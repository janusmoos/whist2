import { GameDetailView } from "@/components/stats/GameDetailView";

type Props = { params: Promise<{ gameId: string }> };

export default async function GameDetailPage({ params }: Props) {
  const { gameId } = await params;
  return <GameDetailView gameId={decodeURIComponent(gameId)} />;
}
