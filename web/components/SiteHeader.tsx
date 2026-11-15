import Link from "next/link";
import { SiteMenu } from "@/components/SiteMenu";

export function SiteHeader({ sub = "live" }: { sub?: string }) {
  return (
    <div className="site-header">
      <Link href="/" className="site-header-brand">
        <h1>Whistklubben</h1>
        <span className="site-sub">{sub}</span>
      </Link>
      <SiteMenu />
    </div>
  );
}
