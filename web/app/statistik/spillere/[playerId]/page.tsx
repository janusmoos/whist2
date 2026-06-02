import { PlayerDetailView } from "@/components/stats/PlayerDetailView";

type Props = { params: Promise<{ playerId: string }> };

export default async function PlayerDetailPage({ params }: Props) {
  const { playerId } = await params;
  return <PlayerDetailView playerId={decodeURIComponent(playerId)} />;
}
