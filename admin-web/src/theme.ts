import { useEffect, useState } from "react";

type Theme = "light" | "dark";
const system = window.matchMedia("(prefers-color-scheme: dark)");
function preference(): Theme {
  const saved = localStorage.getItem("patag-theme");
  return saved === "light" || saved === "dark" ? saved : system.matches ? "dark" : "light";
}
function apply(theme: Theme) {
  document.documentElement.dataset.theme = theme;
  document.documentElement.style.colorScheme = theme;
}
apply(preference());

export function useTheme() {
  const [theme, setTheme] = useState<Theme>(preference);
  useEffect(() => {
    const sync = () => { const next = preference(); apply(next); setTheme(next); };
    system.addEventListener("change", sync);
    window.addEventListener("storage", sync);
    return () => { system.removeEventListener("change", sync); window.removeEventListener("storage", sync); };
  }, []);
  return { theme, toggleTheme: () => {
    const next = theme === "dark" ? "light" : "dark";
    localStorage.setItem("patag-theme", next);
    apply(next);
    setTheme(next);
  } };
}
