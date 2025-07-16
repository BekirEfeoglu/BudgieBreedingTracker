import { z } from 'zod';
import { useCallback } from 'react';

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
    .max(new Date(), 'Doğum tarihi gelecekte olamaz')
    .optional()
    .nullable(),
  
  ringNumber: z.string()
    .max(20, 'Halka numarası en fazla 20 karakter olabilir')
    .regex(/^[a-zA-Z0-9-]*$/, 'Halka numarası sadece harf, rakam ve tire içerebilir')
    .refine((val) => {
      if (!val || val.trim() === '') return true; // Allow empty values
      return val.trim().length >= 2; // If provided, must be at least 2 characters
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
    .min(2, 'Kuluçka adı en az 2 karakter olmalıdır')
    .max(50, 'Kuluçka adı en fazla 50 karakter olabilir'),
  
  motherId: z.string()
    .min(1, 'Anne kuş seçimi zorunludur'),
  
  fatherId: z.string()
    .min(1, 'Baba kuş seçimi zorunludur'),
  
  startDate: z.date({
    required_error: 'Başlangıç tarihi zorunludur'
  })
    .max(new Date(), 'Başlangıç tarihi gelecekte olamaz'),
  
  enableNotifications: z.boolean(),
  
  notes: z.string()
    .max(500, 'Notlar en fazla 500 karakter olabilir')
    .optional()
});

// Yumurta formu için validation schema - EggFormData ile tam uyumlu
export const eggFormSchema = z.object({
  id: z.string().optional(), // Optional for new eggs, required for editing
  clutchId: z.string()
    .min(1, 'Kuluçka seçimi zorunludur'),
  
  eggNumber: z.number()
    .min(1, 'Yumurta numarası 1 veya daha büyük olmalıdır')
    .max(20, 'Yumurta numarası 20\'den büyük olamaz'),
  
  startDate: z.date({
    required_error: 'Başlangıç tarihi zorunludur'
  })
    .refine((date) => {
      const today = new Date();
      today.setHours(23, 59, 59, 999); // Set to end of today
      return date <= today;
    }, 'Başlangıç tarihi gelecekte olamaz'),
  
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
    .max(new Date(), 'Çıkış tarihi gelecekte olamaz'),
  
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
      if (!val || val.trim() === '') return true; // Allow empty values
      return val.trim().length >= 2; // If provided, must be at least 2 characters
    }, 'Halka numarası en az 2 karakter olmalıdır')
    .optional(),
  
  healthNotes: z.string()
    .max(500, 'Sağlık notları en fazla 500 karakter olabilir')
    .optional()
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

  return {
    validateBirdForm,
    validateIncubationForm,
    validateEggForm,
    validateChickForm,
    schemas: {
      birdFormSchema,
      incubationFormSchema,
      eggFormSchema,
      chickFormSchema
    }
  };
};
