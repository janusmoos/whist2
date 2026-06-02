import { GameTypeDetailView } from "@/components/stats/GameTypeDetailView";

type Props = { params: Promise<{ slug: string }> };

export default async function GameTypeDetailPage({ params }: Props) {
  const { slug } = await params;
  return <GameTypeDetailView slug={slug} />;
}
