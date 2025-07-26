
import React from 'react';
import { UseFormReturn } from 'react-hook-form';
import { useLanguage } from '@/contexts/LanguageContext';
import { FormField, FormItem, FormLabel, FormControl, FormMessage } from '@/components/ui/form';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Textarea } from '@/components/ui/textarea';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { Button } from '@/components/ui/button';
import { Calendar } from '@/components/ui/calendar';
import { CalendarIcon } from 'lucide-react';
import { format } from 'date-fns';
import { cn } from '@/lib/utils';
import { EggFormData } from '@/types/egg';
import { isFutureDate } from '@/utils/dateUtils';

interface EggFormFieldsProps {
  form: UseFormReturn<EggFormData>;
  isCalendarOpen: boolean;
  setIsCalendarOpen: (open: boolean) => void;
  estimatedHatchDate?: Date | null;
}

const EggFormFields: React.FC<EggFormFieldsProps> = ({
  form,
  isCalendarOpen,
  setIsCalendarOpen
}) => {
  const { t } = useLanguage();

  const statusOptions = [
    { value: 'laid', label: 'Yumurtlandı' }
  ];

  return (
    <>
      <FormField
        control={form.control}
        name="eggNumber"
        render={({ field }) => (
          <FormItem>
            <FormLabel>{t('egg.number', 'Yumurta Numarası')}</FormLabel>
            <FormControl>
              <Input
                type="number"
                min="1"
                {...field}
                onChange={(e) => field.onChange(parseInt(e.target.value) || 1)}
              />
            </FormControl>
            <FormMessage />
          </FormItem>
        )}
      />

      <FormField
        control={form.control}
        name="startDate"
        render={({ field }) => (
          <FormItem className="flex flex-col">
            <FormLabel>{t('egg.layDate', 'Yumurtlama Tarihi')}</FormLabel>
            <Popover open={isCalendarOpen} onOpenChange={setIsCalendarOpen}>
              <PopoverTrigger asChild>
                <FormControl>
                  <Button
                    variant="outline"
                    className={cn(
                      "w-full pl-3 text-left font-normal",
                      !field.value && "text-muted-foreground"
                    )}
                  >
                    {field.value ? (
                      format(field.value, "dd/MM/yyyy")
                    ) : (
                      <span>{t('common.selectDate', 'Tarih seçin')}</span>
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
                    return isFutureDate(date) || date < new Date("1900-01-01");
                  }}
                  initialFocus
                  className={cn("p-3 pointer-events-auto")}
                />
              </PopoverContent>
            </Popover>
            <FormMessage />
          </FormItem>
        )}
      />

      <FormField
        control={form.control}
        name="status"
        render={({ field }) => (
          <FormItem>
            <FormLabel>{t('egg.status', 'Durum')}</FormLabel>
            <Select onValueChange={field.onChange} defaultValue={field.value}>
              <FormControl>
                <SelectTrigger>
                  <SelectValue placeholder={t('egg.selectStatus', 'Durum seçin')} />
                </SelectTrigger>
              </FormControl>
              <SelectContent>
                {statusOptions.map((option) => (
                  <SelectItem key={option.value} value={option.value}>
                    {option.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            <FormMessage />
          </FormItem>
        )}
      />

      <FormField
        control={form.control}
        name="notes"
        render={({ field }) => (
          <FormItem>
            <FormLabel>{t('common.notes', 'Notlar')}</FormLabel>
            <FormControl>
              <Textarea
                placeholder={t('egg.notesPlaceholder', 'Yumurta hakkında notlar...')}
                className="resize-none"
                {...field}
              />
            </FormControl>
            <FormMessage />
          </FormItem>
        )}
      />
    </>
  );
};

export default EggFormFields;
