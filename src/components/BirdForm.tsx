import { useState, useEffect } from 'react';
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
import { format } from 'date-fns';
import { cn } from '@/lib/utils';
import { toast } from '@/hooks/use-toast';
import { useFormValidation } from '@/hooks/useFormValidation';
import PhotoUpload from '@/components/forms/PhotoUpload';
import NameField from '@/components/forms/NameField';
import ParentSelection from '@/components/forms/ParentSelection';
import { useLanguage } from '@/contexts/LanguageContext';
import { Bird } from '@/types';

interface BirdFormProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (data: Partial<Bird> & { birthDate?: Date }) => void;
  existingBirds: Array<{ id: string; name: string; gender: 'male' | 'female' | 'unknown'; ringNumber?: string }>;
  editingBird?: Bird | null;
}

const BirdForm = ({ isOpen, onClose, onSave, existingBirds, editingBird }: BirdFormProps) => {
  const [selectedPhoto, setSelectedPhoto] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [lastSubmitTime, setLastSubmitTime] = useState(0);
  const isEditing = !!editingBird;
  const { validateBirdForm, schemas } = useFormValidation();
  const { t } = useLanguage();

  const form = useForm({
    resolver: zodResolver(schemas.birdFormSchema),
    defaultValues: {
      name: '',
      gender: '',
      color: '',
      birthDate: undefined,
      ringNumber: '',
      motherId: '',
      fatherId: '',
      healthNotes: '',
      photo: ''
    }
  });

  // Düzenleme modunda form verilerini doldur
  useEffect(() => {
    if (isEditing && editingBird) {
      form.reset({
        name: editingBird.name || '',
        gender: editingBird.gender || '',
        color: editingBird.color || '',
        birthDate: editingBird.birthDate ? new Date(editingBird.birthDate) : undefined,
        ringNumber: editingBird.ringNumber || '',
        motherId: editingBird.motherId || '',
        fatherId: editingBird.fatherId || '',
        healthNotes: editingBird.healthNotes || '',
        photo: editingBird.photo || ''
      });
      setSelectedPhoto(editingBird.photo || null);
    } else {
      form.reset({
        name: '',
        gender: '',
        color: '',
        birthDate: undefined,
        ringNumber: '',
        motherId: '',
        fatherId: '',
        healthNotes: '',
        photo: ''
      });
      setSelectedPhoto(null);
    }
  }, [isEditing, editingBird, form]);

  const handlePhotoSelect = (photo: string) => {
    setSelectedPhoto(photo);
    form.setValue('photo', photo);
  };

  const handleNameChange = (value: string) => {
    const upperValue = value.toUpperCase();
    form.setValue('name', upperValue);
  };

  const onSubmit = async (data: any) => {
    const now = Date.now();
    if (isSubmitting || (now - lastSubmitTime) < 3000) {
      console.log('🔄 Form submission blocked - already in progress or too recent');
      return;
    }
    setLastSubmitTime(now);
    setIsSubmitting(true);
    
    try {
      // Reduced logging for performance
      
      // Form validation
      const validatedData = validateBirdForm(data);
      // Reduced logging for performance
      
      // Halka numarası tekrarlılık kontrolü
      if (validatedData.ringNumber && validatedData.ringNumber.trim()) {
        const existingBird = existingBirds.find(bird => 
          bird.ringNumber === validatedData.ringNumber && 
          bird.id !== editingBird?.id
        );
        
        if (existingBird) {
          toast({
            title: 'Halka Numarası Hatası',
            description: `Bu halka numarası "${existingBird.name}" adlı kuşta zaten kullanılıyor.`,
            variant: 'destructive'
          });
          return;
        }
      }

      // İsim tekrarlılık kontrolü (aynı isim ve cinsiyet)
      const existingBirdWithSameName = existingBirds.find(bird => 
        bird.name.toLowerCase() === validatedData.name.toLowerCase() && 
        bird.gender === validatedData.gender &&
        bird.id !== editingBird?.id
      );
      
      if (existingBirdWithSameName) {
        toast({
          title: 'İsim Hatası',
          description: `"${validatedData.name}" adlı ${validatedData.gender === 'female' ? 'dişi' : validatedData.gender === 'male' ? 'erkek' : 'bilinmeyen cinsiyetli'} kuş zaten mevcut.`,
          variant: 'destructive'
        });
        return;
      }

      // Tarih kontrolleri
      if (validatedData.birthDate && validatedData.birthDate > new Date()) {
        toast({
          title: 'Tarih Hatası',
          description: 'Doğum tarihi gelecekte olamaz.',
          variant: 'destructive'
        });
        return;
      }

      // Veriyi onSave fonksiyonuna uygun formata dönüştür
      const transformedData = {
        name: validatedData.name,
        gender: validatedData.gender,
        color: validatedData.color || '',
        birthDate: validatedData.birthDate,
        ringNumber: validatedData.ringNumber || '',
        motherId: validatedData.motherId || '',
        fatherId: validatedData.fatherId || '',
        healthNotes: validatedData.healthNotes || '',
        photo: validatedData.photo || ''
      };

      // Reduced logging for performance
      
      await onSave(transformedData);
      
      onClose();
    } catch (error) {
      console.error('Form gönderim hatası:', error);
      
      if (error instanceof Error) {
        if (error.message.includes('Form doğrulama hatası')) {
          toast({
            title: 'Form Hatası',
            description: error.message.replace('Form doğrulama hatası: ', ''),
            variant: 'destructive'
          });
        } else {
          toast({
            title: 'Form Hatası',
            description: error.message,
            variant: 'destructive'
          });
        }
      } else {
        toast({
          title: 'Form Hatası',
          description: 'Form gönderilirken bir hata oluştu.',
          variant: 'destructive'
        });
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleClose = () => {
    if (isSubmitting) return;
    form.reset();
    setSelectedPhoto(null);
    onClose();
  };

  return (
    <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent 
        aria-describedby="bird-form-description"
        className="mobile-modal-large max-w-[95vw] mx-auto max-h-[95vh] overflow-y-auto"
      >
        <DialogHeader>
          <DialogTitle className="text-xl font-bold text-center flex items-center justify-between">
            {isEditing ? 'Kuşu Düzenle' : 'Yeni Kuş Ekle'}
            <Button 
              variant="ghost" 
              size="icon" 
              onClick={handleClose}
              disabled={isSubmitting}
              className="touch-target"
            >
              <X className="w-4 h-4" />
            </Button>
          </DialogTitle>
          <DialogDescription>
            Kuş ekleme veya düzenleme işlemi için formu doldurun.
          </DialogDescription>
          <div id="bird-form-description" className="sr-only">
            Kuş ekleme/düzenleme formu
          </div>
        </DialogHeader>
        
        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
            <PhotoUpload 
              selectedPhoto={selectedPhoto} 
              onPhotoSelect={handlePhotoSelect} 
            />

            <NameField 
              control={form.control}
              onRandomName={() => {}}
              onNameChange={handleNameChange}
              gender={form.watch('gender') as 'male' | 'female' | 'unknown'}
            />

            {/* Cinsiyet */}
            <FormField
              control={form.control}
              name="gender"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Cinsiyet *</FormLabel>
                  <FormControl>
                    <RadioGroup 
                      value={field.value} 
                      onValueChange={field.onChange}
                      className="flex flex-col sm:flex-row space-y-2 sm:space-y-0 sm:space-x-4"
                    >
                      <div className="flex items-center space-x-2 touch-target">
                        <RadioGroupItem value="female" id="female" />
                        <Label htmlFor="female">Dişi ♀️</Label>
                      </div>
                      <div className="flex items-center space-x-2 touch-target">
                        <RadioGroupItem value="male" id="male" />
                        <Label htmlFor="male">Erkek ♂️</Label>
                      </div>
                      <div className="flex items-center space-x-2 touch-target">
                        <RadioGroupItem value="unknown" id="unknown" />
                        <Label htmlFor="unknown">{t('birds.unknown')}</Label>
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
                  <FormLabel>Renk</FormLabel>
                  <FormControl>
                    <Input 
                      {...field} 
                      placeholder="örn: sarı, gök mavisi, yeşil-beyaz"
                      maxLength={100}
                      className="mobile-form-input"
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
                  <FormLabel>Doğum Tarihi</FormLabel>
                  <div className="space-y-3">
                    {/* Hızlı Seçim Butonları */}
                    <div className="grid grid-cols-3 gap-3">
                      <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        className="text-xs mobile-form-button"
                        onClick={() => {
                          const sixMonthsAgo = new Date();
                          sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
                          if (sixMonthsAgo <= new Date()) {
                            field.onChange(sixMonthsAgo);
                          }
                        }}
                      >
                        6 Ay
                      </Button>
                      <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        className="text-xs mobile-form-button"
                        onClick={() => {
                          const oneYearAgo = new Date();
                          oneYearAgo.setFullYear(oneYearAgo.getFullYear() - 1);
                          if (oneYearAgo <= new Date()) {
                            field.onChange(oneYearAgo);
                          }
                        }}
                      >
                        1 Yıl
                      </Button>
                      <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        className="text-xs mobile-form-button"
                        onClick={() => {
                          const twoYearsAgo = new Date();
                          twoYearsAgo.setFullYear(twoYearsAgo.getFullYear() - 2);
                          if (twoYearsAgo <= new Date()) {
                            field.onChange(twoYearsAgo);
                          }
                        }}
                      >
                        2 Yıl
                      </Button>
                    </div>
                    
                    {/* Ana Tarih Seçici */}
                    <Popover>
                      <PopoverTrigger asChild>
                        <FormControl>
                          <Button
                            variant="outline"
                            className={cn(
                              "w-full pl-3 text-left font-normal mobile-form-input",
                              !field.value && "text-muted-foreground"
                            )}
                          >
                            {field.value ? (
                              format(field.value, "dd/MM/yyyy")
                            ) : (
                              <span>Tarih seçin veya hızlı butonları kullanın</span>
                            )}
                            <CalendarIcon className="ml-auto h-4 w-4 opacity-50" />
                          </Button>
                        </FormControl>
                      </PopoverTrigger>
                      <PopoverContent className="w-auto p-0 mobile-modal" align="start">
                        <div className="p-3 space-y-3">
                          {/* Yıl Hızlı Seçim */}
                          <div className="flex gap-2 flex-wrap">
                            {[2024, 2023, 2022, 2021, 2020].map(year => (
                              <Button
                                key={year}
                                type="button"
                                variant="ghost"
                                size="sm"
                                className="text-xs h-8 px-3 touch-target"
                                onClick={() => {
                                  const yearDate = new Date();
                                  yearDate.setFullYear(year);
                                  if (yearDate <= new Date()) {
                                    field.onChange(yearDate);
                                  }
                                }}
                              >
                                {year}
                              </Button>
                            ))}
                          </div>
                          <Calendar
                            mode="single"
                            selected={field.value || undefined}
                            onSelect={field.onChange}
                            disabled={(date) => date > new Date() || false}
                            initialFocus
                            className="pointer-events-auto"
                            captionLayout="dropdown-buttons"
                            fromYear={2000}
                            toYear={new Date().getFullYear()}
                          />
                        </div>
                        {field.value && (
                          <div className="border-t p-2">
                            <Button
                              type="button"
                              variant="ghost"
                              size="sm"
                              className="w-full text-xs"
                              onClick={() => field.onChange(undefined)}
                            >
                              Tarihi Temizle
                            </Button>
                          </div>
                        )}
                      </PopoverContent>
                    </Popover>
                  </div>
                  <FormMessage />
                </FormItem>
              )}
            />

            {/* Bilezik Numarası */}
            <FormField
              control={form.control}
              name="ringNumber"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Bilezik Numarası</FormLabel>
                  <FormControl>
                    <Input 
                      {...field} 
                      placeholder="Bilezik numarasını girin"
                      maxLength={20}
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            <ParentSelection control={form.control} existingBirds={existingBirds} />

            {/* Sağlık Notları */}
            <FormField
              control={form.control}
              name="healthNotes"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Sağlık Notları</FormLabel>
                  <FormControl>
                    <Textarea 
                      {...field}
                      placeholder="Sağlık durumu, tedavi geçmişi, alerji vb."
                      rows={3}
                      maxLength={500}
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            {/* Butonlar */}
            <div className="flex space-x-2 pt-4">
              <Button
                type="button"
                variant="outline"
                onClick={handleClose}
                className="flex-1"
                disabled={isSubmitting}
              >
                Vazgeç
              </Button>
              <Button
                type="submit"
                className="flex-1 budgie-button"
                disabled={!form.formState.isValid || isSubmitting}
              >
                {isSubmitting ? 'Kaydediliyor...' : (isEditing ? 'Güncelle' : 'Kaydet')}
              </Button>
            </div>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  );
};

export default BirdForm;
