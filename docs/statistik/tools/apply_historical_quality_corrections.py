import json
from collections import Counter
from datetime import datetime
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
JSON_PATH = ROOT / "Whist20/Resources/HistoricalData/whist_historical_data_v2.json"
REPORT_PATH = ROOT / "docs/statistik/historical_quality_corrections.md"
PLAYERS = ["Thomas", "Peter", "Janus", "Christian"]


CORRECTIONS = {
    ("2", 13): {
        "player": "Janus",
        "before": -104,
        "after": -4,
        "reason": "Regnearksnoten siger: Her ryger jeg 100 kroner for langt ned.",
    },
    ("2", 14): {
        "player": "Christian",
        "before": -20,
        "after": 20,
        "reason": "Regnearksnoten siger: Hvem vinder 20 i stedet for at miste dem? Tror det er Christian...",
    },
}


def score_text(scores):
    return ", ".join(f"{player} {scores[player]:+d}" for player in PLAYERS)


def remove_flag(flags, flag):
    return [item for item in flags if item != flag]


def recompute_audit_summary(data):
    games = data["games"]
    results = data["playerResults"]
    player_totals = {player: 0 for player in PLAYERS}
    for result in results:
        if result["playerId"] in player_totals:
            player_totals[result["playerId"]] += result["score"]

    results_by_game = {}
    for result in results:
        results_by_game.setdefault(result["gameId"], []).append(result["score"])

    issue_counts = Counter()
    for game in games:
        for flag in game.get("qualityFlags", []):
            if flag in (
                "score_sum_not_zero",
                "source_explicit_score_sum_not_zero",
                "corrected_from_source_note",
            ):
                issue_counts[flag] += 1

    old_issue_counts = data.get("auditSummary", {}).get("issueCounts", {})
    for preserved in ("game_marker_without_scores", "expected_vs_imported_count_mismatch"):
        if preserved in old_issue_counts:
            issue_counts[preserved] = old_issue_counts[preserved]
    issue_counts["game_marker_without_scores"] = issue_counts.get("game_marker_without_scores", 13)
    issue_counts["expected_vs_imported_count_mismatch"] = issue_counts.get("expected_vs_imported_count_mismatch", 3)

    field_counts = {
        "gameType": sum(1 for game in games if game.get("gameTypeRaw")),
        "dealer": sum(1 for game in games if game.get("dealerId")),
        "bidder_or_winner": sum(1 for game in games if game.get("bidderId") or game.get("winnerId")),
        "partner": sum(1 for game in games if game.get("partnerId")),
        "score_sum_zero": sum(1 for game in games if sum(results_by_game.get(game["id"], [])) == 0),
    }

    audit = data["auditSummary"]
    audit["playerTotals"] = player_totals
    audit["fieldCounts"] = field_counts
    audit["issueCounts"] = dict(sorted(issue_counts.items()))
    audit["issueCount"] = sum(issue_counts.values())


def main():
    data = json.loads(JSON_PATH.read_text(encoding="utf-8"))
    games_by_key = {
        (game["sessionNumber"], game["gameNumberInSession"]): game
        for game in data["games"]
    }
    results_by_game = {}
    for result in data["playerResults"]:
        results_by_game.setdefault(result["gameId"], {})[result["playerId"]] = result

    applied = []
    for key, correction in CORRECTIONS.items():
        game = games_by_key[key]
        game_results = results_by_game[game["id"]]
        current_scores = {player: game_results[player]["score"] for player in PLAYERS}

        player = correction["player"]
        if current_scores[player] == correction["after"]:
            corrected_scores = current_scores
        elif current_scores[player] == correction["before"]:
            game_results[player]["score"] = correction["after"]
            corrected_scores = {player: game_results[player]["score"] for player in PLAYERS}
        else:
            raise ValueError(
                f"Unexpected score for session {key[0]} game {key[1]} {player}: "
                f"{current_scores[player]} != {correction['before']}"
            )

        game["checksum"] = sum(corrected_scores.values())
        game["scoreSource"] = "corrected_from_source_note"
        game["qualityFlags"] = remove_flag(game["qualityFlags"], "score_sum_not_zero")
        if "corrected_from_source_note" not in game["qualityFlags"]:
            game["qualityFlags"].append("corrected_from_source_note")

        applied.append((game, current_scores, corrected_scores, correction))

    data["generatedAt"] = datetime.now().isoformat(timespec="seconds")
    data["version"] = "whist_historical_data_v2_corrected"
    recompute_audit_summary(data)

    JSON_PATH.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    lines = [
        "# Historiske datakvalitetsrettelser\n",
        "\n",
        f"Genereret: {data['generatedAt']}\n",
        "\n",
        "## Automatiske rettelser\n",
        "\n",
        "Kun spil med en konkret regnearksnote og en entydig nulsum-korrektion er rettet. "
        "Øvrige ubalancer bevares som datakvalitetsadvarsler i appen.\n",
        "\n",
        "| Spilledag | Spil | Spiller | Før | Efter | Resultat efter rettelse | Kilde-note |\n",
        "|---:|---:|---|---:|---:|---|---|\n",
    ]

    for game, before, after, correction in applied:
        lines.append(
            f"| {game['sessionNumber']} | {game['gameNumberInSession']} | {correction['player']} | "
            f"{correction['before']:+d} | {correction['after']:+d} | {score_text(after)} | "
            f"{correction['reason']} |\n"
        )

    lines.extend([
        "\n",
        "## Bevidst ikke rettet automatisk\n",
        "\n",
        "- Spilledag 1, 3 og 4 har historiske ubalancer uden nok metadata til at afgøre, hvilken spiller der skal justeres.\n",
        "- Spilledag 25, spil 3-7 summerer til nul, men resultatet matcher ikke almindelig makkerlogik. Her kan fejlen ligge i resultat, makker, melder/vinder eller spiltype.\n",
        "- Spilledag 26, spil 24 har en eksplicit scoreblok, der selv summerer forkert. Den kræver manuel kildeafklaring.\n",
    ])

    REPORT_PATH.write_text("".join(lines), encoding="utf-8")
    print(f"Applied {len(applied)} historical quality corrections.")


if __name__ == "__main__":
    main()
