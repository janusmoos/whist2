export function HeatmapScoreLegend({ maxAbs }: { maxAbs: number }) {
  const maxLabel = maxAbs >= 10 ? Math.round(maxAbs) : Math.round(maxAbs * 10) / 10;

  return (
    <div className="stats-heatmap-legend" aria-hidden="true">
      <span className="stats-heatmap-legend-label">Tab</span>
      <div className="stats-heatmap-legend-track">
        <div className="stats-heatmap-legend-gradient" />
        <span className="stats-heatmap-legend-zero">0</span>
      </div>
      <span className="stats-heatmap-legend-label">Gevinst</span>
      <span className="stats-heatmap-legend-scale">
        ±{maxLabel} = fuld farve
      </span>
    </div>
  );
}
