/** Ingen trumf — som NoTrumpIcon (SF Symbol xmark.circle) i appen. */
export function NoTrumpIcon({ size = 72 }: { size?: number }) {
  return (
    <svg
      className="no-trump-icon"
      width={size}
      height={size}
      viewBox="0 0 72 72"
      aria-label="Ingen trumf"
      role="img"
    >
      <circle
        cx="36"
        cy="36"
        r="30"
        fill="none"
        stroke="currentColor"
        strokeWidth="5"
      />
      <path
        d="M22 22 L50 50 M50 22 L22 50"
        stroke="currentColor"
        strokeWidth="5"
        strokeLinecap="round"
      />
    </svg>
  );
}
