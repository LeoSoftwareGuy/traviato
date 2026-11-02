// Web teaser copy (#310), EN + RU. RU is a draft pending native review;
// gendered forms use the neutral "(-ась)" pattern until profiles store one.

export type Lang = "en" | "ru";

export const strings = {
  en: {
    cta: "Create an account to see <em>the whole memory</em>",
    more: (n: number) => `+${n} more`,
    moreSub: "Photos · notes · the film",
    moreSubNoFilm: "Photos · notes",
    openInApp: "Already have Storyni? <span>Open in the app</span>",
    sharedBy: (name: string) => `Shared by <strong>${name}</strong>`,
    unavailableEyebrow: "Link unavailable",
    unavailableTitle: "This memory <em>isn't shared anymore</em>",
    unavailableBody:
      "The link was turned off, or it was never right. If someone sent it to you, ask them for a new one.",
    startOwn: "Start your own memory",
    appStore: "Download on the App Store",
    googlePlay: "Get it on Google Play",
    days: (n: number) => (n === 1 ? "1 day" : `${n} days`),
    ogDescription: (name: string) => `${name} shared a memory on Storyni.`,
    ogDescriptionAnon: "A memory shared on Storyni.",
    ogUnavailableTitle: "A memory on Storyni",
  },
  ru: {
    cta: "Создайте аккаунт, чтобы увидеть <em>воспоминание целиком</em>",
    more: (n: number) => `Ещё ${n}`,
    moreSub: "Фото · заметки · фильм",
    moreSubNoFilm: "Фото · заметки",
    openInApp: "Уже есть Storyni? <span>Открыть в приложении</span>",
    sharedBy: (name: string) => `Поделился(-ась) <strong>${name}</strong>`,
    unavailableEyebrow: "Ссылка недоступна",
    unavailableTitle: "Этим воспоминанием <em>больше не делятся</em>",
    unavailableBody:
      "Ссылку отключили или она неверная. Попросите у отправителя новую.",
    startOwn: "Начать своё воспоминание",
    appStore: "Загрузите в App Store",
    googlePlay: "Доступно в Google Play",
    days: (n: number) => `${n} ${ruPlural(n, "день", "дня", "дней")}`,
    ogDescription: (name: string) =>
      `${name} поделился(-ась) воспоминанием в Storyni.`,
    ogDescriptionAnon: "Воспоминание в Storyni.",
    ogUnavailableTitle: "Воспоминание в Storyni",
  },
} as const;

export type Strings = (typeof strings)[Lang];

function ruPlural(n: number, one: string, few: string, many: string): string {
  const mod10 = n % 10;
  const mod100 = n % 100;
  if (mod10 === 1 && mod100 !== 11) return one;
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return few;
  return many;
}

/** The first of en / ru the browser asks for; English otherwise. */
export function pickLang(acceptLanguage: string | null): Lang {
  const tags = (acceptLanguage ?? "")
    .split(",")
    .map((part) => {
      const [tag, q] = part.trim().split(";q=");
      return { tag: tag.toLowerCase(), q: q === undefined ? 1 : Number(q) };
    })
    .filter((t) => t.tag.length > 0 && !Number.isNaN(t.q))
    .sort((a, b) => b.q - a.q);
  for (const { tag } of tags) {
    if (tag.startsWith("ru")) return "ru";
    if (tag.startsWith("en")) return "en";
  }
  return "en";
}

const months = {
  en: [
    "JAN",
    "FEB",
    "MAR",
    "APR",
    "MAY",
    "JUN",
    "JUL",
    "AUG",
    "SEP",
    "OCT",
    "NOV",
    "DEC",
  ],
  ru: [
    "ЯНВ",
    "ФЕВ",
    "МАР",
    "АПР",
    "МАЯ",
    "ИЮН",
    "ИЮЛ",
    "АВГ",
    "СЕН",
    "ОКТ",
    "НОЯ",
    "ДЕК",
  ],
};

/**
 * `12–16 AUG 2026` · `30 JUL – 2 AUG 2026` · `30 DEC 2026 – 2 JAN 2027` —
 * the app's L10nDates.dateRange, uppercased.
 */
export function dateRange(start: string, end: string, lang: Lang): string {
  const [y1, m1, d1] = start.split("-").map(Number);
  const [y2, m2, d2] = end.split("-").map(Number);
  const mon = months[lang];
  const full = (y: number, m: number, d: number) => `${d} ${mon[m - 1]} ${y}`;
  if (y1 === y2 && m1 === m2) {
    return d1 === d2 ? full(y1, m1, d1) : `${d1}–${full(y2, m2, d2)}`;
  }
  if (y1 === y2) return `${d1} ${mon[m1 - 1]} – ${full(y2, m2, d2)}`;
  return `${full(y1, m1, d1)} – ${full(y2, m2, d2)}`;
}
