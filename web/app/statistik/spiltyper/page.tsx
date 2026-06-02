import { StatsComingSoon } from "@/components/stats/StatsComingSoon";
import { StatsPageShell } from "@/components/stats/StatsPageShell";

export const metadata = {
  title: "Spiltyper — Whistklubben",
};

export default function SpiltyperPage() {
  return (
    <StatsPageShell
      title="Spiltyper"
      lead="Succes pr. type med tydelig sample size."
    >
      <StatsComingSoon />
    </StatsPageShell>
  );
}
