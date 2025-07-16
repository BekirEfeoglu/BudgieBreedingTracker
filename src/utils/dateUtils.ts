import { parseISO, isValid, differenceInDays, differenceInMonths, differenceInYears } from 'date-fns';

export const formatDate = (date: string | Date): string => {
  try {
    const dateObj = typeof date === 'string' ? parseISO(date) : date;
    
    if (!isValid(dateObj)) {
      return 'Geçersiz tarih';
    }
    
    return dateObj.toLocaleDateString('tr-TR', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
  } catch (error) {
    console.error('Date formatting error:', error);
    return 'Geçersiz tarih';
  }
};

export const formatDateShort = (date: string | Date): string => {
  try {
    const dateObj = typeof date === 'string' ? parseISO(date) : date;
    
    if (!isValid(dateObj)) {
      return 'Geçersiz tarih';
    }
    
    return dateObj.toLocaleDateString('tr-TR', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  } catch (error) {
    console.error('Date formatting error:', error);
    return 'Geçersiz tarih';
  }
};

export const formatRelativeDate = (date: string | Date): string => {
  try {
    const dateObj = typeof date === 'string' ? parseISO(date) : date;
    
    if (!isValid(dateObj)) {
      return 'Geçersiz tarih';
    }
    
    const now = new Date();
    const diffInDays = Math.floor((now.getTime() - dateObj.getTime()) / (1000 * 60 * 60 * 24));
    
    if (diffInDays === 0) return 'Bugün';
    if (diffInDays === 1) return 'Dün';
    if (diffInDays < 7) return `${diffInDays} gün önce`;
    if (diffInDays < 30) return `${Math.floor(diffInDays / 7)} hafta önce`;
    if (diffInDays < 365) return `${Math.floor(diffInDays / 30)} ay önce`;
    
    return `${Math.floor(diffInDays / 365)} yıl önce`;
  } catch (error) {
    console.error('Relative date formatting error:', error);
    return 'Geçersiz tarih';
  }
};

export const calculateAge = (birthDate: string | Date): string => {
  try {
    const birthDateObj = typeof birthDate === 'string' ? parseISO(birthDate) : birthDate;
    
    if (!isValid(birthDateObj)) {
      return 'Bilinmiyor';
    }
    
    const now = new Date();
    const diffInDays = Math.floor((now.getTime() - birthDateObj.getTime()) / (1000 * 60 * 60 * 24));
    
    if (diffInDays < 30) return `${diffInDays} günlük`;
    if (diffInDays < 365) return `${Math.floor(diffInDays / 30)} aylık`;
    
    const years = Math.floor(diffInDays / 365);
    const remainingMonths = Math.floor((diffInDays % 365) / 30);
    
    if (remainingMonths === 0) return `${years} yaşında`;
    return `${years} yaş ${remainingMonths} ay`;
  } catch (error) {
    console.error('Age calculation error:', error);
    return 'Bilinmiyor';
  }
};

// Yeni fonksiyon: Yaş kategorisini belirle (Yavru/Yetişkin)
export const getAgeCategory = (birthDate: string | Date): 'chick' | 'adult' => {
  try {
    const birthDateObj = typeof birthDate === 'string' ? parseISO(birthDate) : birthDate;
    
    if (!isValid(birthDateObj)) {
      return 'adult'; // Geçersiz tarih durumunda yetişkin olarak kabul et
    }
    
    const now = new Date();
    const diffInMonths = differenceInMonths(now, birthDateObj);
    
    // 6 aydan küçükse yavru, büyükse yetişkin
    return diffInMonths < 6 ? 'chick' : 'adult';
  } catch (error) {
    console.error('Age category calculation error:', error);
    return 'adult';
  }
};

// Yeni fonksiyon: Yaş kategorisi ikonunu getir
export const getAgeCategoryIcon = (birthDate: string | Date): string => {
  const category = getAgeCategory(birthDate);
  return category === 'chick' ? '🐣' : '🦜';
};

// Yeni fonksiyon: Yaş kategorisi etiketini getir
export const getAgeCategoryLabel = (birthDate: string | Date, t: (key: string) => string): string => {
  const category = getAgeCategory(birthDate);
  if (category === 'chick') return t('birds.chick');
  if (category === 'adult') return t('birds.adult');
  return t('birds.unknown');
};

// Yeni fonksiyon: Detaylı yaş bilgisi
export const getDetailedAge = (birthDate: string | Date): {
  days: number;
  months: number;
  years: number;
  category: 'chick' | 'adult';
  icon: string;
} => {
  try {
    const birthDateObj = typeof birthDate === 'string' ? parseISO(birthDate) : birthDate;
    
    if (!isValid(birthDateObj)) {
      return {
        days: 0,
        months: 0,
        years: 0,
        category: 'adult',
        icon: '🦜'
      };
    }
    
    const now = new Date();
    const days = differenceInDays(now, birthDateObj);
    const months = differenceInMonths(now, birthDateObj);
    const years = differenceInYears(now, birthDateObj);
    
    const category = months < 6 ? 'chick' : 'adult';
    const icon = category === 'chick' ? '🐣' : '🦜';
    
    return {
      days,
      months,
      years,
      category,
      icon
    };
  } catch (error) {
    console.error('Detailed age calculation error:', error);
    return {
      days: 0,
      months: 0,
      years: 0,
      category: 'adult',
      icon: '🦜'
    };
  }
};
