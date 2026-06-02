import { SessionDetailView } from "@/components/stats/SessionDetailView";

type Props = { params: Promise<{ sessionIndex: string }> };

export default async function SessionDetailPage({ params }: Props) {
  const { sessionIndex } = await params;
  const index = Number.parseInt(sessionIndex, 10);
  return <SessionDetailView sessionIndex={Number.isFinite(index) ? index : 0} />;
}
