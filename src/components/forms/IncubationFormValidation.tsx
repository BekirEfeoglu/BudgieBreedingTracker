import { z } from 'zod';

export interface IncubationFormData {
  incubationName: string;
  motherId: string;
  fatherId: string;
  startDate: Date;
  enableNotifications: boolean;
  notes?: string;
}

export const createIncubationFormSchema = () => {
  return z.object({
    incubationName: z.string()
      .min(1, 'Zorunlu alan')
      .min(3, 'En az 3 karakter')
      .max(100, 'En fazla 100 karakter'),
    motherId: z.string()
      .min(1, 'Anne zorunlu'),
    fatherId: z.string()
      .min(1, 'Baba zorunlu'),
    startDate: z.date({
      required_error: 'Başlangıç tarihi zorunlu',
      invalid_type_error: 'Geçersiz tarih',
    }),
    enableNotifications: z.boolean().default(true),
    notes: z.string().optional(),
  }).refine((data) => data.motherId !== data.fatherId, {
    message: 'Anne ve baba farklı olmalı',
    path: ['fatherId'],
  });
};

export type IncubationFormSchema = ReturnType<typeof createIncubationFormSchema>; 