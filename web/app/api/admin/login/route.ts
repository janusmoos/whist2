import { NextResponse } from "next/server";
import {
  adminCookie,
  createAdminToken,
  passwordMatches,
} from "@/lib/adminAuth";

export async function POST(req: Request) {
  const body = (await req.json().catch(() => null)) as
    | { password?: string }
    | null;
  if (!body?.password || !passwordMatches(body.password)) {
    return NextResponse.json(
      { error: "Forkert adgangskode." },
      { status: 401 }
    );
  }

  const response = NextResponse.json({ ok: true });
  response.headers.set("Cache-Control", "private, no-store");
  response.cookies.set(adminCookie.name, createAdminToken(), {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "strict",
    path: "/",
    maxAge: adminCookie.maxAge,
  });
  return response;
}
