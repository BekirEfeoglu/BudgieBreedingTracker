import React, { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Form, FormField, FormItem, FormLabel, FormControl, FormMessage } from '@/components/ui/form';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Textarea } from '@/components/ui/textarea';
import { Switch } from '@/components/ui/switch';
import { Calendar } from '@/components/ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { CalendarIcon } from 'lucide-react';
import { format } from 'date-fns';
import { cn } from '@/lib/utils';
import { useToast } from '@/hooks/use-toast';
import { useErrorReporting } from '@/hooks/useErrorReporting';
import { incubationFormSchema } from '@/hooks/useFormValidation';
import { Bird, Breeding } from '@/types';

interface BreedingFormProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (data: Partial<Breeding>) => void;
  editingBreeding: Breeding | null;
  birds: Bird[];
}

type FormData = {
  incubationName: string;
  motherId: string;
  fatherId: string;
  startDate: Date;
  enableNotifications: boolean;
  notes?: string;
};

const BreedingForm = ({ isOpen, onClose, onSave, editingBreeding, birds }: BreedingFormProps) => {
  const { toast } = useToast();
  const { reportError } = useErrorReporting();
  const [isCalendarOpen, setIsCalendarOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const form = useForm<FormData>({
    resolver: zodResolver(incubationFormSchema),
    defaultValues: {
      incubationName: '',
      motherId: '',
      fatherId: '',
      startDate: new Date(),
      enableNotifications: true,
      notes: ''
    }
  });

  // Reset form when modal opens/closes or editingBreeding changes
  React.useEffect(() => {
    if (isOpen) {
      form.reset({
        incubationName: editingBreeding?.nestName || '',
        motherId: editingBreeding?.femaleBirdId || '',
        fatherId: editingBreeding?.maleBirdId || '',
        startDate: editingBreeding?.pairDate ? new Date(editingBreeding.pairDate) : new Date(),
        enableNotifications: true,
        notes: editingBreeding?.notes || ''
      });
    }
  }, [isOpen, editingBreeding, form]);

  // Filter birds by gender
  const maleBirds = birds.filter(bird => bird.gender === 'male');
  const femaleBirds = birds.filter(bird => bird.gender === 'female');

  const handleSubmit = async (data: FormData) => {
    try {
      setIsSubmitting(true);
      
      // Validate parent selection
      if (data.motherId === data.fatherId) {
        toast({
          title: 'Hata',
          description: 'Anne ve baba kuş aynı olamaz.',
          variant: 'destructive'
        });
        return;
      }

      // Validate date is not in the future
      const today = new Date();
      today.setHours(23, 59, 59, 999);
      if (data.startDate > today) {
        toast({
          title: 'Hata',
          description: 'Başlangıç tarihi gelecekte olamaz.',
          variant: 'destructive'
        });
        return;
      }

      // Transform data for backend
      const transformedData = {
        nestName: data.incubationName,
        maleBirdId: data.fatherId,
        femaleBirdId: data.motherId,
        pairDate: data.startDate.toISOString(),
        enableNotifications: data.enableNotifications,
        notes: data.notes || '',
        eggs: editingBreeding?.eggs || []
      };

      await onSave(transformedData);
      onClose();
      
      toast({
        title: 'Başarılı',
        description: editingBreeding ? 'Kuluçka güncellendi.' : 'Yeni kuluçka eklendi.',
      });
    } catch (error) {
      reportError(error as Error, 'BreedingForm.handleSubmit', {
        toastTitle: 'Kuluçka Kaydetme Hatası',
        toastDescription: 'Kuluçka kaydedilirken bir hata oluştu.'
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleClose = () => {
    if (!isSubmitting) {
      form.reset();
      onClose();
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-[500px]" aria-describedby="breeding-form-description">
        <DialogHeader>
          <DialogTitle>
            {editingBreeding ? 'Kuluçka Düzenle' : 'Yeni Kuluçka Ekle'}
          </DialogTitle>
          <DialogDescription>
            Kuluçka bilgilerini girin. Tüm zorunlu alanları doldurun.
          </DialogDescription>
        </DialogHeader>
        
        <Form {...form}>
          <form onSubmit={form.handleSubmit(handleSubmit)} className="space-y-4">
            <FormField
              control={form.control}
              name="incubationName"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Kuluçka Adı *</FormLabel>
                  <FormControl>
                    <Input
                      placeholder="Örn: Yuva 1"
                      {...field}
                      aria-describedby="name-help"
                    />
                  </FormControl>
                  <p id="name-help" className="text-xs text-muted-foreground">
                    2-50 karakter arası bir ad girin
                  </p>
                  <FormMessage />
                </FormItem>
              )}
            />

            <FormField
              control={form.control}
              name="motherId"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Anne Kuş *</FormLabel>
                  <Select onValueChange={field.onChange} defaultValue={field.value}>
                    <FormControl>
                      <SelectTrigger aria-describedby="mother-help">
                        <SelectValue placeholder="Anne kuş seçin" />
                      </SelectTrigger>
                    </FormControl>
                    <SelectContent>
                      {femaleBirds.length === 0 ? (
                        <SelectItem value="" disabled>
                          Dişi kuş bulunamadı
                        </SelectItem>
                      ) : (
                        femaleBirds.map((bird) => (
                          <SelectItem key={bird.id} value={bird.id}>
                            ♀ {bird.name} {bird.ringNumber && `(${bird.ringNumber})`}
                          </SelectItem>
                        ))
                      )}
                    </SelectContent>
                  </Select>
                  <p id="mother-help" className="text-xs text-muted-foreground">
                    Dişi kuş seçin
                  </p>
                  <FormMessage />
                </FormItem>
              )}
            />

            <FormField
              control={form.control}
              name="fatherId"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Baba Kuş *</FormLabel>
                  <Select onValueChange={field.onChange} defaultValue={field.value}>
                    <FormControl>
                      <SelectTrigger aria-describedby="father-help">
                        <SelectValue placeholder="Baba kuş seçin" />
                      </SelectTrigger>
                    </FormControl>
                    <SelectContent>
                      {maleBirds.length === 0 ? (
                        <SelectItem value="" disabled>
                          Erkek kuş bulunamadı
                        </SelectItem>
                      ) : (
                        maleBirds.map((bird) => (
                          <SelectItem key={bird.id} value={bird.id}>
                            ♂ {bird.name} {bird.ringNumber && `(${bird.ringNumber})`}
                          </SelectItem>
                        ))
                      )}
                    </SelectContent>
                  </Select>
                  <p id="father-help" className="text-xs text-muted-foreground">
                    Erkek kuş seçin
                  </p>
                  <FormMessage />
                </FormItem>
              )}
            />

            <FormField
              control={form.control}
              name="startDate"
              render={({ field }) => (
                <FormItem className="flex flex-col">
                  <FormLabel>Başlangıç Tarihi *</FormLabel>
                  <Popover open={isCalendarOpen} onOpenChange={setIsCalendarOpen}>
                    <PopoverTrigger asChild>
                      <FormControl>
                        <Button
                          variant="outline"
                          className={cn(
                            "w-full pl-3 text-left font-normal",
                            !field.value && "text-muted-foreground"
                          )}
                          aria-describedby="date-help"
                        >
                          {field.value ? (
                            format(field.value, "dd/MM/yyyy")
                          ) : (
                            <span>Tarih seçin</span>
                          )}
                          <CalendarIcon className="ml-auto h-4 w-4 opacity-50" />
                        </Button>
                      </FormControl>
                    </PopoverTrigger>
                    <PopoverContent className="w-auto p-0" align="start">
                      <Calendar
                        mode="single"
                        selected={field.value}
                        onSelect={(date) => {
                          field.onChange(date);
                          setIsCalendarOpen(false);
                        }}
                        disabled={(date) => {
                          const today = new Date();
                          today.setHours(23, 59, 59, 999);
                          return date > today || date < new Date("1900-01-01");
                        }}
                        initialFocus
                      />
                    </PopoverContent>
                  </Popover>
                  <p id="date-help" className="text-xs text-muted-foreground">
                    Kuluçka başlangıç tarihi
                  </p>
                  <FormMessage />
                </FormItem>
              )}
            />

            <FormField
              control={form.control}
              name="enableNotifications"
              render={({ field }) => (
                <FormItem className="flex flex-row items-center justify-between rounded-lg border p-3">
                  <div className="space-y-0.5">
                    <FormLabel className="text-base">
                      Bildirimler
                    </FormLabel>
                    <p className="text-sm text-muted-foreground">
                      Kuluçka hatırlatıcıları alın
                    </p>
                  </div>
                  <FormControl>
                    <Switch
                      checked={field.value}
                      onCheckedChange={field.onChange}
                      aria-describedby="notifications-help"
                    />
                  </FormControl>
                </FormItem>
              )}
            />

            <FormField
              control={form.control}
              name="notes"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Notlar</FormLabel>
                  <FormControl>
                    <Textarea
                      placeholder="Kuluçka hakkında notlar..."
                      className="resize-none"
                      {...field}
                      aria-describedby="notes-help"
                    />
                  </FormControl>
                  <p id="notes-help" className="text-xs text-muted-foreground">
                    En fazla 500 karakter
                  </p>
                  <FormMessage />
                </FormItem>
              )}
            />
            
            <div className="flex justify-end gap-2 pt-4">
              <Button 
                type="button" 
                variant="outline" 
                onClick={handleClose}
                disabled={isSubmitting}
              >
                İptal
              </Button>
              <Button 
                type="submit" 
                disabled={isSubmitting || maleBirds.length === 0 || femaleBirds.length === 0}
              >
                {isSubmitting ? 'Kaydediliyor...' : 'Kaydet'}
              </Button>
            </div>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  );
};

export default BreedingForm;
