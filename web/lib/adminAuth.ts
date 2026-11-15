import { createHmac, timingSafeEqual } from "node:crypto";
import { cookies } from "next/headers";

const COOKIE_NAME = "whist_admin";
const SESSION_SECONDS = 60 * 60 * 12;

function secret(): string {
  const value = process.env.ADMIN_SESSION_SECRET;
  if (!value) throw new Error("ADMIN_SESSION_SECRET mangler.");
  return value;
}

function signature(value: string): string {
  return createHmac("sha256", secret()).update(value).digest("base64url");
}

function equal(a: string, b: string): boolean {
  const left = Buffer.from(a);
  const right = Buffer.from(b);
  return left.length === right.length && timingSafeEqual(left, right);
}

export function passwordMatches(candidate: string): boolean {
  const expected = process.env.ADMIN_PASSWORD;
  return Boolean(expected) && equal(candidate, expected ?? "");
}

export function createAdminToken(now = Date.now()): string {
  const expires = String(Math.floor(now / 1000) + SESSION_SECONDS);
  return `${expires}.${signature(expires)}`;
}

export function validAdminToken(token: string | undefined, now = Date.now()): boolean {
  if (!token) return false;
  const [expiresRaw, suppliedSignature] = token.split(".");
  const expires = Number(expiresRaw);
  if (!expiresRaw || !suppliedSignature || !Number.isFinite(expires)) return false;
  if (expires <= Math.floor(now / 1000)) return false;
  return equal(suppliedSignature, signature(expiresRaw));
}

export async function isAdminAuthenticated(): Promise<boolean> {
  const store = await cookies();
  return validAdminToken(store.get(COOKIE_NAME)?.value);
}

export const adminCookie = {
  name: COOKIE_NAME,
  maxAge: SESSION_SECONDS,
};
