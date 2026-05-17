import zipfile, xml.etree.ElementTree as ET, re, json, hashlib, csv
from datetime import datetime, timedelta
from pathlib import Path
from collections import Counter, defaultdict

INPUT = Path('/mnt/data/Whist – resultater – samlet (2024)_AKTIV_forenkling af data.xlsx')
OUTDIR = Path('/mnt/data/whist_import_v2_output')
OUTDIR.mkdir(exist_ok=True)
NS={'a':'http://schemas.openxmlformats.org/spreadsheetml/2006/main','r':'http://schemas.openxmlformats.org/officeDocument/2006/relationships'}
PLAYERS = ['Thomas','Peter','Janus','Christian']
NAME_MAP = {
    'thomas':'Thomas','thomas ':'Thomas','thomas?':'Thomas','thomas.':'Thomas','thomas,':'Thomas','thomas/':'Thomas','thomas /':'Thomas','thomas/ ':'Thomas','thomas ':'Thomas','thomas\xa0':'Thomas','thoms':'Thomas','thoms/janus':'Thomas/Janus','thomas/ janus':'Thomas/Janus','thomas/peter':'Thomas/Peter',
    'peter':'Peter','pete':'Peter','perter':'Peter','peter ':'Peter','peter/':'Peter','peter/christian':'Peter/Christian','peter + christian':'Peter/Christian','peter+christian':'Peter/Christian','peter + christian':'Peter/Christian','peter/christian':'Peter/Christian',
    'janus':'Janus','janus ':'Janus','janjuz':'Janus','janjus':'Janus','janjusz':'Janus','j-naus':'Janus','jnaus':'Janus','janis':'Janus','janjus ':'Janus','janusz':'Janus','janiz':'Janus','jansicz':'Janus',
    'christian':'Christian','christian ':'Christian','chrisitan':'Christian','chistian':'Christian','chrstian':'Christian','chr.':'Christian','ch':'Christian','chr':'Christian','chrisitan ':'Christian','christian /janus':'Christian/Janus','christian/janus':'Christian/Janus',
    'selv makker':'Selvmakker','selvmakker':'Selvmakker','selv-makker':'Selvmakker',
    'ingen':'Ingen','-':'Ingen','—':'Ingen'
}
SKIP_PREFIXES = ('STATISTIK','TEST_STATISTIK','SAMLET','d_')
SKIP_EXACT = {'00_Regnskab_01','Claude Cache','Statistik-spørgsmål','_skabelon','22b_31-09-2023','_26_30-11-2024 (lørdag i Berlin','_27_30-11-2024 (lørdag i Berlin','05_22-09-2017_TOM'}

# Per-sheet corrections discovered in audit v1. None = no direct expectation from 00_Regnskab_01 can be used.
EXPECTED_OVERRIDE = {
    '12_21-02-2020': 35,             # 12a + 12b are on one sheet: 8 + 27
    '19a_13-01-2023_Fredag': None,   # continuation sheet, not represented directly in overview count
    '19b_13-01-2023_Færge mod Tyskla': 8,
    '19c_13-01-2023_Brewdog fredag': None,
}

# For some old sheets the overview contains a count, but rows with score values are genuinely missing.
KNOWN_MISSING_SCORE_ROWS = {'03_25-02-2017', '04_Måske Berlin', '08_3-11-2018'}

def norm_text(x):
    if x is None: return None
    s=str(x).replace('\xa0',' ').strip()
    return s if s else None

def key_text(x):
    s=norm_text(x)
    if not s: return ''
    return re.sub(r'\s+', ' ', s.lower().strip())

def norm_name(x):
    s=norm_text(x)
    if not s: return None
    key=key_text(s)
    return NAME_MAP.get(key, s)

def split_players(x):
    n=norm_name(x)
    if not n: return []
    parts=re.split(r'[/+]', str(n))
    out=[]
    for p in parts:
        pp=norm_name(p)
        if pp in PLAYERS: out.append(pp)
    return out

