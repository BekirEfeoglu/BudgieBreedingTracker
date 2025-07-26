import { parseISO, isValid, differenceInDays, differenceInMonths, differenceInYears, format as dateFnsFormat, startOfDay, endOfDay, addDays as dateFnsAddDays } from 'date-fns';

// Temel tarih doğrulama fonksiyonu
export const isValidDate = (date: string | Date): boolean => {
  try {
    const dateObj = typeof date === 'string' ? parseISO(date) : date;
    return isValid(dateObj);
  } catch {
    return false;
  }
};

// Tarihe gün ekleme fonksiyonu
export const addDays = (date: string | Date, days: number): Date => {
  try {
    const dateObj = typeof date === 'string' ? parseISO(date) : date;
    
    if (!isValid(dateObj)) {
      throw new Error('Geçersiz tarih');
    }
    
    return dateFnsAddDays(dateObj, days);
  } catch (error) {
    console.error('Add days error:', error);
    throw error;
  }
};

// Bugünün başlangıcını al (00:00:00)
export const getTodayStart = (): Date => {
  return startOfDay(new Date());
};

// Bugünün sonunu al (23:59:59)
export const getTodayEnd = (): Date => {
  return endOfDay(new Date());
};

// Gelecek tarih kontrolü
export const isFutureDate = (date: string | Date): boolean => {
  try {
    const dateObj = typeof date === 'string' ? parseISO(date) : date;
    if (!isValid(dateObj)) return false;
    
    // Bugünün başlangıcını al (00:00:00)
    const todayStart = getTodayStart();
    
    // Tarihin sadece gün kısmını karşılaştır (saat bilgisini göz ardı et)
    const dateOnly = new Date(dateObj.getFullYear(), dateObj.getMonth(), dateObj.getDate());
    const todayOnly = new Date(todayStart.getFullYear(), todayStart.getMonth(), todayStart.getDate());
    
    return dateOnly > todayOnly;
  } catch {
    return false;
  }
};

// Geçmiş tarih kontrolü
export const isPastDate = (date: string | Date): boolean => {
  try {
    const dateObj = typeof date === 'string' ? parseISO(date) : date;
    if (!isValid(dateObj)) return false;
    
    // Bugünün başlangıcını al (00:00:00)
    const todayStart = getTodayStart();
    
    // Tarihin sadece gün kısmını karşılaştır (saat bilgisini göz ardı et)
    const dateOnly = new Date(dateObj.getFullYear(), dateObj.getMonth(), dateObj.getDate());
    const todayOnly = new Date(todayStart.getFullYear(), todayStart.getMonth(), todayStart.getDate());
    
    return dateOnly < todayOnly;
  } catch {
    return false;
  }
};

// Tarih formatlama fonksiyonları
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

