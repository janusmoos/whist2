"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useRef, useState } from "react";
import type { ThemeMode } from "@/lib/posterTypes";
import { THEME_STORAGE_KEY } from "@/lib/posterTypes";
import { SITE_MENU_NAV } from "@/lib/stats/navigation";

function applyTheme(mode: ThemeMode) {
  document.documentElement.dataset.theme = mode;
  localStorage.setItem(THEME_STORAGE_KEY, mode);
}

export function SiteMenu() {
  const pathname = usePathname();
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
    setOpen(false);
  }, [pathname]);

  useEffect(() => {
    if (!open) return;
    function onDocClick(e: MouseEvent) {
      if (!menuRef.current?.contains(e.target as Node)) setOpen(false);
    }
    document.addEventListener("click", onDocClick);
    return () => document.removeEventListener("click", onDocClick);
  }, [open]);

  function selectTheme(mode: ThemeMode) {
    setTheme(mode);
    applyTheme(mode);
  }

  function isActive(href: string): boolean {
    if (href === "/") return pathname === "/";
    return pathname === href || pathname.startsWith(`${href}/`);
  }

  return (
    <div className="site-menu" ref={menuRef}>
      <button
        type="button"
        className="site-menu-btn"
        aria-label="Menu"
        aria-expanded={open}
        onClick={() => setOpen((v) => !v)}
      >
        <span className="site-menu-icon" aria-hidden="true">
          <span />
          <span />
          <span />
        </span>
      </button>

      {open ? (
        <div className="site-menu-panel" role="menu">
          <p className="site-menu-title">Navigation</p>
          {SITE_MENU_NAV.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              role="menuitem"
              className={`site-menu-link${
                "indent" in item && item.indent ? " site-menu-link--indent" : ""
              }${isActive(item.href) ? " site-menu-link--active" : ""}`}
              onClick={() => setOpen(false)}
            >
              {item.label}
            </Link>
          ))}

          <div className="site-menu-divider" role="separator" />

          <p className="site-menu-title">Tema</p>
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
              className={`site-menu-option${theme === mode ? " site-menu-option--active" : ""}`}
              onClick={() => selectTheme(mode)}
            >
              {label}
            </button>
          ))}
        </div>
      ) : null}
    </div>
  );
}