def is_player(x): return len(split_players(x))==1

def excel_date(v):
    if isinstance(v, (int,float)) and 30000 < v < 60000:
        return (datetime(1899,12,30) + timedelta(days=float(v))).date().isoformat()
    if isinstance(v,str) and re.match(r'\d{1,2}[-/]\d{1,2}[-/]\d{2,4}$', v):
        return v
    return None

def colrow(cell):
    m=re.match(r'([A-Z]+)(\d+)',cell)
    col=0
    for ch in m.group(1): col=col*26+ord(ch)-64
    return int(m.group(2)), col

class Xlsx:
    def __init__(self, path):
        self.z=zipfile.ZipFile(path)
        self.shared=[]
        if 'xl/sharedStrings.xml' in self.z.namelist():
            root=ET.fromstring(self.z.read('xl/sharedStrings.xml'))
            for si in root.findall('a:si',NS):
                self.shared.append(''.join(t.text or '' for t in si.findall('.//a:t',NS)))
        wb=ET.fromstring(self.z.read('xl/workbook.xml'))
        rels=ET.fromstring(self.z.read('xl/_rels/workbook.xml.rels'))
        rid_to_target={rel.attrib['Id']: rel.attrib['Target'] for rel in rels}
        self.sheets=[]
        for s in wb.findall('.//a:sheets/a:sheet',NS):
            rid=s.attrib['{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id']
            target=rid_to_target[rid]
            full='xl/'+target if not target.startswith('/') else target[1:]
            self.sheets.append({'name':s.attrib['name'],'path':full,'sheetId':s.attrib.get('sheetId')})
    def value(self,c):
        t=c.attrib.get('t'); v=c.find('a:v',NS); isel=c.find('a:is',NS)
        if t=='inlineStr' and isel is not None:
            return ''.join(x.text or '' for x in isel.findall('.//a:t',NS))
        if v is None: return None
        txt=v.text
        if txt is None: return None
        if t=='s':
            try: return self.shared[int(txt)]
            except Exception: return txt
        if t=='b': return bool(int(txt))
        try:
            f=float(txt); return int(f) if f.is_integer() else f
        except Exception: return txt
    def matrix(self, path):
        if path not in self.z.namelist() or not path.startswith('xl/worksheets/'):
            return []
        root=ET.fromstring(self.z.read(path))
        data={}; maxr=maxc=0
        for c in root.findall('.//a:sheetData/a:row/a:c',NS):
            r,col=colrow(c.attrib['r']); vv=self.value(c)
            if vv is not None:
                data[(r,col)] = vv; maxr=max(maxr,r); maxc=max(maxc,col)
        return [[data.get((r,c)) for c in range(1,maxc+1)] for r in range(1,maxr+1)]

def should_import(name):
    if name in SKIP_EXACT: return False
    if any(name.startswith(p) for p in SKIP_PREFIXES): return False
    return bool(re.match(r'^\d{2}|^\d{1,2}[a-z]_', name))

def find_header(mat):
    for i,row in enumerate(mat):
        normalized=[norm_name(c) for c in row]
        lows=[key_text(c) for c in row]
        has_game_col = any(x in lows for x in ('spil','#','fortløbende')) or (len(row)>0 and row[0] is None)
        if has_game_col and sum(1 for p in PLAYERS if p in normalized)>=3:
            return i
    return None

def player_blocks(header):
    names=[norm_name(c) for c in header]
    blocks=[]
    for start in range(len(names)-3):
        seq=names[start:start+4]
        if all(x in PLAYERS for x in seq) and len(set(seq))==4:
            blocks.append({'start':start,'players':seq})
    return blocks

def is_num(x): return isinstance(x,(int,float)) and not isinstance(x,bool)

def get_col(header, *labels):
    lows=[key_text(c) for c in header]
    for label in labels:
        lab=label.lower()
        for idx,v in enumerate(lows):
            if v==lab: return idx
    return None

