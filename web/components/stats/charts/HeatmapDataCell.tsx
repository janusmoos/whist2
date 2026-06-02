"use client";

import { useCallback, useEffect, useRef, useState, type CSSProperties } from "react";
import { createPortal } from "react-dom";
import { GameTypeCell } from "@/components/stats/GameTypeCell";
import { formatAverage, scoreClass } from "@/lib/stats/format";
import { heatmapCellBackground } from "@/lib/stats/heatmapColors";
import type { PlayerHeatmapCellData } from "@/lib/stats/playerGameTypeStats";

type TooltipState = {
  x: number;
  y: number;
  cell: PlayerHeatmapCellData;
};

function HeatmapTooltipContent({ cell }: { cell: PlayerHeatmapCellData }) {
  return (
    <div className="stats-heatmap-popup-inner">
      <GameTypeCell label={cell.gameType} iconKind={cell.iconKind} showLabel />
      {cell.bidTricks != null ? (
        <span className="stats-heatmap-cell-popup-meta">{cell.bidTricks} meldte stik</span>
      ) : null}
      <span className={`stats-heatmap-cell-popup-score${scoreClass(cell.averageScore)}`}>
        Snit {formatAverage(cell.averageScore)}
      </span>
      <span className="stats-heatmap-cell-popup-meta">{cell.games} spil</span>
    </div>
  );
}

export function HeatmapDataCell({
  cell,
  maxAbs,
  stagger,
  empty = false,
}: {
  cell?: PlayerHeatmapCellData;
  maxAbs: number;
  stagger?: number;
  empty?: boolean;
}) {
  const ref = useRef<HTMLTableCellElement>(null);
  const [tooltip, setTooltip] = useState<TooltipState | null>(null);

  const showTooltip = useCallback(() => {
    if (!cell || !ref.current) return;
    const rect = ref.current.getBoundingClientRect();
    setTooltip({
      x: rect.left + rect.width / 2,
      y: rect.top,
      cell,
    });
  }, [cell]);

  const hideTooltip = useCallback(() => setTooltip(null), []);

  useEffect(() => {
    if (!tooltip) return;
    const dismiss = () => hideTooltip();
    window.addEventListener("scroll", dismiss, true);
    window.addEventListener("resize", dismiss);
    return () => {
      window.removeEventListener("scroll", dismiss, true);
      window.removeEventListener("resize", dismiss);
    };
  }, [tooltip, hideTooltip]);

  if (empty || !cell) {
    return (
      <td
        className="stats-player-bid-heatmap-cell stats-player-bid-heatmap-cell--empty"
        style={stagger != null ? ({ "--stagger": stagger } as CSSProperties) : undefined}
        aria-hidden="true"
      />
    );
  }

  const label = `${cell.gameType}${cell.bidTricks != null ? `, ${cell.bidTricks} stik` : ""}: snit ${formatAverage(cell.averageScore)} (${cell.games} spil)`;

  return (
    <>
      <td
        ref={ref}
        className="stats-player-bid-heatmap-cell stats-player-bid-heatmap-cell--filled"
        style={{
          background: heatmapCellBackground(cell.averageScore, maxAbs),
          ...(stagger != null ? { "--stagger": stagger } : {}),
        }}
        tabIndex={0}
        role="gridcell"
        aria-label={label}
        onMouseEnter={showTooltip}
        onMouseLeave={hideTooltip}
        onFocus={showTooltip}
        onBlur={hideTooltip}
      />
      {tooltip
        ? createPortal(
            <div
              className="stats-heatmap-popup-fixed"
              style={{
                left: tooltip.x,
                top: tooltip.y,
              }}
              role="tooltip"
            >
              <HeatmapTooltipContent cell={tooltip.cell} />
            </div>,
            document.body
          )
        : null}
    </>
  );
}
