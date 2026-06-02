import { StatsComingSoon } from "@/components/stats/StatsComingSoon";
import { StatsPageShell } from "@/components/stats/StatsPageShell";

export const metadata = {
  title: "Datagrundlag — Whistklubben",
};

export default function DatagrundlagPage() {
  return (
    <StatsPageShell
      title="Datagrundlag"
      lead="Importkvalitet, feltdækning og planlagte forbedringer."
    >
      <StatsComingSoon />
    </StatsPageShell>
  );
}
