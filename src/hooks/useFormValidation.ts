import { z } from 'zod';
import { useCallback } from 'react';
import { isFutureDate, validateDateTime } from '@/utils/dateUtils';

// Tarih doğrulama yardımcı fonksiyonu
const validateDateNotFuture = (date: Date, fieldName: string = 'Tarih') => {
  if (isFutureDate(date)) {
    return `${fieldName} gelecekte olamaz`;
  }
  return null;
};

// Tarih ve saat doğrulama yardımcı fonksiyonu
const validateDateTimeNotFuture = (date: Date, time?: string, fieldName: string = 'Tarih') => {
  const validation = validateDateTime(date, time);
  if (!validation.isValid) {
    return validation.message || `${fieldName} geçerli olmalıdır`;
  }
  return null;
};

// Kuş formu için validation schema
export const birdFormSchema = z.object({
  name: z.string()
    .min(1, 'Kuş adı zorunludur')
    .min(2, 'Kuş adı en az 2 karakter olmalıdır')
    .max(50, 'Kuş adı en fazla 50 karakter olabilir')
    .regex(/^[a-zA-ZçğıöşüÇĞIİÖŞÜ\s-]+$/, 'Kuş adı sadece harfler, boşluk ve tire içerebilir'),
  
  gender: z.enum(['male', 'female', 'unknown'], {
    required_error: 'Cinsiyet seçimi zorunludur'
  }),
  
  color: z.string()
    .max(100, 'Renk açıklaması en fazla 100 karakter olabilir')
    .optional(),
  
  birthDate: z.date()
    .refine((date) => !isFutureDate(date), 'Doğum tarihi gelecekte olamaz')
    .nullable()
    .optional(),
  
  ringNumber: z.string()
    .max(20, 'Halka numarası en fazla 20 karakter olabilir')
    .regex(/^[a-zA-Z0-9-]*$/, 'Halka numarası sadece harf, rakam ve tire içerebilir')
    .refine((val) => {
      if (!val || val.trim() === '') return true;
      return val.trim().length >= 2;
    }, 'Halka numarası en az 2 karakter olmalıdır')
    .optional(),
  
  motherId: z.string().optional(),
  fatherId: z.string().optional(),
  
  healthNotes: z.string()
    .max(500, 'Sağlık notları en fazla 500 karakter olabilir')
    .optional(),
  
  photo: z.string().optional()
});

// Kuluçka formu için validation schema
export const incubationFormSchema = z.object({
  incubationName: z.string()
    .min(1, 'Kuluçka adı zorunludur')
    .max(50, 'Kuluçka adı en fazla 50 karakter olabilir'),
  
  motherId: z.string()
    .min(1, 'Anne kuş seçimi zorunludur'),
  
  fatherId: z.string()
    .min(1, 'Baba kuş seçimi zorunludur'),
  
  startDate: z.date({
    required_error: 'Başlangıç tarihi zorunludur'
  })
    .refine((date) => !isFutureDate(date), 'Başlangıç tarihi gelecekte olamaz'),
  
  enableNotifications: z.boolean(),
  
  notes: z.string()
    .max(500, 'Notlar en fazla 500 karakter olabilir')
    .optional()
});

// Yumurta formu için validation schema
export const eggFormSchema = z.object({
  id: z.string().optional(),
  clutchId: z.string()
    .min(1, 'Kuluçka seçimi zorunludur'),
  
  eggNumber: z.number()
    .min(1, 'Yumurta numarası 1 veya daha büyük olmalıdır')
    .max(20, 'Yumurta numarası 20\'den büyük olamaz'),
  
  startDate: z.date({
    required_error: 'Başlangıç tarihi zorunludur'
  })
    .refine((date) => !isFutureDate(date), 'Başlangıç tarihi gelecekte olamaz'),
  
  status: z.enum(['laid', 'fertile', 'hatched', 'infertile']),
  
  notes: z.string()
    .max(300, 'Notlar en fazla 300 karakter olabilir')
    .optional()
});

