/**
 * Input sanitization utilities for security
 */

export const sanitizeText = (input: string | null | undefined): string => {
  if (!input) return '';
  
  return input
    .trim()
    .replace(/[<>]/g, '') // Remove potential HTML tags
    .replace(/javascript:/gi, '') // Remove javascript: protocol
    .replace(/on\w+=/gi, '') // Remove event handlers
    .slice(0, 1000); // Limit length
};

export const sanitizeHtml = (input: string | null | undefined): string => {
  if (!input) return '';
  
  return input
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#x27;')
    .replace(/\//g, '&#x2F;');
};

export const sanitizeNumber = (input: number | string | null | undefined): number | null => {
  if (input === null || input === undefined || input === '') return null;
  
  const num = typeof input === 'string' ? parseFloat(input) : input;
  if (isNaN(num) || !isFinite(num)) return null;
  
  return num;
};

export const sanitizeRingNumber = (input: string | null | undefined): string => {
  if (!input) return '';
  
  return input
    .trim()
    .replace(/[^a-zA-Z0-9\-_]/g, '') // Only allow alphanumeric, hyphens, underscores
    .slice(0, 20); // Limit length
};

export const validateEmail = (email: string): boolean => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email) && email.length <= 254;
};

export const validateName = (name: string): { isValid: boolean; errors: string[] } => {
  const errors: string[] = [];
  
  if (!name || name.trim().length === 0) {
    errors.push('Bu alan zorunludur');
    return { isValid: false, errors };
  }
  
  const trimmedName = name.trim();
  
  if (trimmedName.length < 2) {
    errors.push('En az 2 karakter olmalıdır');
  }
  
  if (trimmedName.length > 50) {
    errors.push('Maksimum 50 karakter olabilir');
  }
  
  // Türkçe karakterler dahil sadece harf ve boşluk kabul et
  const nameRegex = /^[a-zA-ZğüşıöçĞÜŞİÖÇ\s]+$/;
  if (!nameRegex.test(trimmedName)) {
    errors.push('Sadece harf ve boşluk kullanabilirsiniz');
  }
  
  // Ardışık boşlukları kontrol et
  if (/\s{2,}/.test(trimmedName)) {
    errors.push('Ardışık boşluk kullanamazsınız');
  }
  
  // Başında ve sonunda boşluk kontrolü
  if (trimmedName !== name) {
    errors.push('Başında ve sonunda boşluk olamaz');
  }
  
  return {
    isValid: errors.length === 0,
    errors
  };
};

export const validatePassword = (password: string): { isValid: boolean; errors: string[] } => {
  const errors: string[] = [];
  
  if (password.length < 6) {
    errors.push('Şifre en az 6 karakter olmalıdır');
  }
  
  // Daha esnek kurallar - en az 2 kriteri karşılamalı
  const hasUpperCase = /[A-Z]/.test(password);
  const hasLowerCase = /[a-z]/.test(password);
  const hasNumbers = /[0-9]/.test(password);
  const hasSpecialChar = /[!@#$%^&*(),.?":{}|<>]/.test(password);
  
  const criteriaCount = [hasUpperCase, hasLowerCase, hasNumbers, hasSpecialChar].filter(Boolean).length;
  
  if (criteriaCount < 2) {
    errors.push('Şifre en az 2 farklı karakter türü içermelidir (büyük harf, küçük harf, rakam, özel karakter)');
  }
  
  return {
    isValid: errors.length === 0,
    errors
  };
};

export const encryptLocalStorage = (key: string, data: any): void => {
  try {
    // Simple encryption for client-side storage
    const jsonData = JSON.stringify(data);
    const encoded = btoa(jsonData);
    localStorage.setItem(key, encoded);
  } catch (error) {
    console.error('LocalStorage encryption error:', error);
  }
};

export const decryptLocalStorage = <T>(key: string): T | null => {
  try {
    const encoded = localStorage.getItem(key);
    if (!encoded) return null;
    
    const decoded = atob(encoded);
    return JSON.parse(decoded) as T;
  } catch (error) {
    console.error('LocalStorage decryption error:', error);
    localStorage.removeItem(key); // Remove corrupted data
    return null;
  }
};

export const sanitizeFileUpload = (file: File): { isValid: boolean; error?: string } => {
  const allowedTypes = ['image/jpeg', 'image/png', 'image/webp'];
  const maxSize = 5 * 1024 * 1024; // 5MB
  
  if (!allowedTypes.includes(file.type)) {
    return { isValid: false, error: 'Desteklenmeyen dosya formatı' };
  }
  
  if (file.size > maxSize) {
    return { isValid: false, error: 'Dosya boyutu çok büyük (max: 5MB)' };
  }
  
  // Check for suspicious file names
  const suspiciousPatterns = [
    /\.php$/i,
    /\.js$/i,
    /\.html$/i,
    /\.exe$/i,
    /script/i,
    /<script/i
  ];
  
  if (suspiciousPatterns.some(pattern => pattern.test(file.name))) {
    return { isValid: false, error: 'Güvenlik nedeniyle bu dosya türü kabul edilmiyor' };
  }
  
  return { isValid: true };
};

export const rateLimitCheck = (key: string, limit: number, windowMs: number): boolean => {
  // Rate limiting devre dışı kontrolü
  if (localStorage.getItem('rateLimitDisabled') === 'true') {
    console.log(`⚠️ Rate limiting devre dışı: ${key}`);
    return true;
  }
  
  const now = Date.now();
  const attempts = JSON.parse(localStorage.getItem(`rateLimit_${key}`) || '[]') as number[];
  
  // Remove attempts outside the time window
  const validAttempts = attempts.filter(time => now - time < windowMs);
  
  if (validAttempts.length >= limit) {
    return false; // Rate limit exceeded
  }
  
  // Add current attempt
  validAttempts.push(now);
  localStorage.setItem(`rateLimit_${key}`, JSON.stringify(validAttempts));
  
  return true; // Allow request
};

// Rate limit verilerini temizleme fonksiyonu
export const clearAllRateLimits = (): void => {
  const keysToRemove = [];
  for (let i = 0; i < localStorage.length; i++) {
    const key = localStorage.key(i);
    if (key && key.startsWith('rateLimit_')) {
      keysToRemove.push(key);
    }
  }
  keysToRemove.forEach(key => localStorage.removeItem(key));
  console.log('✅ Tüm rate limit verileri temizlendi');
};