"use client";

import { StatsPageShell } from "@/components/stats/StatsPageShell";
import { useClubStats } from "@/hooks/useClubStats";

export function DataQualityStatsView() {
  const { model, error, loading } = useClubStats();

  return (
    <StatsPageShell
      title="Datagrundlag"
      lead="Importkvalitet, feltdækning og kendte afvigelser i historikken."
    >
      {error ? (
        <div className="banner" role="alert">
          Kan ikke hente data — {error}
        </div>
      ) : null}
      {loading && !model ? <p className="stats-loading">Indlæser…</p> : null}
      {model ? (
        <div className="stats-quality">
          <dl className="stats-quality-metrics">
            <div>
              <dt>Dataversion</dt>
              <dd>{model.dataQuality.dataVersion}</dd>
            </div>
            <div>
              <dt>Genereret</dt>
              <dd>{new Date(model.dataQuality.generatedAt).toLocaleString("da-DK")}</dd>
            </div>
            <div>
              <dt>Spilledage</dt>
              <dd>{model.dataQuality.sessionCount}</dd>
            </div>
            <div>
              <dt>Spil</dt>
              <dd>{model.dataQuality.gameCount}</dd>
            </div>
            <div>
              <dt>Resultatrækker</dt>
              <dd>{model.dataQuality.playerResultCount}</dd>
            </div>
            <div>
              <dt>Nul-sum spil</dt>
              <dd>{model.dataQuality.zeroSumGameCount}</dd>
            </div>
            <div>
              <dt>Spil med kvalitets-flag</dt>
              <dd>{model.dataQuality.gamesWithQualityFlags}</dd>
            </div>
          </dl>

          <section>
            <h3 className="stats-section-title">Hyppigste kvalitets-flag</h3>
            {model.dataQuality.topQualityFlags.length === 0 ? (
              <p className="stats-empty">Ingen kvalitets-flag registreret.</p>
            ) : (
              <ul className="stats-flag-list">
                {model.dataQuality.topQualityFlags.map((row) => (
                  <li key={row.flag}>
                    <code>{row.flag}</code>
                    <span>{row.count} spil</span>
                  </li>
                ))}
              </ul>
            )}
          </section>

          <p className="stats-quality-note">
            Første web-version bruger primært pointdata fra import v3. Finere felter
            (melder, makker, spiltype) udfyldes løbende — som i appen.
          </p>
        </div>
      ) : null}
    </StatsPageShell>
  );
}