def get_cols(header, *labels):
    lows=[key_text(c) for c in header]
    return [idx for idx,v in enumerate(lows) if v in [l.lower() for l in labels]]

def game_type_category(raw):
    s=key_text(raw)
    if not s: return None
    if 'bordlægger' in s: return 'bordlægger'
    if 'storslem' in s: return 'storslem'
    if 'ren' in s and 'sol' in s: return 'ren sol'
    if 'sol' in s: return 'sol'
    if 'sans' in s or 'sang' in s: return 'sans/sang'
    if 'halve' in s: return 'halve'
    if 'vip' in s: return 'vip'
    if 'gode' in s: return 'gode'
    if 'alm' in s or 'almindelige' in s: return 'alm'
    return None

def bid_tricks(raw):
    if raw is None: return None
    m=re.search(r'\b(7|8|9|10|11|12|13)\b', str(raw))
    return int(m.group(1)) if m else None

def infer_columns(header, mat, header_i):
    # Returns semantic metadata columns. Uses actual values, not only header names.
    melding_col=get_col(header,'melding')
    winning_col=get_col(header,'vindende melding')
    hvem_col=get_col(header,'hvem')
    dealer_col=get_col(header,'giver')
    partner_col=get_col(header,'makker')

    if hvem_col is not None:
        return {'game_type_col': melding_col, 'bidder_col': hvem_col, 'winner_col': hvem_col, 'dealer_col': dealer_col, 'partner_col': partner_col}

    candidates=[c for c in [melding_col, winning_col] if c is not None]
    if not candidates:
        return {'game_type_col': None, 'bidder_col': None, 'winner_col': None, 'dealer_col': dealer_col, 'partner_col': partner_col}

    score={}
    for c in candidates:
        player_count=0; type_count=0; nonempty=0
        for row in mat[header_i+1:header_i+45]:
            if c >= len(row): continue
            v=row[c]
            if norm_text(v) is None: continue
            nonempty += 1
            if is_player(v): player_count += 1
            if game_type_category(v) or bid_tricks(v): type_count += 1
        score[c]=(player_count,type_count,nonempty)
    # choose game type as most type-looking. choose winner/bidder as most player-looking.
    game_type_col=max(candidates, key=lambda c:(score[c][1], -score[c][0], score[c][2])) if candidates else None
    bidder_col=max(candidates, key=lambda c:(score[c][0], -score[c][1], score[c][2])) if candidates else None
    if score.get(bidder_col,(0,0,0))[0] == 0:
        bidder_col = None
    return {'game_type_col': game_type_col, 'bidder_col': bidder_col, 'winner_col': bidder_col, 'dealer_col': dealer_col, 'partner_col': partner_col}

def choose_score_blocks(blocks, mat, header_i):
    # last block with numeric rows is usually explicit per-game deltas. first block is cumulative.
    scored=[]
    for bi,b in enumerate(blocks):
        rows_numeric=rows_sum_zero=0
        for row in mat[header_i+1:]:
            vals=[row[c] if c < len(row) else None for c in range(b['start'], b['start']+4)]
            if all(is_num(v) for v in vals):
                rows_numeric += 1
                if sum(vals)==0: rows_sum_zero += 1
        scored.append((rows_numeric, rows_sum_zero, bi, b))
    scored.sort(key=lambda x:(x[0], x[1], x[2]), reverse=True)
    delta=scored[0][3]
    cumulative=blocks[0]
    return cumulative, delta, scored[0]

def parse_regnskab(mat):
    meta={}
    for row in mat[2:35]:
        if not row or row[0] is None: continue
        no=str(row[0])
        date=excel_date(row[2] if len(row)>2 else None)
        expected=row[8] if len(row)>8 and isinstance(row[8],(int,float)) else None
        location=row[11] if len(row)>11 else None
        meta[no]={'date':date,'location':norm_text(location),'expectedGameCount':int(expected) if expected is not None else None,
                  'overviewScores': {'Thomas':row[3] if len(row)>3 else None,'Peter':row[4] if len(row)>4 else None,'Janus':row[5] if len(row)>5 else None,'Christian':row[6] if len(row)>6 else None}}
    return meta

