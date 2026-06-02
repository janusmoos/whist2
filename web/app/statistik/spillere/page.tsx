import { StatsComingSoon } from "@/components/stats/StatsComingSoon";
import { StatsPageShell } from "@/components/stats/StatsPageShell";

export const metadata = {
  title: "Spillere — Whistklubben",
};

export default function SpillerePage() {
  return (
    <StatsPageShell
      title="Spillere"
      lead="Profiler, bedste/værste spil og meldinger."
    >
      <StatsComingSoon />
    </StatsPageShell>
  );
}
