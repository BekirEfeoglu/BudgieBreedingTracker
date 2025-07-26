import React, { useState, useEffect, memo } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { Calendar } from '@/components/ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from '@/components/ui/form';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog';
import { Calendar as CalendarIcon, X } from 'lucide-react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { format } from 'date-fns';
import { cn } from '@/lib/utils';
import { toast } from '@/hooks/use-toast';
import { useLanguage } from '@/contexts/LanguageContext';
import PhotoUpload from '@/components/forms/PhotoUpload';
import ParentSelection from '@/components/forms/ParentSelection';
import { Bird, Chick } from '@/types';

const ChickForm = memo(({ isOpen, onClose, onSave, birds, editingChick }: {
  isOpen: boolean;
  onClose: () => void;
  onSave: (data: any) => void;
  birds: Bird[];
  editingChick: Chick | null;
}) => {
  const { t } = useLanguage();
  const [selectedPhoto, setSelectedPhoto] = useState<string | null>(null);
  const isEditing = !!editingChick;

  // Dynamic schema based on translations
  const chickFormSchema = z.object({
    name: z.string().min(1, t('chicks.nameRequired')),
    gender: z.enum(['female', 'male', 'unknown'], {
      required_error: t('chicks.genderRequired')
    }),
    color: z.string().optional(),
    birthDate: z.date({
      required_error: t('chicks.birthDateRequired')
    }),
    ringNumber: z.string().optional(),
    motherId: z.string().optional(),
    fatherId: z.string().optional(),
    healthNotes: z.string().optional(),
    photo: z.string().optional()
  });

  type ChickFormData = z.infer<typeof chickFormSchema>;

  const form = useForm<ChickFormData>({
    resolver: zodResolver(chickFormSchema),
    defaultValues: {
      name: '',
      gender: 'unknown',
      color: '',
      birthDate: new Date(),
      ringNumber: '',
      motherId: undefined,
      fatherId: undefined,
      healthNotes: '',
      photo: ''
    }
  });

  // Form verilerini doldur
  useEffect(() => {
    if (isEditing && editingChick && isOpen) {
      form.reset({
        name: editingChick.name || '',
        gender: editingChick.gender || 'unknown',
        color: editingChick.color || '',
        birthDate: editingChick.hatchDate ? new Date(editingChick.hatchDate) : new Date(),
        ringNumber: editingChick.ringNumber || '',
        motherId: editingChick.motherId || undefined,
        fatherId: editingChick.fatherId || undefined,
        healthNotes: editingChick.healthNotes || '',
        photo: editingChick.photo || ''
      });
      setSelectedPhoto(editingChick.photo || null);
    } else if (!isEditing && isOpen) {
      form.reset({
        name: '',
        gender: 'unknown',
        color: '',
        birthDate: new Date(),
        ringNumber: '',
        motherId: undefined,
        fatherId: undefined,
        healthNotes: '',
        photo: ''
      });
      setSelectedPhoto(null);
    }
  }, [editingChick, isEditing, isOpen, form]);

  const handlePhotoSelect = (photo: string) => {
    setSelectedPhoto(photo);
    form.setValue('photo', photo);
  };

  const handleNameChange = (value: string) => {
    const upperValue = value.toUpperCase();
    form.setValue('name', upperValue);
  };

  const onSubmit = (data: ChickFormData) => {
    if (data.birthDate && data.birthDate > new Date()) {
      toast({
        title: t('chicks.error'),
        description: t('chicks.futureDateError'),
        variant: 'destructive'
      });
      return;
    }

    console.log('🔄 ChickForm.onSubmit - Form verisi gönderiliyor:', data);

    if (isEditing && editingChick) {
      onSave({
        ...data,
        id: editingChick.id
      });
    } else {
      onSave(data);
    }
    handleClose();
  };

  const handleClose = () => {
    form.reset();
    setSelectedPhoto(null);
    onClose();
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Escape') {
      handleClose();
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent
        aria-describedby="chick-form-description"
        className="max-w-md mx-auto max-h-[90vh] overflow-y-auto"
        onKeyDown={handleKeyDown}
        aria-label={isEditing ? t('chicks.editChickTitle') : t('chicks.newChick')}
      >
        <DialogHeader>
          <DialogTitle className="text-xl font-bold text-center flex items-center justify-between">
            {isEditing ? t('chicks.editChickTitle') : t('chicks.newChick')}
            <Button variant="ghost" size="icon" onClick={handleClose} aria-label={t('common.close')}>
              <X className="w-4 h-4" aria-hidden="true" />
            </Button>
          </DialogTitle>
          <DialogDescription>
            {isEditing ? t('chicks.editChickDescription') : t('chicks.newChickDescription')}
          </DialogDescription>
          <div id="chick-form-description" className="sr-only">
            Yavru ekleme/düzenleme formu
          </div>
        </DialogHeader>
        
        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
            <PhotoUpload 
              selectedPhoto={selectedPhoto} 
              onPhotoSelect={handlePhotoSelect} 
            />

            {/* İsim */}
            <FormField
              control={form.control}
              name="name"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>{t('chicks.name')} *</FormLabel>
                  <FormControl>
                    <Input 
                      {...field} 
                      placeholder={t('chicks.namePlaceholder')} 
                      onChange={(e) => {
                        handleNameChange(e.target.value);
                      }}
                      aria-label={t('chicks.name')}
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            {/* Cinsiyet */}
            <FormField
              control={form.control}
              name="gender"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>{t('chicks.gender')} *</FormLabel>
                  <FormControl>
                    <RadioGroup 
                      value={field.value} 
                      onValueChange={field.onChange}
                      className="flex space-x-4"
                      aria-label={t('chicks.selectGender')}
                    >
                      <div className="flex items-center space-x-2">
                        <RadioGroupItem value="female" id="female" />
                        <Label htmlFor="female">{t('chicks.femaleLabel')}</Label>
                      </div>
                      <div className="flex items-center space-x-2">
                        <RadioGroupItem value="male" id="male" />
                        <Label htmlFor="male">{t('chicks.maleLabel')}</Label>
                      </div>
                      <div className="flex items-center space-x-2">
                        <RadioGroupItem value="unknown" id="unknown" />
                        <Label htmlFor="unknown">{t('chicks.unknownLabel')}</Label>
                      </div>
                    </RadioGroup>
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            {/* Renk */}
            <FormField
              control={form.control}
              name="color"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>{t('chicks.color')}</FormLabel>
                  <FormControl>
                    <Input 
                      {...field} 
                      placeholder="Renk girin" 
                      aria-label={t('chicks.color')}
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            {/* Doğum Tarihi */}
            <FormField
              control={form.control}
              name="birthDate"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>{t('chicks.birthDate')} *</FormLabel>
                  <FormControl>
                    <Popover>
                      <PopoverTrigger asChild>
                        <Button
                          variant="outline"
                          className={cn(
                            "w-full justify-start text-left font-normal",
                            !field.value && "text-muted-foreground"
                          )}
                          aria-label={t('chicks.birthDate')}
                        >
                          <CalendarIcon className="mr-2 h-4 w-4" aria-hidden="true" />
                          {field.value ? format(field.value, "PPP") : t('common.selectDate')}
                        </Button>
                      </PopoverTrigger>
                      <PopoverContent className="w-auto p-0">
                        <Calendar
                          mode="single"
                          selected={field.value}
                          onSelect={field.onChange}
                          disabled={(date) => date > new Date() || date < new Date("1900-01-01")}
                          initialFocus
                        />
                      </PopoverContent>
                    </Popover>
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            {/* Halka Numarası */}
            <FormField
              control={form.control}
              name="ringNumber"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>{t('chicks.ringNumber')}</FormLabel>
                  <FormControl>
                    <Input 
                      {...field} 
                      placeholder="Halka numarası girin" 
                      aria-label={t('chicks.ringNumber')}
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            {/* Ebeveyn Seçimi */}
            <ParentSelection
              control={form.control}
              existingBirds={birds}
            />

            {/* Sağlık Notları */}
            <FormField
              control={form.control}
              name="healthNotes"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>{t('chicks.healthNotes')}</FormLabel>
                  <FormControl>
                    <Textarea 
                      {...field} 
                      placeholder="Sağlık notları girin" 
                      className="resize-none"
                      rows={3}
                      aria-label={t('chicks.healthNotes')}
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            {/* Butonlar */}
            <div className="flex gap-2 pt-4">
              <Button 
                type="button" 
                variant="outline" 
                onClick={handleClose}
                className="flex-1"
              >
                {t('chicks.cancel')}
              </Button>
              <Button 
                type="submit" 
                className="flex-1"
                disabled={form.formState.isSubmitting}
              >
                {form.formState.isSubmitting ? t('chicks.saving') : t('chicks.save')}
              </Button>
            </div>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  );
});

ChickForm.displayName = 'ChickForm';

export default ChickForm;