def sheet_session_number(name, mat):
    # keep 19a/19b/19c distinct even though top row says 19
    m=re.match(r'^(\d+[a-z]?)_', name)
    if m and re.search(r'[a-z]', m.group(1)): return m.group(1)
    if mat and mat[0] and mat[0][0] is not None: return str(mat[0][0])
    return m.group(1) if m else re.sub('[^0-9A-Za-z]+','-',name).strip('-')

def game_rows(mat, header_i, header, cumulative_block, delta_block):
    spil_col=get_col(header,'spil','#','fortløbende')
    if spil_col is None: spil_col = 0
    seen_summary=False
    prev_cum=None
    for r_index,row0 in enumerate(mat[header_i+1:], start=header_i+2):
        row=row0+[None]*max(0, len(header)-len(row0))
        # stop after clear summary section like I ALT
        if any(isinstance(x,str) and key_text(x) in ('i alt','ialt','total','sum') for x in row[:3]):
            seen_summary=True
            continue
        if seen_summary: continue
        if spil_col>=len(row): continue
        marker=row[spil_col]
        if marker is None: continue
        if not (is_num(marker) or re.match(r'^\d+', str(marker).strip())): continue
        cum_vals=[row[c] if c < len(row) else None for c in range(cumulative_block['start'], cumulative_block['start']+4)]
        delta_vals=[row[c] if c < len(row) else None for c in range(delta_block['start'], delta_block['start']+4)] if delta_block else []
        has_delta = bool(delta_block) and all(is_num(v) for v in delta_vals)
        has_cum = all(is_num(v) for v in cum_vals)
        if not has_delta and not has_cum:
            yield {'row':r_index,'marker':marker,'kind':'missing_scores','scores':None,'players':cumulative_block['players'],'rawRow':row}
            continue
        if delta_block and delta_block['start'] != cumulative_block['start'] and has_delta:
            scores=delta_vals; players=delta_block['players']; source='delta_columns'
        elif has_cum and prev_cum is not None:
            scores=[cum_vals[i]-prev_cum[i] for i in range(4)]; players=cumulative_block['players']; source='derived_from_cumulative'
        elif has_cum:
            scores=cum_vals; players=cumulative_block['players']; source='cumulative_first_row_as_delta'
        else:
            scores=delta_vals; players=delta_block['players']; source='delta_columns'
        if has_cum: prev_cum=cum_vals
        yield {'row':r_index,'marker':marker,'kind':'game','scores':scores,'players':players,'scoreSource':source,'rawRow':row}

