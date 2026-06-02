/** Sol-ikon som i appen (SolGameIcon) — varianter efter solType. */
export function SolGameIcon({
  solKind = "normal",
  size = 72,
}: {
  solKind?: "normal" | "pure" | "halfDealer" | "dealer";
  size?: number;
}) {
  const color = "currentColor";
  const disc = size * 0.42;
  const ring = size * 0.08;
  const rayCount =
    solKind === "pure" ? 8 : solKind === "halfDealer" || solKind === "dealer" ? 12 : 6;
  const rayLen = size * (solKind === "normal" ? 0.22 : 0.25);
  const rayW = size * 0.07;
  const cx = size / 2;
  const cy = size / 2;

  const rays = Array.from({ length: rayCount }, (_, i) => {
    const angle = (i * 360) / rayCount;
    return (
      <rect
        key={i}
        x={cx - rayW / 2}
        y={cy - disc / 2 - rayLen}
        width={rayW}
        height={rayLen}
        rx={rayW / 2}
        fill={color}
        transform={`rotate(${angle} ${cx} ${cy})`}
      />
    );
  });

  return (
    <svg
      className="sol-game-icon"
      width={size}
      height={size}
      viewBox={`0 0 ${size} ${size}`}
      aria-hidden="true"
    >
      {rays}
      {solKind === "dealer" ? (
        <circle cx={cx} cy={cy} r={disc / 2} fill={color} />
      ) : solKind === "halfDealer" ? (
        <>
          <circle
            cx={cx}
            cy={cy}
            r={disc / 2}
            fill="none"
            stroke={color}
            strokeWidth={ring}
          />
          <path
            d={`M ${cx} ${cy - disc / 2} A ${disc / 2} ${disc / 2} 0 0 1 ${cx} ${cy + disc / 2} L ${cx} ${cy} Z`}
            fill={color}
          />
        </>
      ) : (
        <circle
          cx={cx}
          cy={cy}
          r={disc / 2}
          fill="none"
          stroke={color}
          strokeWidth={ring}
        />
      )}
    </svg>
  );
}

export function solKindFromLabel(label?: string | null): "normal" | "pure" | "halfDealer" | "dealer" {
  const l = (label ?? "").toLowerCase();
  if (l.includes("ren sol")) return "pure";
  if (l.includes("½") || l.includes("halv bord")) return "halfDealer";
  if (l.includes("bordlægger")) return "dealer";
  return "normal";
}
