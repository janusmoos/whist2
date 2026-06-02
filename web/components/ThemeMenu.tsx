"use client";

import { useEffect, useRef, useState } from "react";
import type { ThemeMode } from "@/lib/posterTypes";
import { THEME_STORAGE_KEY } from "@/lib/posterTypes";

function applyTheme(mode: ThemeMode) {
  document.documentElement.dataset.theme = mode;
  localStorage.setItem(THEME_STORAGE_KEY, mode);
}

export function ThemeMenu() {
  const [open, setOpen] = useState(false);
  const [theme, setTheme] = useState<ThemeMode>("auto");
  const menuRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const stored = localStorage.getItem(THEME_STORAGE_KEY) as ThemeMode | null;
    const initial: ThemeMode =
      stored === "light" || stored === "dark" || stored === "auto" ? stored : "auto";
    setTheme(initial);
    applyTheme(initial);
  }, []);

  useEffect(() => {
    if (!open) return;
    function onDocClick(e: MouseEvent) {
      if (!menuRef.current?.contains(e.target as Node)) setOpen(false);
    }
    document.addEventListener("click", onDocClick);
    return () => document.removeEventListener("click", onDocClick);
  }, [open]);

  function select(mode: ThemeMode) {
    setTheme(mode);
    applyTheme(mode);
    setOpen(false);
  }

  return (
    <div className="theme-menu" ref={menuRef}>
      <button
        type="button"
        className="theme-menu-btn"
        aria-label="Indstillinger"
        aria-expanded={open}
        onClick={() => setOpen((v) => !v)}
      >
        <span className="theme-menu-icon" aria-hidden="true">
          <span />
          <span />
          <span />
        </span>
      </button>

      {open ? (
        <div className="theme-menu-panel" role="menu">
          <p className="theme-menu-title">Tema</p>
          {(
            [
              ["auto", "Auto"],
              ["light", "Normal"],
              ["dark", "Dark mode"],
            ] as const
          ).map(([mode, label]) => (
            <button
              key={mode}
              type="button"
              role="menuitemradio"
              aria-checked={theme === mode}
              className={`theme-menu-option${theme === mode ? " theme-menu-option--active" : ""}`}
              onClick={() => select(mode)}
            >
              {label}
            </button>
          ))}
        </div>
      ) : null}
    </div>
  );
}