def parse_sheet(sheet, mat, regnskab_meta):
    name=sheet['name']; header_i=find_header(mat); 
    if header_i is None:
        return None, [], [], [{'sheet':name,'row':None,'severity':'error','issue':'no_header_found','rawValue':None}]
    header=mat[header_i]
    blocks=player_blocks(header)
    if not blocks:
        return None, [], [], [{'sheet':name,'row':header_i+1,'severity':'error','issue':'no_player_block_found','rawValue':header}]
    cumulative_block, delta_block, score_stats = choose_score_blocks(blocks, mat, header_i)
    cols=infer_columns(header, mat, header_i)
    raw_session_number=sheet_session_number(name, mat)
    # Metadata lookup: 19a/19b/19c fall back to 19, otherwise exact.
    meta = regnskab_meta.get(raw_session_number) or regnskab_meta.get(re.match(r'\d+', raw_session_number).group(0) if re.match(r'\d+', raw_session_number) else raw_session_number)
    raw_date = mat[0][1] if mat and len(mat[0])>1 else None
    raw_location = next((c for c in (mat[0][2:6] if mat else []) if isinstance(c,str) and c.strip()), None)
    date = meta.get('date') if meta else excel_date(raw_date)
    location = meta.get('location') if meta else raw_location
    expected = EXPECTED_OVERRIDE.get(name, meta.get('expectedGameCount') if meta else None)
    session_number=raw_session_number
    session_id = f"session_{session_number}_{date or re.sub('[^0-9A-Za-z]+','-',name).strip('-')}"
    games=[]; results=[]; issues=[]; imported=0; missing_score_rows=0
    for gr in game_rows(mat, header_i, header, cumulative_block, delta_block):
        if gr['kind']=='missing_scores':
            missing_score_rows += 1
            issues.append({'sheet':name,'row':gr['row'],'severity':'warning','issue':'game_marker_without_scores','rawValue':gr['marker']})
            continue
        row=gr['rawRow']; imported+=1
        game_id=f"{session_id}_game_{imported:03d}"
        game_type_raw = row[cols['game_type_col']] if cols['game_type_col'] is not None and cols['game_type_col'] < len(row) else None
        bidder_raw = row[cols['bidder_col']] if cols['bidder_col'] is not None and cols['bidder_col'] < len(row) else None
        dealer_raw = row[cols['dealer_col']] if cols['dealer_col'] is not None and cols['dealer_col'] < len(row) else None
        partner_raw = row[cols['partner_col']] if cols['partner_col'] is not None and cols['partner_col'] < len(row) else None
        bidder=norm_name(bidder_raw); dealer=norm_name(dealer_raw); partner=norm_name(partner_raw); bidder_ids=split_players(bidder_raw)
        scores=gr['scores']; ssum=sum(scores)
        qflags=[]
        if not norm_text(game_type_raw): qflags.append('missing_game_type')
        if not bidder_ids: qflags.append('missing_bidder_or_winner')
        if not (dealer in PLAYERS): qflags.append('missing_dealer')
        # partner can be missing for solspil, so don't flag if game type is sol/ren sol
        cat=game_type_category(game_type_raw)
        if partner is None and cat not in ('sol','ren sol','bordlægger'):
            qflags.append('missing_partner')
        if ssum != 0:
            qflags.append('score_sum_not_zero')
            issues.append({'sheet':name,'row':gr['row'],'severity':'warning','issue':'score_sum_not_zero','rawValue':ssum})
        for field, raw, nval in [('bidder',bidder_raw,bidder),('dealer',dealer_raw,dealer),('partner',partner_raw,partner)]:
            if raw is not None and nval not in PLAYERS and nval not in ('Selvmakker','Ingen') and not split_players(raw):
                # Avoid reporting actual game types as player names; only flag if semantic column really should be a name.
                issues.append({'sheet':name,'row':gr['row'],'severity':'warning','issue':f'unknown_{field}_name','rawValue':str(raw)})
        games.append({
            'id':game_id,'sessionId':session_id,'sessionNumber':session_number,
            'gameNumberInSession':imported,'sourceGameMarker':gr['marker'],
            'gameTypeRaw':norm_text(game_type_raw),'gameTypeNormalized':cat,'bidTricks':bid_tricks(game_type_raw),
            'bidderId':bidder_ids[0] if len(bidder_ids)==1 else None,'bidderIds':bidder_ids,'winnerId':bidder_ids[0] if len(bidder_ids)==1 else None,'winnerIds':bidder_ids,
            'partnerId':partner if partner in PLAYERS else ('Selvmakker' if partner=='Selvmakker' else None),
            'dealerId':dealer if dealer in PLAYERS else None,
            'checksum':ssum,'scoreSource':gr['scoreSource'],
            'sourceSheetName':name,'sourceRow':gr['row'],'qualityFlags':qflags,
        })
        for player, score in zip(gr['players'], scores):
            results.append({'id':f'{game_id}_{player}','gameId':game_id,'playerId':player,'score':int(score),'sourceSheetName':name,'sourceRow':gr['row']})
    status='ok'
    if expected is not None and imported != expected: status='warning'
    if not games: status='error'
    if name in KNOWN_MISSING_SCORE_ROWS and expected and imported < expected:
        # explicitly mark as known data absence rather than parser failure
        status='warning_missing_source_rows'
    session={
        'id':session_id,'sessionNumber':session_number,'date':date,'location':location,
        'sourceSheetName':name,'expectedGameCount':expected,'importedGameCount':imported,
        'missingScoreRows':missing_score_rows,'qualityStatus':status,
        'cumulativeBlockStartColumn':cumulative_block['start']+1,
        'deltaBlockStartColumn':delta_block['start']+1 if delta_block else None,
        'preferredScoreBlockNumericRows':score_stats[0],
        'headerRow':header_i+1,
        'columnMapping': cols
    }
    if expected is not None and imported != expected:
        issues.append({'sheet':name,'row':None,'severity':'warning','issue':'expected_vs_imported_count_mismatch','rawValue':{'expected':expected,'imported':imported}})
    return session, games, results, issues

