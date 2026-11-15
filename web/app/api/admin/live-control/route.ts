import { NextResponse } from "next/server";
import { isAdminAuthenticated } from "@/lib/adminAuth";
import { setLiveControl } from "@/lib/liveControl";

export async function POST(req: Request) {
  if (!(await isAdminAuthenticated())) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = (await req.json().catch(() => null)) as
    | { enabled?: boolean }
    | null;
  if (typeof body?.enabled !== "boolean") {
    return NextResponse.json({ error: "Ugyldig status." }, { status: 400 });
  }

  return NextResponse.json(await setLiveControl(body.enabled), {
    headers: { "Cache-Control": "private, no-store" },
  });
}
