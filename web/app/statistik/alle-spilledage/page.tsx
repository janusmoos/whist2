import { StatsComingSoon } from "@/components/stats/StatsComingSoon";
import { StatsPageShell } from "@/components/stats/StatsPageShell";

export const metadata = {
  title: "Alle spilledage — Whistklubben",
};

export default function AlleSpilledagePage() {
  return (
    <StatsPageShell
      title="Alle spilledage"
      lead="Dato, sted, resultater og spil-detaljer for hele klubbens historik."
    >
      <StatsComingSoon />
    </StatsPageShell>
  );
}