// Yeni: Tarih ve saat formatlama
export const formatDateTime = (date: string | Date): string => {
  try {
    const dateObj = typeof date === 'string' ? parseISO(date) : date;
    
    if (!isValid(dateObj)) {
      return 'Geçersiz tarih';
    }
    
    return dateObj.toLocaleString('tr-TR', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  } catch (error) {
    console.error('DateTime formatting error:', error);
    return 'Geçersiz tarih';
  }
};

// Yeni: Sadece saat formatlama
export const formatTime = (date: string | Date): string => {
  try {
    const dateObj = typeof date === 'string' ? parseISO(date) : date;
    
    if (!isValid(dateObj)) {
      return 'Geçersiz saat';
    }
    
    return dateObj.toLocaleTimeString('tr-TR', {
      hour: '2-digit',
      minute: '2-digit'
    });
  } catch (error) {
    console.error('Time formatting error:', error);
    return 'Geçersiz saat';
  }
};

// Yeni: HTML input için tarih formatı (YYYY-MM-DD)
export const formatDateForInput = (date: string | Date): string => {
  try {
    const dateObj = typeof date === 'string' ? parseISO(date) : date;
    
    if (!isValid(dateObj)) {
      return '';
    }
    
    return dateFnsFormat(dateObj, 'yyyy-MM-dd');
  } catch (error) {
    console.error('Date input formatting error:', error);
    return '';
  }
};

// Yeni: HTML input için saat formatı (HH:mm)
export const formatTimeForInput = (date: string | Date): string => {
  try {
    const dateObj = typeof date === 'string' ? parseISO(date) : date;
    
    if (!isValid(dateObj)) {
      return '';
    }
    
    return dateFnsFormat(dateObj, 'HH:mm');
  } catch (error) {
    console.error('Time input formatting error:', error);
    return '';
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

// Yeni: Gelecek tarihler için göreceli format
export const formatRelativeFutureDate = (date: string | Date): string => {
  try {
    const dateObj = typeof date === 'string' ? parseISO(date) : date;
    
    if (!isValid(dateObj)) {
      return 'Geçersiz tarih';
    }
    
    const now = new Date();
    const diffInDays = Math.floor((dateObj.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
    
    if (diffInDays === 0) return 'Bugün';
    if (diffInDays === 1) return 'Yarın';
    if (diffInDays < 7) return `${diffInDays} gün sonra`;
    if (diffInDays < 30) return `${Math.floor(diffInDays / 7)} hafta sonra`;
    if (diffInDays < 365) return `${Math.floor(diffInDays / 30)} ay sonra`;
    
    return `${Math.floor(diffInDays / 365)} yıl sonra`;
  } catch (error) {
    console.error('Relative future date formatting error:', error);
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

// Yeni: Kuluçka süresi hesaplama (18 gün)
export const calculateIncubationDays = (startDate: string | Date): number => {
  try {
    const startDateObj = typeof startDate === 'string' ? parseISO(startDate) : startDate;
    
    if (!isValid(startDateObj)) {
      return 0;
    }
    
    const now = new Date();
    const diffInDays = Math.floor((now.getTime() - startDateObj.getTime()) / (1000 * 60 * 60 * 24));
    
    return Math.max(0, diffInDays);
  } catch (error) {
    console.error('Incubation days calculation error:', error);
    return 0;
  }
};

// Yeni: Kuluçka durumu kontrolü
export const getIncubationStatus = (startDate: string | Date): {
  days: number;
  remainingDays: number;
  isComplete: boolean;
  progress: number;
} => {
  try {
    const startDateObj = typeof startDate === 'string' ? parseISO(startDate) : startDate;
    
    if (!isValid(startDateObj)) {
      return {
        days: 0,
        remainingDays: 18,
        isComplete: false,
        progress: 0
      };
    }
    
    const days = calculateIncubationDays(startDate);
    const remainingDays = Math.max(0, 18 - days);
    const isComplete = days >= 18;
    const progress = Math.min(100, (days / 18) * 100);
    
    return {
      days,
      remainingDays,
      isComplete,
      progress
    };
  } catch (error) {
    console.error('Incubation status calculation error:', error);
    return {
      days: 0,
      remainingDays: 18,
      isComplete: false,
      progress: 0
    };
  }
};

// Yeni: Tarih ve saat birleştirme
export const combineDateAndTime = (date: string | Date, time: string): Date => {
  try {
    const dateObj = typeof date === 'string' ? parseISO(date) : date;
    
    if (!isValid(dateObj)) {
      throw new Error('Geçersiz tarih');
    }
    
    const timeParts = time.split(':').map(Number);
    const hours = timeParts[0];
    const minutes = timeParts[1];
    
    if (hours === undefined || minutes === undefined || isNaN(hours) || isNaN(minutes)) {
      throw new Error('Geçersiz saat formatı');
    }
    
    const combinedDate = new Date(dateObj);
    combinedDate.setHours(hours, minutes, 0, 0);
    
    return combinedDate;
  } catch (error) {
    console.error('Date and time combination error:', error);
    throw error;
  }
};

// Yeni: Tarih aralığı oluşturma
export const createDateRange = (startDate: string | Date, endDate: string | Date): Date[] => {
  try {
    const start = typeof startDate === 'string' ? parseISO(startDate) : startDate;
    const end = typeof endDate === 'string' ? parseISO(endDate) : endDate;
    
    if (!isValid(start) || !isValid(end)) {
      return [];
    }
    
    const dates: Date[] = [];
    let currentDate = new Date(start);
    
    while (currentDate <= end) {
      dates.push(new Date(currentDate));
      currentDate = new Date(currentDate); // Corrected: addDays(currentDate, 1);
      currentDate.setDate(currentDate.getDate() + 1);
    }
    
    return dates;
  } catch (error) {
    console.error('Date range creation error:', error);
    return [];
  }
};

// Yeni: Saat aralığı oluşturma
export const createTimeRange = (startHour: number, endHour: number, interval: number = 1): string[] => {
  try {
    const times: string[] = [];
    
    for (let hour = startHour; hour <= endHour; hour++) {
      for (let minute = 0; minute < 60; minute += interval * 60) {
        const timeString = `${hour.toString().padStart(2, '0')}:${minute.toString().padStart(2, '0')}`;
        times.push(timeString);
      }
    }
    
    return times;
  } catch (error) {
    console.error('Time range creation error:', error);
    return [];
  }
};

// Yeni: Bildirim için tarih hesaplama
export const calculateNotificationDate = (baseDate: string | Date, daysBefore: number): Date => {
  try {
    const baseDateObj = typeof baseDate === 'string' ? parseISO(baseDate) : baseDate;
    
    if (!isValid(baseDateObj)) {
      throw new Error('Geçersiz tarih');
    }
    
    const notificationDate = new Date(baseDateObj);
    notificationDate.setDate(notificationDate.getDate() - daysBefore);
    
    return notificationDate;
  } catch (error) {
    console.error('Notification date calculation error:', error);
    throw error;
  }
};

// Yeni: Tarih karşılaştırma fonksiyonları
export const isSameDay = (date1: string | Date, date2: string | Date): boolean => {
  try {
    const d1 = typeof date1 === 'string' ? parseISO(date1) : date1;
    const d2 = typeof date2 === 'string' ? parseISO(date2) : date2;
    
    if (!isValid(d1) || !isValid(d2)) {
      return false;
    }
    
    return d1.toDateString() === d2.toDateString();
  } catch (error) {
    console.error('Same day comparison error:', error);
    return false;
  }
};

export const isToday = (date: string | Date): boolean => {
  return isSameDay(date, new Date());
};

export const isYesterday = (date: string | Date): boolean => {
  try {
    const dateObj = typeof date === 'string' ? parseISO(date) : date;
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    
    return isSameDay(dateObj, yesterday);
  } catch (error) {
    console.error('Yesterday check error:', error);
    return false;
  }
};

export const isTomorrow = (date: string | Date): boolean => {
  try {
    const dateObj = typeof date === 'string' ? parseISO(date) : date;
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    
    return isSameDay(dateObj, tomorrow);
  } catch (error) {
    console.error('Tomorrow check error:', error);
    return false;
  }
};

// Yeni: Tarih doğrulama mesajları
export const getDateValidationMessage = (date: string | Date, fieldName: string): string | null => {
  try {
    const dateObj = typeof date === 'string' ? parseISO(date) : date;
    
    if (!isValid(dateObj)) {
      return `${fieldName} geçerli bir tarih olmalıdır`;
    }
    
    if (isFutureDate(dateObj)) {
      return `${fieldName} gelecekte olamaz`;
    }
    
    return null;
  } catch (error) {
    console.error('Date validation message error:', error);
    return `${fieldName} geçerli bir tarih olmalıdır`;
  }
};

// Yeni: Saat doğrulama mesajları
export const getTimeValidationMessage = (time: string): string | null => {
  try {
    const timeParts = time.split(':').map(Number);
    const hours = timeParts[0];
    const minutes = timeParts[1];
    
    if (hours === undefined || minutes === undefined || isNaN(hours) || isNaN(minutes)) {
      return 'Geçerli bir saat formatı giriniz (HH:MM)';
    }
    
    if (hours < 0 || hours > 23) {
      return 'Saat 0-23 arasında olmalıdır';
    }
    
    if (minutes < 0 || minutes > 59) {
      return 'Dakika 0-59 arasında olmalıdır';
    }
    
    return null;
  } catch (error) {
    console.error('Time validation message error:', error);
    return 'Geçerli bir saat formatı giriniz';
  }
};

// Yeni: Tarih ve saat doğrulama
export const validateDateTime = (date: string | Date, time?: string): {
  isValid: boolean;
  message: string | null;
  dateTime?: Date;
} => {
  try {
    const dateObj = typeof date === 'string' ? parseISO(date) : date;
    
    if (!isValid(dateObj)) {
      return {
        isValid: false,
        message: 'Geçerli bir tarih giriniz'
      };
    }
    
    if (time) {
      const timeValidation = getTimeValidationMessage(time);
      if (timeValidation) {
        return {
          isValid: false,
          message: timeValidation
        };
      }
      
      const dateTime = combineDateAndTime(dateObj, time);
      
      if (isFutureDate(dateTime)) {
        return {
          isValid: false,
          message: 'Tarih ve saat gelecekte olamaz'
        };
      }
      
      return {
        isValid: true,
        message: null,
        dateTime
      };
    }
    
    if (isFutureDate(dateObj)) {
      return {
        isValid: false,
        message: 'Tarih gelecekte olamaz'
      };
    }
    
    return {
      isValid: true,
      message: null,
      dateTime: dateObj
    };
  } catch (error) {
    console.error('DateTime validation error:', error);
    return {
      isValid: false,
      message: 'Geçerli bir tarih ve saat giriniz'
    };
  }
};

// Mevcut fonksiyonlar korunuyor
export const getAgeCategory = (birthDate: string | Date): 'chick' | 'adult' => {
  try {
    const birthDateObj = typeof birthDate === 'string' ? parseISO(birthDate) : birthDate;
    
    if (!isValid(birthDateObj)) {
      return 'adult';
    }
    
    const now = new Date();
    const diffInMonths = differenceInMonths(now, birthDateObj);
    
    return diffInMonths < 6 ? 'chick' : 'adult';
  } catch (error) {
    console.error('Age category calculation error:', error);
    return 'adult';
  }
};

export const getAgeCategoryIcon = (birthDate: string | Date): string => {
  const category = getAgeCategory(birthDate);
  return category === 'chick' ? '🐣' : '🦜';
};

export const getAgeCategoryLabel = (birthDate: string | Date, t: (key: string) => string): string => {
  const category = getAgeCategory(birthDate);
  if (category === 'chick') return t('birds.chick');
  if (category === 'adult') return t('birds.adult');
  return t('birds.unknown');
};

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
