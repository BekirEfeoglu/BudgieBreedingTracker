import React, { useState, useCallback } from 'react';
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

interface EnhancedIncubationFormProps {
  birds: Array<{
    id: string;
    name: string;
    gender: 'male' | 'female' | 'unknown';
    color?: string;
    age?: number;
  }>;
  onSubmit: (data: IncubationFormData) => Promise<void>;
  onCancel: () => void;
  isLoading?: boolean;
  editingIncubation?: {
    id: string;
    name: string;
    motherId: string;
    fatherId: string;
    startDate: string | Date;
    enableNotifications?: boolean;
    notes?: string;
  } | null;
  formType?: 'add' | 'edit';
}

interface IncubationFormData {
  incubationName: string;
  motherId: string;
  fatherId: string;
  startDate: Date;
  enableNotifications: boolean;
  notes?: string;
}

const EnhancedIncubationForm: React.FC<EnhancedIncubationFormProps> = ({
  birds,
  onSubmit,
  onCancel,
  isLoading = false,
  editingIncubation = null,
  formType = 'add',
}) => {
  const { t } = useLanguage();
  const [formData, setFormData] = useState<IncubationFormData>(() => {
    if (editingIncubation) {
      return {
        incubationName: editingIncubation.name || '',
        motherId: editingIncubation.motherId || '',
        fatherId: editingIncubation.fatherId || '',
        startDate: editingIncubation.startDate ? new Date(editingIncubation.startDate) : new Date(),
        enableNotifications: editingIncubation.enableNotifications ?? true,
        notes: editingIncubation.notes || '',
      };
    }
    return {
      incubationName: '',
      motherId: '',
      fatherId: '',
      startDate: new Date(),
      enableNotifications: true,
      notes: ''
    };
  });
  const [errors, setErrors] = useState<{ [key: string]: string }>({});

  const femaleBirds = birds.filter(bird => bird.gender === 'female');
  const maleBirds = birds.filter(bird => bird.gender === 'male');

  const handleSubmit = useCallback(async (e: React.FormEvent) => {
    e.preventDefault();
    const newErrors: { [key: string]: string } = {};
    if (!formData.incubationName.trim()) newErrors.incubationName = t('breeding.incubationNameRequired') || 'İsim gerekli';
    if (!formData.motherId) newErrors.motherId = t('breeding.motherRequired') || 'Anne seçilmeli';
    if (!formData.fatherId) newErrors.fatherId = t('breeding.fatherRequired') || 'Baba seçilmeli';
    setErrors(newErrors);
    if (Object.keys(newErrors).length > 0) return;
    try {
      await onSubmit(formData);
    } catch (error) {
      setErrors({ submit: t('breeding.formSubmitError') || 'Bir hata oluştu.' });
    }
  }, [formData, onSubmit, t]);

  const updateFormData = useCallback((field: keyof IncubationFormData, value: unknown) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  }, []);

  const hasValidBirds = femaleBirds.length > 0 && maleBirds.length > 0;

  if (!hasValidBirds) {
    return (
      <Card className="w-full max-w-md mx-auto">
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-destructive">
            <AlertTriangle className="w-5 h-5" />
            {t('breeding.noValidBirds')}
          </CardTitle>
          <CardDescription>
            {t('breeding.noValidBirdsDescription')}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Button onClick={onCancel} className="w-full">
            {t('common.back')}
          </Button>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="w-full max-w-md mx-auto">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          {formType === 'edit' ? <>
            <Plus className="w-5 h-5" />
            {t('breeding.editIncubation') || 'Kuluçkayı Düzenle'}
          </> : <>
            <Plus className="w-5 h-5" />
            {t('breeding.addIncubation')}
          </>}
        </CardTitle>
        <CardDescription>
          {formType === 'edit' ? (t('breeding.editIncubationDescription') || 'Kuluçka bilgilerini düzenleyin.') : t('breeding.addIncubationDescription')}
        </CardDescription>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Incubation Name */}
          <div className="space-y-2">
            <Label htmlFor="incubationName">{t('breeding.incubationName')} *</Label>
            <Input
              id="incubationName"
              value={formData.incubationName}
              onChange={(e) => updateFormData('incubationName', e.target.value)}
              placeholder={t('breeding.incubationNamePlaceholder')}
              required
              aria-invalid={!!errors.incubationName}
            />
            {errors.incubationName && <div className="text-destructive text-xs">{errors.incubationName}</div>}
          </div>
          {/* Mother Selection */}
          <div className="space-y-2">
            <Label htmlFor="motherId">{t('breeding.mother')} *</Label>
            <Select
              value={formData.motherId}
              onValueChange={(value) => updateFormData('motherId', value)}
            >
              <SelectTrigger aria-invalid={!!errors.motherId}>
                <SelectValue placeholder={t('breeding.selectMother')} />
              </SelectTrigger>
              <SelectContent>
                {femaleBirds.map((bird) => (
                  <SelectItem key={bird.id} value={bird.id}>
                    {bird.name} {bird.color && `(${bird.color})`}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            {errors.motherId && <div className="text-destructive text-xs">{errors.motherId}</div>}
          </div>
          {/* Father Selection */}
          <div className="space-y-2">
            <Label htmlFor="fatherId">{t('breeding.father')} *</Label>
            <Select
              value={formData.fatherId}
              onValueChange={(value) => updateFormData('fatherId', value)}
            >
              <SelectTrigger aria-invalid={!!errors.fatherId}>
                <SelectValue placeholder={t('breeding.selectFather')} />
              </SelectTrigger>
              <SelectContent>
                {maleBirds.map((bird) => (
                  <SelectItem key={bird.id} value={bird.id}>
                    {bird.name} {bird.color && `(${bird.color})`}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            {errors.fatherId && <div className="text-destructive text-xs">{errors.fatherId}</div>}
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
                  onSelect={(date) => date && updateFormData('startDate', date)}
                  initialFocus
                />
              </PopoverContent>
            </Popover>
          </div>
          {/* Notifications */}
          <div className="flex items-center justify-between">
            <Label htmlFor="notifications">{t('breeding.enableNotifications')}</Label>
            <Switch
              id="notifications"
              checked={formData.enableNotifications}
              onCheckedChange={(checked) => updateFormData('enableNotifications', checked)}
            />
          </div>
          {/* Notes */}
          <div className="space-y-2">
            <Label htmlFor="notes">{t('breeding.notes')}</Label>
            <Textarea
              id="notes"
              value={formData.notes}
              onChange={(e) => updateFormData('notes', e.target.value)}
              placeholder={t('breeding.notesPlaceholder')}
              rows={3}
            />
          </div>
          {/* Form Actions */}
          {errors.submit && <div className="text-destructive text-xs mb-2">{errors.submit}</div>}
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
              disabled={isLoading || !formData.incubationName.trim() || !formData.motherId || !formData.fatherId}
            >
              {isLoading ? (
                <>
                  <div className="w-4 h-4 border-2 border-current border-t-transparent rounded-full animate-spin mr-2" />
                  {t('common.saving')}
                </>
              ) : (
                <>
                  <Plus className="w-4 h-4 mr-2" />
                  {formType === 'edit' ? (t('common.save') || 'Kaydet') : t('breeding.add')}
                </>
              )}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
};

export default EnhancedIncubationForm;
