import { StatsComingSoon } from "@/components/stats/StatsComingSoon";
import { StatsPageShell } from "@/components/stats/StatsPageShell";

export const metadata = {
  title: "Tendenser — Whistklubben",
};

export default function TendenserPage() {
  return (
    <StatsPageShell
      title="Tendenser"
      lead="Udvikling over tid og seneste perioder."
    >
      <StatsComingSoon />
    </StatsPageShell>
  );
}
