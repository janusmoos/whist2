"use client";

import { GameTypeCell } from "@/components/stats/GameTypeCell";
import { ChartReveal, chartStagger } from "@/components/stats/charts/ChartReveal";
import { HeatmapDataCell } from "@/components/stats/charts/HeatmapDataCell";
import { HeatmapScoreLegend } from "@/components/stats/charts/HeatmapScoreLegend";
import {
  findHeatmapCell,
  type PlayerBidTrickHeatmapData,
  type PlayerSolHeatmapData,
} from "@/lib/stats/playerGameTypeStats";

export function PlayerBidTrickHeatmap({
  data,
  title = "Gennemsnit pr. spiltype og meldte stik",
}: {
  data: PlayerBidTrickHeatmapData;
  title?: string;
}) {
  let stagger = 0;

  return (
    <ChartReveal className="stats-player-bid-heatmap">
      {title ? <h4 className="stats-chart-subtitle">{title}</h4> : null}

      <div className="stats-player-bid-heatmap-scroll">
        <table className="stats-player-bid-heatmap-table" role="grid">
          <thead>
            <tr>
              <th scope="col" className="stats-player-bid-heatmap-corner">
                Spiltype
              </th>
              {data.columns.map((bid) => (
                <th key={bid} scope="col" className="stats-player-bid-heatmap-col-head">
                  {bid}
                </th>
              ))}
            </tr>
            <tr className="stats-player-bid-heatmap-subhead">
              <td colSpan={data.columns.length + 1}>Meldte stik →</td>
            </tr>
          </thead>
          <tbody>
            {data.rows.map((row) => (
              <tr key={row.gameType}>
                <th scope="row" className="stats-player-bid-heatmap-row-head">
                  <GameTypeCell label={row.gameType} iconKind={row.iconKind} showLabel />
                </th>
                {data.columns.map((bid) => {
                  const cell = findHeatmapCell(data.cells, row.gameType, bid);
                  const idx = stagger++;
                  return (
                    <HeatmapDataCell
                      key={bid}
                      cell={cell}
                      maxAbs={data.maxAbs}
                      empty={!cell}
                      stagger={idx}
                    />
                  );
                })}
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <HeatmapScoreLegend maxAbs={data.maxAbs} />
    </ChartReveal>
  );
}

export function PlayerSolHeatmap({
  data,
  title = "Gennemsnit i solspil",
}: {
  data: PlayerSolHeatmapData;
  title?: string;
}) {
  return (
    <ChartReveal className="stats-player-sol-heatmap">
      {title ? <h4 className="stats-chart-subtitle">{title}</h4> : null}

      <div className="stats-player-bid-heatmap-scroll">
        <table className="stats-player-bid-heatmap-table stats-player-sol-heatmap-table" role="grid">
          <thead>
            <tr>
              <th scope="col" className="stats-player-bid-heatmap-corner">
                Spiltype
              </th>
              <th scope="col" className="stats-player-bid-heatmap-col-head">
                Snit
              </th>
            </tr>
          </thead>
          <tbody>
            {data.cells.map((cell, i) => (
              <tr key={cell.gameType} style={chartStagger(i)}>
                <th scope="row" className="stats-player-bid-heatmap-row-head">
                  <GameTypeCell label={cell.gameType} iconKind={cell.iconKind} showLabel />
                </th>
                <HeatmapDataCell cell={cell} maxAbs={data.maxAbs} stagger={i} />
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <HeatmapScoreLegend maxAbs={data.maxAbs} />
    </ChartReveal>
  );
}