// Yavru formu için validation schema
export const chickFormSchema = z.object({
  name: z.string()
    .min(1, 'Yavru adı zorunludur')
    .min(2, 'Yavru adı en az 2 karakter olmalıdır')
    .max(50, 'Yavru adı en fazla 50 karakter olabilir'),
  
  gender: z.enum(['male', 'female', 'unknown'], {
    required_error: 'Cinsiyet seçimi zorunludur'
  }),
  
  hatchDate: z.date({
    required_error: 'Çıkış tarihi zorunludur'
  })
    .refine((date) => !isFutureDate(date), 'Çıkış tarihi gelecekte olamaz'),
  
  motherId: z.string()
    .min(1, 'Anne kuş seçimi zorunludur'),
  
  fatherId: z.string()
    .min(1, 'Baba kuş seçimi zorunludur'),
  
  color: z.string()
    .max(100, 'Renk açıklaması en fazla 100 karakter olabilir')
    .optional(),
  
  ringNumber: z.string()
    .max(20, 'Halka numarası en fazla 20 karakter olabilir')
    .regex(/^[a-zA-Z0-9-]*$/, 'Halka numarası sadece harf, rakam ve tire içerebilir')
    .refine((val) => {
      if (!val || val.trim() === '') return true;
      return val.trim().length >= 2;
    }, 'Halka numarası en az 2 karakter olmalıdır')
    .optional(),
  
  healthNotes: z.string()
    .max(500, 'Sağlık notları en fazla 500 karakter olabilir')
    .optional()
});

// Yeni: Bildirim formu için validation schema
export const notificationFormSchema = z.object({
  type: z.enum(['incubation', 'feeding', 'veterinary', 'breeding', 'event']),
  
  title: z.string()
    .min(1, 'Başlık zorunludur')
    .max(100, 'Başlık en fazla 100 karakter olabilir'),
  
  date: z.date({
    required_error: 'Tarih zorunludur'
  }),
  
  time: z.string()
    .regex(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/, 'Geçerli saat formatı giriniz (HH:MM)')
    .optional(),
  
  description: z.string()
    .max(500, 'Açıklama en fazla 500 karakter olabilir')
    .optional(),
  
  enabled: z.boolean().default(true)
}).refine((data) => {
  if (data.time) {
    const validation = validateDateTime(data.date, data.time);
    return validation.isValid;
  }
  return !isFutureDate(data.date);
}, {
  message: 'Bildirim tarihi gelecekte olamaz',
  path: ['date']
});

// Yeni: Etkinlik formu için validation schema
export const eventFormSchema = z.object({
  title: z.string()
    .min(1, 'Etkinlik adı zorunludur')
    .min(2, 'Etkinlik adı en az 2 karakter olmalıdır')
    .max(100, 'Etkinlik adı en fazla 100 karakter olabilir'),
  
  date: z.date({
    required_error: 'Etkinlik tarihi zorunludur'
  }),
  
  time: z.string()
    .regex(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/, 'Geçerli saat formatı giriniz (HH:MM)')
    .optional(),
  
  type: z.enum(['competition', 'exhibition', 'show', 'meeting', 'custom']),
  
  location: z.string()
    .max(200, 'Konum en fazla 200 karakter olabilir')
    .optional(),
  
  description: z.string()
    .max(1000, 'Açıklama en fazla 1000 karakter olabilir')
    .optional(),
  
  color: z.string().optional(),
  icon: z.string().optional()
});

// Yeni: Veteriner randevu formu için validation schema
export const veterinaryAppointmentSchema = z.object({
  birdId: z.string()
    .min(1, 'Kuş seçimi zorunludur'),
  
  appointmentType: z.enum(['checkup', 'vaccination', 'treatment', 'emergency']),
  
  date: z.date({
    required_error: 'Randevu tarihi zorunludur'
  }),
  
  time: z.string()
    .regex(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/, 'Geçerli saat formatı giriniz (HH:MM)')
    .optional(),
  
  vetName: z.string()
    .max(100, 'Veteriner adı en fazla 100 karakter olabilir')
    .optional(),
  
  notes: z.string()
    .max(500, 'Notlar en fazla 500 karakter olabilir')
    .optional()
}).refine((data) => {
  if (data.time) {
    const validation = validateDateTime(data.date, data.time);
    return validation.isValid;
  }
  return !isFutureDate(data.date);
}, {
  message: 'Randevu tarihi gelecekte olamaz',
  path: ['date']
});

