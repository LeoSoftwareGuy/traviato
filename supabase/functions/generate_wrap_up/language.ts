// The language the AI writes the wrap-up's lines in (#250): the app's
// resolved UI language, sent in the request body. `profiles.language` can't
// be used — NULL there means "follow the device", which the server can't see.

export type WrapUpLanguage = "en" | "ru";

// Anything missing or unknown falls back to English.
export function parseWrapUpLanguage(value: unknown): WrapUpLanguage {
  return value === "ru" ? "ru" : "en";
}

// The prompt's closing instruction for [language], or "" for English (the
// prompt's own language).
export function languageInstruction(language: WrapUpLanguage): string {
  switch (language) {
    case "ru":
      return "\n\nWrite every field in natural, warm Russian, addressing the " +
        'reader as "вы". Keep the trip name and place names exactly as given.';
    case "en":
      return "";
  }
}
