import { useCallback } from 'react';

interface PasswordValidationResult {
  isValid: boolean;
  errors: string[];
  strength: 'weak' | 'medium' | 'strong' | 'very-strong';
  score: number;
}

export const usePasswordValidation = () => {
  const validatePassword = useCallback((password: string): PasswordValidationResult => {
    const minLength = 8;
    const hasUpperCase = /[A-Z]/.test(password);
    const hasLowerCase = /[a-z]/.test(password);
    const hasNumbers = /\d/.test(password);
    const hasSpecialChar = /[!@#$%^&*(),.?":{}|<>]/.test(password);
    
    const errors: string[] = [];
    
    if (password.length < minLength) {
      errors.push(`Şifre en az ${minLength} karakter olmalıdır`);
    }
    if (!hasUpperCase) {
      errors.push('En az bir büyük harf içermelidir');
    }
    if (!hasLowerCase) {
      errors.push('En az bir küçük harf içermelidir');
    }
    if (!hasNumbers) {
      errors.push('En az bir rakam içermelidir');
    }
    if (!hasSpecialChar) {
      errors.push('En az bir özel karakter içermelidir');
    }
    
    // Şifre gücü hesaplama
    let score = 0;
    if (password.length >= minLength) score++;
    if (hasUpperCase) score++;
    if (hasLowerCase) score++;
    if (hasNumbers) score++;
    if (hasSpecialChar) score++;
    
    // Ekstra puanlar
    if (password.length >= 12) score++;
    if (password.length >= 16) score++;
    if (/[!@#$%^&*(),.?":{}|<>]{2,}/.test(password)) score++; // Birden fazla özel karakter
    
    let strength: 'weak' | 'medium' | 'strong' | 'very-strong';
    if (score <= 2) strength = 'weak';
    else if (score <= 4) strength = 'medium';
    else if (score <= 6) strength = 'strong';
    else strength = 'very-strong';
    
    return {
      isValid: errors.length === 0,
      errors,
      strength,
      score
    };
  }, []);
  
  const getPasswordStrengthColor = useCallback((strength: string) => {
    switch (strength) {
      case 'weak': return 'text-red-500';
      case 'medium': return 'text-yellow-500';
      case 'strong': return 'text-blue-500';
      case 'very-strong': return 'text-green-500';
      default: return 'text-gray-500';
    }
  }, []);
  
  const getPasswordStrengthText = useCallback((strength: string) => {
    switch (strength) {
      case 'weak': return 'Zayıf';
      case 'medium': return 'Orta';
      case 'strong': return 'Güçlü';
      case 'very-strong': return 'Çok Güçlü';
      default: return 'Bilinmiyor';
    }
  }, []);
  
  const getPasswordStrengthIcon = useCallback((strength: string) => {
    switch (strength) {
      case 'weak': return '🔴';
      case 'medium': return '🟡';
      case 'strong': return '🔵';
      case 'very-strong': return '🟢';
      default: return '⚪';
    }
  }, []);
  
  return {
    validatePassword,
    getPasswordStrengthColor,
    getPasswordStrengthText,
    getPasswordStrengthIcon
  };
}; 