
export type Language = 'tr' | 'en';

export interface LanguageContextType {
  language: Language;
  setLanguage: (language: Language) => void;
  t: (key: string, fallback?: string) => string;
  isChanging?: boolean;
}

export interface Translations {
  [key: string]: string;
}

export interface TranslationData {
  tr: Translations;
  en: Translations;
}
