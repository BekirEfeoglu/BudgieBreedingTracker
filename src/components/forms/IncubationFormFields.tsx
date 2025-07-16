import React from 'react';
import { Control } from 'react-hook-form';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Calendar } from '@/components/ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { Switch } from '@/components/ui/switch';
import { Textarea } from '@/components/ui/textarea';
import { CalendarIcon } from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';
import { cn } from '@/lib/utils';
import { format } from 'date-fns';
import { tr } from 'date-fns/locale';
import { FormField, FormItem, FormLabel, FormControl, FormDescription, FormMessage } from '@/components/ui/form';

interface IncubationFormData {
  incubationName: string;
  motherId: string;
  fatherId: string;
  startDate: Date;
  enableNotifications: boolean;
  notes?: string;
}

interface IncubationFormFieldsProps {
  control: Control<IncubationFormData>;
  birds: Array<{
    id: string;
    name: string;
    gender: 'male' | 'female';
    color?: string;
    age?: number;
  }>;
  isSubmitting: boolean;
}

const IncubationFormFields: React.FC<IncubationFormFieldsProps> = ({
  control,
  birds,
  isSubmitting
}) => {
  const { t } = useLanguage();

  const femaleBirds = birds.filter(bird => bird.gender === 'female');
  const maleBirds = birds.filter(bird => bird.gender === 'male');

  return (
    <div className="space-y-4">
      {/* Incubation Name */}
      <FormField
        control={control}
        name="incubationName"
        render={({ field }) => (
          <FormItem>
            <FormLabel>{t('breeding.incubationName')} *</FormLabel>
            <FormControl>
              <Input
                {...field}
                placeholder={t('breeding.incubationNamePlaceholder')}
                disabled={isSubmitting}
              />
            </FormControl>
            <FormMessage />
          </FormItem>
        )}
      />

      {/* Mother Selection */}
      <FormField
        control={control}
        name="motherId"
        render={({ field }) => (
          <FormItem>
            <FormLabel>{t('breeding.mother')} *</FormLabel>
            <Select onValueChange={field.onChange} value={field.value}>
              <FormControl>
                <SelectTrigger>
                  <SelectValue placeholder={t('breeding.selectMother')} />
                </SelectTrigger>
              </FormControl>
              <SelectContent>
                {femaleBirds.map((bird) => (
                  <SelectItem key={bird.id} value={bird.id}>
                    {bird.name} {bird.color && `(${bird.color})`}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            <FormMessage />
          </FormItem>
        )}
      />

      {/* Father Selection */}
      <FormField
        control={control}
        name="fatherId"
        render={({ field }) => (
          <FormItem>
            <FormLabel>{t('breeding.father')} *</FormLabel>
            <Select onValueChange={field.onChange} value={field.value}>
              <FormControl>
                <SelectTrigger>
                  <SelectValue placeholder={t('breeding.selectFather')} />
                </SelectTrigger>
              </FormControl>
              <SelectContent>
                {maleBirds.map((bird) => (
                  <SelectItem key={bird.id} value={bird.id}>
                    {bird.name} {bird.color && `(${bird.color})`}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            <FormMessage />
          </FormItem>
        )}
      />

      {/* Start Date */}
      <FormField
        control={control}
        name="startDate"
        render={({ field }) => (
          <FormItem>
            <FormLabel>{t('breeding.startDate')} *</FormLabel>
            <Popover>
              <PopoverTrigger asChild>
                <FormControl>
                  <Button
                    variant="outline"
                    className={cn(
                      "w-full justify-start text-left font-normal",
                      !field.value && "text-muted-foreground"
                    )}
                  >
                    <CalendarIcon className="mr-2 h-4 w-4" />
                    {field.value ? format(field.value, "PPP", { locale: tr }) : t('breeding.selectStartDate')}
                  </Button>
                </FormControl>
              </PopoverTrigger>
              <PopoverContent className="w-auto p-0">
                <Calendar
                  mode="single"
                  selected={field.value}
                  onSelect={field.onChange}
                  initialFocus
                />
              </PopoverContent>
            </Popover>
            <FormMessage />
          </FormItem>
        )}
      />

      {/* Notifications */}
      <FormField
        control={control}
        name="enableNotifications"
        render={({ field }) => (
          <FormItem className="flex items-center justify-between rounded-lg border p-3">
            <div className="space-y-0.5">
              <FormLabel>{t('breeding.enableNotifications')}</FormLabel>
              <FormDescription>
                {t('breeding.notificationsDescription')}
              </FormDescription>
            </div>
            <FormControl>
              <Switch
                checked={field.value}
                onCheckedChange={field.onChange}
                disabled={isSubmitting}
              />
            </FormControl>
          </FormItem>
        )}
      />

      {/* Notes */}
      <FormField
        control={control}
        name="notes"
        render={({ field }) => (
          <FormItem>
            <FormLabel>{t('breeding.notes')}</FormLabel>
            <FormControl>
              <Textarea
                {...field}
                placeholder={t('breeding.notesPlaceholder')}
                rows={3}
                disabled={isSubmitting}
              />
            </FormControl>
            <FormMessage />
          </FormItem>
        )}
      />
    </div>
  );
};

export default IncubationFormFields;