def write_csv(path, rows, fieldnames):
    with open(path,'w',newline='',encoding='utf-8') as f:
        w=csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
        w.writeheader(); w.writerows(rows)

def main():
    book=Xlsx(INPUT)
    matrices={s['name']:book.matrix(s['path']) for s in book.sheets if s['path'].startswith('xl/worksheets/')}
    regnskab=parse_regnskab(matrices.get('00_Regnskab_01',[]))
    sessions=[]; games=[]; results=[]; issues=[]; sheet_inventory=[]
    for s in book.sheets:
        name=s['name']; import_flag=should_import(name)
        sheet_inventory.append({'sheetName':name,'path':s['path'],'importCandidate':import_flag})
        if not import_flag: continue
        session, gs, rs, iss = parse_sheet(s, matrices.get(name,[]), regnskab)
        if session: sessions.append(session)
        games.extend(gs); results.extend(rs); issues.extend(iss)
    player_totals={p:0 for p in PLAYERS}
    for r in results: player_totals[r['playerId']]+=r['score']
    field_counts={
        'gameType': sum(1 for g in games if g.get('gameTypeRaw')),
        'dealer': sum(1 for g in games if g.get('dealerId')),
        'bidder_or_winner': sum(1 for g in games if g.get('bidderId') or g.get('winnerId')),
        'partner': sum(1 for g in games if g.get('partnerId')),
        'score_sum_zero': sum(1 for g in games if g.get('checksum')==0),
    }
    issue_counts=dict(Counter(i['issue'] for i in issues))
    audit={'sourceFile':INPUT.name,'generatedAt':datetime.now().isoformat(timespec='seconds'),
           'workbookHashSha256':hashlib.sha256(INPUT.read_bytes()).hexdigest(),
           'sheetInventory':sheet_inventory,
           'summary':{'version':'v2','sheetCount':len(book.sheets),'importedSessions':len(sessions),'importedGames':len(games),'playerResultRows':len(results),'playerTotals':player_totals,'fieldCounts':field_counts,'issueCount':len(issues),'issueCounts':issue_counts},
           'sessions':sessions,'issues':issues[:20000]}
    historical={'version':'whist_historical_data_v2','generatedAt':audit['generatedAt'],'players':[{'id':p,'name':p,'displayOrder':i+1,'isActive':True} for i,p in enumerate(PLAYERS)],'sessions':sessions,'games':games,'playerResults':results,'auditSummary':audit['summary']}
    for fn,obj in {'sessions.json':sessions,'games.json':games,'player_results.json':results,'import_audit.json':audit,'whist_historical_data_v2.json':historical}.items():
        (OUTDIR/fn).write_text(json.dumps(obj, ensure_ascii=False, indent=2), encoding='utf-8')
    # CSV summaries
    write_csv(OUTDIR/'session_validation_v2.csv', sessions, ['sessionNumber','sourceSheetName','date','location','expectedGameCount','importedGameCount','missingScoreRows','qualityStatus','headerRow','cumulativeBlockStartColumn','deltaBlockStartColumn'])
    write_csv(OUTDIR/'issue_summary_v2.csv', [{'issue':k,'count':v} for k,v in sorted(issue_counts.items(), key=lambda x:-x[1])], ['issue','count'])
    ex=[]
    for it in issues:
        ex.append({'sheet':it.get('sheet'),'row':it.get('row'),'severity':it.get('severity'),'issue':it.get('issue'),'rawValue':str(it.get('rawValue'))})
    write_csv(OUTDIR/'issues_v2.csv', ex, ['sheet','row','severity','issue','rawValue'])
    # Markdown report
    lines=[]
    lines.append('# Whist import v2 — audit og app-klart datasæt\n\n')
    lines.append(f"Genereret: {audit['generatedAt']}\n\n")
    lines.append('## Kort status\n\n')
    lines.append('| Måling | Antal |\n|---|---:|\n')
    for label,key in [('Sessions', 'importedSessions'),('Spil','importedGames'),('PlayerResult-rækker','playerResultRows'),('Issues','issueCount')]:
        lines.append(f"| {label} | {audit['summary'][key]} |\n")
    lines.append('\n## Felt-dækning\n\n| Felt | Spil med felt | Ud af alle spil |\n|---|---:|---:|\n')
    total=len(games)
    labels={'gameType':'Spiltype','dealer':'Giver/dealer','bidder_or_winner':'Melder/vinder','partner':'Makker','score_sum_zero':'Score-sum = 0'}
    for k,v in field_counts.items(): lines.append(f"| {labels[k]} | {v} | {total} |\n")
    lines.append('\n## Issues efter v2\n\n| Issue | Antal |\n|---|---:|\n')
    for k,v in sorted(issue_counts.items(), key=lambda x:-x[1]): lines.append(f"| `{k}` | {v} |\n")
    lines.append('\n## Sessions\n\n| Session | Ark | Forventet | Importeret | Manglende score-rækker | Status |\n|---|---|---:|---:|---:|---|\n')
    for s in sessions:
        lines.append(f"| {s['sessionNumber']} | `{s['sourceSheetName']}` | {'' if s.get('expectedGameCount') is None else s.get('expectedGameCount')} | {s['importedGameCount']} | {s.get('missingScoreRows',0)} | {s['qualityStatus']} |\n")
    lines.append('\n## Hvad er forbedret fra v1\n\n')
    lines.append('- `Melding` og `Vindende melding` bliver nu vurderet ud fra kolonneindhold, ikke kun headernavn. Det reducerer fejlagtige `unknown_bidder_name` markant.\n')
    lines.append('- `Makker` importeres nu, hvor kolonnen findes.\n')
    lines.append('- Ark med delspil/fortsættelser håndteres bedre, især `12_21-02-2020` og Berlin 2023-arkene.\n')
    lines.append('- Rækker efter tydelige summeringer som `I ALT` ignoreres, så duplikatrækker ikke importeres som spil.\n')
    lines.append('- Der eksporteres nu ét samlet app-klart JSON-datasæt: `whist_historical_data_v2.json`.\n')
    lines.append('\n## Anbefalet næste skridt\n\n')
    lines.append('Brug v2-outputtet som grundlag for første Swift/Codable- og CoreData-model. De resterende issues bør behandles som datakvalitet, ikke som blocker for de første pointbaserede statistikker.\n')
    (OUTDIR/'IMPORT_V2_REPORT.md').write_text(''.join(lines), encoding='utf-8')
    print(json.dumps(audit['summary'], ensure_ascii=False, indent=2))
    print(OUTDIR)

if __name__=='__main__': main()
