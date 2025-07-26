import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Calendar } from '@/components/ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { CalendarIcon, Plus, X } from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';
import { cn } from '@/lib/utils';
import { format } from 'date-fns';
import { tr } from 'date-fns/locale';

interface AddIncubationFormProps {
  onSubmit: (data: IncubationFormData) => Promise<void>;
  onCancel: () => void;
  isLoading?: boolean;
}

interface IncubationFormData {
  nestName: string;
  startDate: Date;
  expectedHatchDate: Date;
  notes?: string;
}

const AddIncubationForm: React.FC<AddIncubationFormProps> = ({
  onSubmit,
  onCancel,
  isLoading = false
}) => {
  const { t } = useLanguage();
  const [formData, setFormData] = useState<IncubationFormData>({
    nestName: '',
    startDate: new Date(),
    expectedHatchDate: new Date(Date.now() + 18 * 24 * 60 * 60 * 1000), // 18 days from now
    notes: ''
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.nestName.trim()) return;
    
    try {
      await onSubmit(formData);
    } catch (error) {
      console.error('Form submission error:', error);
    }
  };

  const updateFormData = (field: keyof IncubationFormData, value: unknown) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  return (
    <Card className="w-full max-w-md mx-auto">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Plus className="w-5 h-5" />
          {t('breeding.addIncubation')}
        </CardTitle>
        <CardDescription>
          {t('breeding.addIncubationDescription')}
        </CardDescription>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Nest Name */}
          <div className="space-y-2">
            <Label htmlFor="nestName">{t('breeding.nestName')} *</Label>
            <Input
              id="nestName"
              value={formData.nestName}
              onChange={(e) => updateFormData('nestName', e.target.value)}
              placeholder={t('breeding.nestNamePlaceholder')}
              required
            />
          </div>

          {/* Start Date */}
          <div className="space-y-2">
            <Label>{t('breeding.startDate')} *</Label>
            <Popover>
              <PopoverTrigger asChild>
                <Button
                  variant="outline"
                  className={cn(
                    "w-full justify-start text-left font-normal",
                    !formData.startDate && "text-muted-foreground"
                  )}
                >
                  <CalendarIcon className="mr-2 h-4 w-4" />
                  {formData.startDate ? format(formData.startDate, "PPP", { locale: tr }) : t('breeding.selectStartDate')}
                </Button>
              </PopoverTrigger>
              <PopoverContent className="w-auto p-0">
                <Calendar
                  mode="single"
                  selected={formData.startDate}
                  onSelect={(date) => {
                    if (date) {
                      updateFormData('startDate', date);
                      // Auto-calculate expected hatch date (18 days later)
                      const expectedHatch = new Date(date);
                      expectedHatch.setDate(expectedHatch.getDate() + 18);
                      updateFormData('expectedHatchDate', expectedHatch);
                    }
                  }}
                  initialFocus
                />
              </PopoverContent>
            </Popover>
          </div>

          {/* Expected Hatch Date */}
          <div className="space-y-2">
            <Label>{t('breeding.expectedHatchDate')}</Label>
            <Popover>
              <PopoverTrigger asChild>
                <Button
                  variant="outline"
                  className={cn(
                    "w-full justify-start text-left font-normal",
                    !formData.expectedHatchDate && "text-muted-foreground"
                  )}
                >
                  <CalendarIcon className="mr-2 h-4 w-4" />
                  {formData.expectedHatchDate ? format(formData.expectedHatchDate, "PPP", { locale: tr }) : t('breeding.selectHatchDate')}
                </Button>
              </PopoverTrigger>
              <PopoverContent className="w-auto p-0">
                <Calendar
                  mode="single"
                  selected={formData.expectedHatchDate}
                  onSelect={(date) => date && updateFormData('expectedHatchDate', date)}
                  initialFocus
                />
              </PopoverContent>
            </Popover>
          </div>

          {/* Notes */}
          <div className="space-y-2">
            <Label htmlFor="notes">{t('breeding.notes')}</Label>
            <textarea
              id="notes"
              value={formData.notes}
              onChange={(e) => updateFormData('notes', e.target.value)}
              placeholder={t('breeding.notesPlaceholder')}
              className="w-full min-h-[80px] p-3 border border-input rounded-md resize-none focus:outline-none focus:ring-2 focus:ring-ring"
            />
          </div>

          {/* Form Actions */}
          <div className="flex gap-2 pt-4">
            <Button
              type="button"
              variant="outline"
              onClick={onCancel}
              className="flex-1"
              disabled={isLoading}
            >
              <X className="w-4 h-4 mr-2" />
              {t('common.cancel')}
            </Button>
            <Button
              type="submit"
              className="flex-1"
              disabled={isLoading || !formData.nestName.trim()}
            >
              {isLoading ? (
                <>
                  <div className="w-4 h-4 border-2 border-current border-t-transparent rounded-full animate-spin mr-2" />
                  {t('common.saving')}
                </>
              ) : (
                <>
                  <Plus className="w-4 h-4 mr-2" />
                  {t('breeding.add')}
                </>
              )}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
};

export default AddIncubationForm;
