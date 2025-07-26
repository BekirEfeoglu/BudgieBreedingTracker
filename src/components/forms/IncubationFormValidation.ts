
import { z } from 'zod';

export const createIncubationFormSchema = () => {
  return z.object({
    incubationName: z.string()
      .min(1, 'Kuluçka adı zorunludur')
      .max(50, 'Kuluçka adı en fazla 50 karakter olabilir')
      .refine(val => val.trim().length > 0, 'Kuluçka adı gereklidir'),
    motherId: z.string().min(1, 'Anne seçimi zorunludur'),
    fatherId: z.string().min(1, 'Baba seçimi zorunludur'),
    startDate: z.date({
      required_error: 'Başlangıç tarihi gereklidir'
    }).refine(date => date <= new Date(), 'Gelecek tarih seçilemez'),
    enableNotifications: z.boolean(),
    notes: z.string().max(500, 'Notlar en fazla 500 karakter olabilir').optional().or(z.literal(''))
  });
};

export type IncubationFormData = z.infer<ReturnType<typeof createIncubationFormSchema>>;
