export function scoreLabel(n: number): string {
  return n > 0 ? `+${n}` : String(n);
}

export function scoreClass(n: number): string {
  if (n > 0) return " score--pos";
  if (n < 0) return " score--neg";
  return " score--zero";
}

export function formatAverage(n: number): string {
  const rounded = Math.round(n * 10) / 10;
  const formatted = Math.abs(rounded).toLocaleString("da-DK", {
    minimumFractionDigits: 1,
    maximumFractionDigits: 1,
  });
  if (rounded > 0) return `+${formatted}`;
  if (rounded < 0) return `-${formatted}`;
  return formatted;
}

export function averageScoreClass(n: number): string {
  return scoreClass(Math.round(n * 10) / 10);
}
