import { useSyncExternalStore } from "react";
import tagalog from "./tagalog.json";

export type Language = "en" | "tl";
const preferenceKey = "patag-language";
const changed = "patag-language-change";
export const languages = [{ value: "en", label: "English" }, { value: "tl", label: "Tagalog" }] as const;
export function getLanguage(): Language {
  try { return localStorage.getItem(preferenceKey) === "tl" ? "tl" : "en"; }
  catch { return "en"; }
}
export function translate(text: string, language = getLanguage()): string {
  return language === "tl" && Object.hasOwn(tagalog, text)
    ? (tagalog as Record<string, string>)[text] : text;
}
export function setLanguage(language: Language) {
  if (!languages.some(option => option.value === language)) return;
  localStorage.setItem(preferenceKey, language);
  window.dispatchEvent(new Event(changed));
}
function subscribe(listener: () => void) {
  window.addEventListener(changed, listener);
  window.addEventListener("storage", listener);
  return () => {
    window.removeEventListener(changed, listener);
    window.removeEventListener("storage", listener);
  };
}
export function useLanguage() {
  return useSyncExternalStore(subscribe, getLanguage, () => "en" as Language);
}
