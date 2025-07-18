import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Calendar } from '@/components/ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { CalendarIcon, Clock } from 'lucide-react';
import { format } from 'date-fns';
import { cn } from '@/lib/utils';
import { formatTimeForInput, isFutureDate, validateDateTime } from '@/utils/dateUtils';

interface DateTimeInputProps {
  date: Date;
  onDateChange: (date: Date) => void;
  time?: string;
  onTimeChange?: (time: string) => void;
  label?: string;
  showTime?: boolean;
  maxDate?: Date;
  minDate?: Date;
  disabled?: boolean;
  required?: boolean;
  error?: string;
  className?: string;
}

export const DateTimeInput: React.FC<DateTimeInputProps> = ({
  date,
  onDateChange,
  time,
  onTimeChange,
  label = 'Tarih',
  showTime = false,
  maxDate,
  minDate,
  disabled = false,
  required = false,
  error,
  className
}) => {
  const [isCalendarOpen, setIsCalendarOpen] = useState(false);

  const handleDateChange = (newDate: Date | undefined) => {
    if (newDate) {
      // Eğer saat varsa, yeni tarihe saati ekle
      if (time && onTimeChange) {
        const timeParts = time.split(':').map(Number);
        const hours = timeParts[0] || 0;
        const minutes = timeParts[1] || 0;
        newDate.setHours(hours, minutes, 0, 0);
      }
      onDateChange(newDate);
    }
    setIsCalendarOpen(false);
  };

  const handleTimeChange = (newTime: string) => {
    if (onTimeChange) {
      onTimeChange(newTime);
      
      // Tarihe yeni saati uygula
      const timeParts = newTime.split(':').map(Number);
      const hours = timeParts[0] || 0;
      const minutes = timeParts[1] || 0;
      const newDate = new Date(date);
      newDate.setHours(hours, minutes, 0, 0);
      onDateChange(newDate);
    }
  };

  const isDateDisabled = (date: Date) => {
    if (isFutureDate(date)) return true;
    if (maxDate && date > maxDate) return true;
    if (minDate && date < minDate) return true;
    return false;
  };

  const validationError = time ? validateDateTime(date, time).message : null;
  const displayError = error || validationError;

  return (
    <div className={cn("space-y-2", className)}>
      {label && (
        <Label className={cn("text-sm font-medium", required && "after:content-['*'] after:ml-0.5 after:text-red-500")}>
          {label}
        </Label>
      )}
      
      <div className="grid grid-cols-2 gap-2">
        {/* Tarih Seçici */}
        <Popover open={isCalendarOpen} onOpenChange={setIsCalendarOpen}>
          <PopoverTrigger asChild>
            <Button
              variant="outline"
              className={cn(
                "w-full pl-3 text-left font-normal",
                !date && "text-muted-foreground",
                displayError && "border-red-500"
              )}
              disabled={disabled}
            >
              {date ? (
                format(date, "dd/MM/yyyy")
              ) : (
                <span>Tarih seçin</span>
              )}
              <CalendarIcon className="ml-auto h-4 w-4 opacity-50" />
            </Button>
          </PopoverTrigger>
          <PopoverContent className="w-auto p-0" align="start">
            <Calendar
              mode="single"
              selected={date}
              onSelect={handleDateChange}
              disabled={isDateDisabled}
              initialFocus
            />
          </PopoverContent>
        </Popover>

        {/* Saat Seçici */}
        {showTime && (
          <div className="relative">
            <Input
              type="time"
              value={time || formatTimeForInput(date)}
              onChange={(e) => handleTimeChange(e.target.value)}
              disabled={disabled}
              className={cn(displayError && "border-red-500")}
            />
            <Clock className="absolute right-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground pointer-events-none" />
          </div>
        )}
      </div>

      {/* Hata Mesajı */}
      {displayError && (
        <p className="text-sm text-red-500">{displayError}</p>
      )}

      {/* Yardım Metni */}
      <p className="text-xs text-muted-foreground">
        {showTime ? 'Tarih ve saat seçin' : 'Tarih seçin'}
      </p>
    </div>
  );
};

// Sadece tarih için basit versiyon
export const DateInput: React.FC<Omit<DateTimeInputProps, 'time' | 'onTimeChange' | 'showTime'>> = (props) => {
  return <DateTimeInput {...props} showTime={false} />;
};

// Sadece saat için basit versiyon
interface TimeInputProps {
  time: string;
  onTimeChange: (time: string) => void;
  label?: string;
  disabled?: boolean;
  required?: boolean;
  error?: string;
  className?: string;
}

export const TimeInput: React.FC<TimeInputProps> = ({
  time,
  onTimeChange,
  label = 'Saat',
  disabled = false,
  required = false,
  error,
  className
}) => {
  const validationError = validateDateTime(new Date(), time).message;
  const displayError = error || validationError;

  return (
    <div className={cn("space-y-2", className)}>
      {label && (
        <Label className={cn("text-sm font-medium", required && "after:content-['*'] after:ml-0.5 after:text-red-500")}>
          {label}
        </Label>
      )}
      
      <div className="relative">
        <Input
          type="time"
          value={time}
          onChange={(e) => onTimeChange(e.target.value)}
          disabled={disabled}
          className={cn(displayError && "border-red-500")}
        />
        <Clock className="absolute right-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground pointer-events-none" />
      </div>

      {displayError && (
        <p className="text-sm text-red-500">{displayError}</p>
      )}

      <p className="text-xs text-muted-foreground">
        Saat formatı: HH:MM
      </p>
    </div>
  );
}; 