
import { Language } from '@/types/language';
import { translations } from '@/data/translations';

export const getTranslation = (language: Language, key: string, fallback?: string): string => {
  const keys = key.split('.');
  let translation: any = translations[language];
  
  for (const k of keys) {
    if (translation && typeof translation === 'object' && k in translation) {
      translation = translation[k];
    } else {
      return fallback || key;
    }
  }
  
  return typeof translation === 'string' ? translation : fallback || key;
};

export const getSavedLanguage = (): Language => {
  const savedLanguage = localStorage.getItem('language') as Language;
  return (savedLanguage && (savedLanguage === 'tr' || savedLanguage === 'en')) ? savedLanguage : 'tr';
};

export const saveLanguage = (language: Language): void => {
  localStorage.setItem('language', language);
};
