import React, { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Calendar } from '@/components/ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { Switch } from '@/components/ui/switch';
import { Textarea } from '@/components/ui/textarea';
import { CalendarIcon, Plus, X, AlertTriangle } from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';
import { cn } from '@/lib/utils';
import { format } from 'date-fns';
import { tr } from 'date-fns/locale';
import { incubationFormSchema } from '@/hooks/useFormValidation';
import { toast } from '@/hooks/use-toast';

type BreedingFormData = z.infer<typeof incubationFormSchema>;

interface Bird {
  id: string;
  name: string;
  gender: 'male' | 'female' | 'unknown';
}

interface BreedingFormProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (data: BreedingFormData) => void;
  existingBirds: Bird[];
  existingBreeding: Array<{ nestName: string }>;
  editingBreeding?: any;
}

const BreedingForm = ({ 
  isOpen, 
  onClose, 
  onSave, 
  existingBirds, 
  existingBreeding, 
  editingBreeding 
}: BreedingFormProps) => {
  const { t } = useLanguage();
  const [isCalendarOpen, setIsCalendarOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  console.log('🔄 BreedingForm - Component render:', {
    isOpen,
    editingBreeding: editingBreeding?.id,
    existingBirdsCount: existingBirds?.length,
    existingBreedingCount: existingBreeding?.length
  });

  const form = useForm<BreedingFormData>({
    resolver: zodResolver(incubationFormSchema),
    defaultValues: {
      incubationName: editingBreeding?.nestName || '',
      motherId: editingBreeding?.femaleBirdId || '',
      fatherId: editingBreeding?.maleBirdId || '',
      startDate: editingBreeding?.startDate ? new Date(editingBreeding.startDate) : new Date(),
      enableNotifications: editingBreeding?.enableNotifications ?? true,
      notes: editingBreeding?.notes || ''
    }
  });

  const nestNameSuggestions = [
    'Yuva 1', 'Yuva 2', 'Yuva 3', 'Yuva 4', 'Yuva 5',
    'Ana Yuva', 'Yan Yuva', 'Üst Yuva', 'Alt Yuva',
    'Kuluçka 1', 'Kuluçka 2', 'Kuluçka 3'
  ];

  const generateNestName = () => {
    console.log('🎲 generateNestName - Yuva adı önerisi oluşturuluyor');
    const usedNames = existingBreeding.map(b => b.nestName).filter(Boolean);
    const availableNames = nestNameSuggestions.filter(name => !usedNames.includes(name));
    
    if (availableNames.length > 0) {
      const randomName = availableNames[Math.floor(Math.random() * availableNames.length)];
      console.log('✅ generateNestName - Önerilen yuva adı:', randomName);
      form.setValue('incubationName', randomName);
    } else {
      const nextNumber = existingBreeding.length + 1;
      const generatedName = `Yuva ${nextNumber}`;
      console.log('✅ generateNestName - Oluşturulan yuva adı:', generatedName);
      form.setValue('incubationName', generatedName);
    }
  };

  const onSubmit = async (data: BreedingFormData) => {
    console.log('💾 BreedingForm.onSubmit - Form gönderimi başlıyor:', {
      data,
      editingBreeding: editingBreeding?.id
    });

    if (data.startDate && data.startDate > new Date()) {
      console.error('❌ BreedingForm.onSubmit - Gelecek tarih hatası');
      toast({
        title: 'Hata',
        description: 'Başlangıç tarihi gelecekte olamaz',
        variant: 'destructive'
      });
      return;
    }

    setIsSubmitting(true);
    try {
      console.log('📤 BreedingForm.onSubmit - onSave çağrılıyor');
      await onSave(data);
      
      if (editingBreeding) {
        console.log('✅ BreedingForm.onSubmit - Kuluçka güncellendi');
        toast({
          title: 'Başarılı',
          description: 'Kuluçka başarıyla güncellendi'
        });
      } else {
        console.log('✅ BreedingForm.onSubmit - Kuluçka eklendi');
        toast({
          title: 'Başarılı',
          description: 'Kuluçka başarıyla eklendi'
        });
      }
      
      handleClose();
    } catch (error) {
      console.error('💥 BreedingForm.onSubmit - Beklenmedik hata:', error);
      toast({
        title: 'Hata',
        description: 'Kuluçka kaydedilirken bir hata oluştu',
        variant: 'destructive'
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleClose = () => {
    console.log('❌ BreedingForm.handleClose - Form kapatılıyor');
    form.reset();
    onClose();
  };

  const femaleBirds = existingBirds.filter(bird => bird.gender === 'female');
  const maleBirds = existingBirds.filter(bird => bird.gender === 'male');

  const selectedFemale = form.watch('motherId');
  const selectedMale = form.watch('fatherId');

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <Card className="w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <CardHeader className="flex flex-col sm:flex-row items-center justify-between space-y-2 sm:space-y-0">
          <div className="flex-1">
            <CardTitle className="text-xl font-bold text-center flex items-center justify-between">
              {editingBreeding ? 'Kuluçkayı Düzenle' : 'Yeni Kuluçka Ekle'}
              <Button variant="ghost" size="icon" onClick={handleClose}>
                <X className="w-4 h-4" />
              </Button>
            </CardTitle>
            <CardDescription>
              Kuluçka bilgilerini girin ve yumurtaları ekleyin.
            </CardDescription>
          </div>
        </CardHeader>
        <CardContent>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
            
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <Label className="flex items-center justify-between">
                  Yuva/Kuluçka Adı *
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    onClick={generateNestName}
                  >
                    Öneri Al
                  </Button>
                </Label>
                <Input 
                  {...form.register('incubationName')}
                  placeholder="Yuva adını girin"
                  className={cn(form.formState.errors.incubationName && 'border-destructive')}
                />
                {form.formState.errors.incubationName && (
                  <p className="text-sm text-destructive mt-1">{form.formState.errors.incubationName.message}</p>
                )}
              </div>

              <div>
                <Label>Dişi Kuş *</Label>
                <Select 
                  value={form.watch('motherId')} 
                  onValueChange={(value) => {
                    if (value) {
                      form.setValue('motherId', value);
                      if (value === selectedMale) {
                        form.setValue('fatherId', '');
                      }
                    }
                  }}
                >
                  <SelectTrigger className={cn(form.formState.errors.motherId && 'border-destructive')}>
                    <SelectValue placeholder="Dişi kuş seçin" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="">Dişi kuş seçin</SelectItem>
                    {femaleBirds.map((bird) => (
                      <SelectItem key={bird.id} value={bird.id}>
                        {bird.name} ♀️
                      </SelectItem>
                    ))}
                    {femaleBirds.length === 0 && (
                      <SelectItem value="no-females" disabled>
                        Dişi kuş bulunamadı
                      </SelectItem>
                    )}
                  </SelectContent>
                </Select>
                {form.formState.errors.motherId && (
                  <p className="text-sm text-destructive mt-1">{form.formState.errors.motherId.message}</p>
                )}
              </div>

              <div>
                <Label>Erkek Kuş *</Label>
                <Select 
                  value={form.watch('fatherId')} 
                  onValueChange={(value) => {
                    form.setValue('fatherId', value);
                    if (value === selectedFemale) {
                      form.setValue('motherId', '');
                    }
                  }}
                >
                  <SelectTrigger className={cn(form.formState.errors.fatherId && 'border-destructive')}>
                    <SelectValue placeholder="Erkek kuş seçin" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="">Erkek kuş seçin</SelectItem>
                    {maleBirds.map((bird) => (
                      <SelectItem key={bird.id} value={bird.id}>
                        {bird.name} ♂️
                      </SelectItem>
                    ))}
                    {maleBirds.length === 0 && (
                      <SelectItem value="no-males" disabled>
                        Erkek kuş bulunamadı
                      </SelectItem>
                    )}
                  </SelectContent>
                </Select>
                {form.formState.errors.fatherId && (
                  <p className="text-sm text-destructive mt-1">{form.formState.errors.fatherId.message}</p>
                )}
              </div>

              <div>
                <Label>Başlangıç Tarihi *</Label>
                <Popover open={isCalendarOpen} onOpenChange={setIsCalendarOpen}>
                  <PopoverTrigger asChild>
                    <Button
                      variant="outline"
                      className={cn(
                        "w-full pl-3 text-left font-normal",
                        !form.watch('startDate') && "text-muted-foreground"
                      )}
                    >
                      {form.watch('startDate') ? (
                        format(form.watch('startDate'), "dd/MM/yyyy", { locale: tr })
                      ) : (
                        <span>Tarih seçin</span>
                      )}
                      <CalendarIcon className="ml-auto h-4 w-4 opacity-50" />
                    </Button>
                  </PopoverTrigger>
                  <PopoverContent className="w-auto p-0" align="start">
                    <Calendar
                      mode="single"
                      selected={form.watch('startDate')}
                      onSelect={(date) => {
                        if (date) {
                          form.setValue('startDate', date);
                        }
                      }}
                      disabled={(date) => date > new Date()}
                      initialFocus
                      locale={tr}
                    />
                  </PopoverContent>
                </Popover>
                {form.formState.errors.startDate && (
                  <p className="text-sm text-destructive mt-1">{form.formState.errors.startDate.message}</p>
                )}
              </div>

              <div className="flex items-center space-x-2">
                <Switch
                  id="enableNotifications"
                  checked={form.watch('enableNotifications')}
                  onCheckedChange={(checked) => form.setValue('enableNotifications', checked)}
                />
                <Label htmlFor="enableNotifications" className="text-sm">Bildirimleri Aktif Et</Label>
              </div>
            </div>

            <div>
              <Label>Notlar</Label>
              <Textarea 
                {...form.register('notes')}
                placeholder="Ek bilgiler, gözlemler vb."
                rows={3}
                className={cn(form.formState.errors.notes && 'border-destructive')}
              />
              {form.formState.errors.notes && (
                <p className="text-sm text-destructive mt-1">{form.formState.errors.notes.message}</p>
              )}
            </div>

            <div className="flex space-x-2 pt-4 safe-area-bottom">
              <Button
                type="button"
                variant="outline"
                onClick={handleClose}
                className="flex-1 touch-button"
              >
                Vazgeç
              </Button>
              <Button
                type="submit"
                className="flex-1 budgie-button touch-button"
                disabled={!form.formState.isValid || isSubmitting}
              >
                {editingBreeding ? 'Güncelle' : 'Kaydet'}
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
};

export default BreedingForm;