export const useFormValidation = () => {
  const validateBirdForm = useCallback((data: unknown) => {
    try {
      return birdFormSchema.parse(data);
    } catch (error) {
      if (error instanceof z.ZodError) {
        const formattedErrors = error.errors.map(err => ({
          field: err.path.join('.'),
          message: err.message
        }));
        throw new Error(`Form doğrulama hatası: ${formattedErrors.map(e => e.message).join(', ')}`);
      }
      throw error;
    }
  }, []);

  const validateIncubationForm = useCallback((data: unknown) => {
    try {
      return incubationFormSchema.parse(data);
    } catch (error) {
      if (error instanceof z.ZodError) {
        const formattedErrors = error.errors.map(err => ({
          field: err.path.join('.'),
          message: err.message
        }));
        throw new Error(`Form doğrulama hatası: ${formattedErrors.map(e => e.message).join(', ')}`);
      }
      throw error;
    }
  }, []);

  const validateEggForm = useCallback((data: unknown) => {
    try {
      return eggFormSchema.parse(data);
    } catch (error) {
      if (error instanceof z.ZodError) {
        const formattedErrors = error.errors.map(err => ({
          field: err.path.join('.'),
          message: err.message
        }));
        throw new Error(`Form doğrulama hatası: ${formattedErrors.map(e => e.message).join(', ')}`);
      }
      throw error;
    }
  }, []);

  const validateChickForm = useCallback((data: unknown) => {
    try {
      return chickFormSchema.parse(data);
    } catch (error) {
      if (error instanceof z.ZodError) {
        const formattedErrors = error.errors.map(err => ({
          field: err.path.join('.'),
          message: err.message
        }));
        throw new Error(`Form doğrulama hatası: ${formattedErrors.map(e => e.message).join(', ')}`);
      }
      throw error;
    }
  }, []);

  // Yeni: Bildirim formu doğrulama
  const validateNotificationForm = useCallback((data: unknown) => {
    try {
      return notificationFormSchema.parse(data);
    } catch (error) {
      if (error instanceof z.ZodError) {
        const formattedErrors = error.errors.map(err => ({
          field: err.path.join('.'),
          message: err.message
        }));
        throw new Error(`Bildirim formu hatası: ${formattedErrors.map(e => e.message).join(', ')}`);
      }
      throw error;
    }
  }, []);

  // Yeni: Etkinlik formu doğrulama
  const validateEventForm = useCallback((data: unknown) => {
    try {
      return eventFormSchema.parse(data);
    } catch (error) {
      if (error instanceof z.ZodError) {
        const formattedErrors = error.errors.map(err => ({
          field: err.path.join('.'),
          message: err.message
        }));
        throw new Error(`Etkinlik formu hatası: ${formattedErrors.map(e => e.message).join(', ')}`);
      }
      throw error;
    }
  }, []);

  // Yeni: Veteriner randevu formu doğrulama
  const validateVeterinaryAppointment = useCallback((data: unknown) => {
    try {
      return veterinaryAppointmentSchema.parse(data);
    } catch (error) {
      if (error instanceof z.ZodError) {
        const formattedErrors = error.errors.map(err => ({
          field: err.path.join('.'),
          message: err.message
        }));
        throw new Error(`Randevu formu hatası: ${formattedErrors.map(e => e.message).join(', ')}`);
      }
      throw error;
    }
  }, []);

  // Yeni: Genel tarih doğrulama
  const validateDate = useCallback((date: Date, fieldName: string = 'Tarih'): string | null => {
    return validateDateNotFuture(date, fieldName);
  }, []);

  // Yeni: Genel tarih ve saat doğrulama
  const validateDateTimeField = useCallback((date: Date, time?: string, fieldName: string = 'Tarih'): string | null => {
    return validateDateTimeNotFuture(date, time, fieldName);
  }, []);

  return {
    validateBirdForm,
    validateIncubationForm,
    validateEggForm,
    validateChickForm,
    validateNotificationForm,
    validateEventForm,
    validateVeterinaryAppointment,
    validateDate,
    validateDateTimeField,
    schemas: {
      birdFormSchema,
      incubationFormSchema,
      eggFormSchema,
      chickFormSchema,
      notificationFormSchema,
      eventFormSchema,
      veterinaryAppointmentSchema
    }
  };
};
