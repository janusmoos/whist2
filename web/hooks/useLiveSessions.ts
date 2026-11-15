"use client";

import { useEffect, useRef, useState } from "react";
import type { LiveSession } from "@/lib/liveSessionTypes";

export function useLiveSessions(pollMs = 2000) {
  const [sessions, setSessions] = useState<LiveSession[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const cancelledRef = useRef(false);

  useEffect(() => {
    cancelledRef.current = false;

    async function fetchSessions() {
      try {
        const res = await fetch("/api/sessions", { cache: "no-store" });
        const data = await res.json();
        if (!res.ok) {
          throw new Error(
            typeof data.error === "string" ? data.error : "Serverfejl"
          );
        }
        if (!cancelledRef.current) {
          setSessions(Array.isArray(data) ? data : []);
          setError(null);
          setLoading(false);
        }
      } catch (e) {
        if (!cancelledRef.current) {
          setError(e instanceof Error ? e.message : "Netværksfejl");
          setLoading(false);
        }
      }
    }

    fetchSessions();
    const id = setInterval(fetchSessions, pollMs);
    return () => {
      cancelledRef.current = true;
      clearInterval(id);
    };
  }, [pollMs]);

  return { sessions, error, loading };
}
