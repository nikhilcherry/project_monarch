"use client";

import { MoonIcon, SunIcon } from "@phosphor-icons/react";
import { useTheme } from "./ThemeProvider";

export function ThemeToggle() {
  const { theme, toggleTheme } = useTheme();
  const nextLabel = theme === "dark" ? "Switch to light theme" : "Switch to dark theme";

  return (
    <button
      type="button"
      className="btn btn-icon"
      onClick={toggleTheme}
      aria-label={nextLabel}
      title={nextLabel}
    >
      {theme === "dark" ? <SunIcon size={20} /> : <MoonIcon size={20} weight="fill" />}
    </button>
  );
}
