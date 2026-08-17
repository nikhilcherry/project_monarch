export type Theme = "dark" | "light";

export const THEME_STORAGE_KEY = "offrecord.theme";

/**
 * Runs before first paint, inlined in <head>.
 *
 * Without this the page renders with the default (black) theme and then
 * snaps to white once React hydrates — a full-screen flash. Reading
 * localStorage synchronously here costs a fraction of a millisecond and
 * removes it entirely.
 */
export const themeInitScript = `
(function () {
  try {
    var stored = localStorage.getItem(${JSON.stringify(THEME_STORAGE_KEY)});
    var theme = stored === "light" || stored === "dark"
      ? stored
      : (window.matchMedia("(prefers-color-scheme: light)").matches ? "light" : "dark");
    document.documentElement.setAttribute("data-theme", theme);
  } catch (e) {
    document.documentElement.setAttribute("data-theme", "dark");
  }
})();
`.trim();
