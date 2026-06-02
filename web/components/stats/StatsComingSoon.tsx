export function StatsComingSoon({
  title = "Kommer i næste fase",
  description = "Fuld klub-statistik beregnes på Vercel ud fra historisk data og afsluttede spilledage — uden ekstra belastning af appen.",
}: {
  title?: string;
  description?: string;
}) {
  return (
    <div className="stats-coming-soon">
      <p className="stats-coming-soon-title">{title}</p>
      <p className="stats-coming-soon-text">{description}</p>
    </div>
  );
}
