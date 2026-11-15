"use client";

import { useEffect, useState } from "react";
import type { ClubStatsModel } from "@/lib/stats/historicalTypes";

export function useClubStats() {
  const [model, setModel] = useState<ClubStatsModel | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;

    async function load() {
      try {
        const res = await fetch("/api/stats/club", { cache: "no-store" });
        const data = await res.json();
        if (!res.ok) {
          throw new Error(typeof data.error === "string" ? data.error : "Serverfejl");
        }
        if (!cancelled) {
          setModel(data as ClubStatsModel);
          setError(null);
          setLoading(false);
        }
      } catch (e) {
        if (!cancelled) {
          setError(e instanceof Error ? e.message : "Netværksfejl");
          setLoading(false);
        }
      }
    }

    load();
    return () => {
      cancelled = true;
    };
  }, []);

  return { model, error, loading };
}
