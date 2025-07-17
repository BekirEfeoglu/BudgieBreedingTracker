import React from 'react';
import { useLanguage } from '@/contexts/LanguageContext';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Form } from '@/components/ui/form';
import { X } from 'lucide-react';
import { EggFormData, EggWithClutch } from '@/types/egg';
import { useEggForm } from '@/hooks/useEggForm';
import { useFormValidation } from '@/hooks/useFormValidation';
import { toast } from '@/hooks/use-toast';
import EggFormFields from './form/EggFormFields';
import EggFormActions from './form/EggFormActions';
import { isFutureDate } from '@/utils/dateUtils';

interface EggFormProps {
  clutchId: string; // Required - no more optional
  editingEgg?: EggWithClutch | null;
  nextEggNumber: number;
  onSubmit: (data: EggFormData) => Promise<boolean>;
  onCancel: () => void;
  isSubmitting?: boolean;
}

const EggForm: React.FC<EggFormProps> = ({
  clutchId,
  editingEgg,
  nextEggNumber,
  onSubmit,
  onCancel,
  isSubmitting = false
}) => {
  const { t } = useLanguage();
  const { validateEggForm } = useFormValidation();
  const { form, isCalendarOpen, setIsCalendarOpen, handleSubmit } = useEggForm(
    clutchId,
    editingEgg,
    nextEggNumber,
    async (formData: EggFormData) => {
      try {
        // EggFormData tipine uygun nesneyi oluştur
        const eggData: EggFormData = {
          clutchId, // Props'dan gelen zorunlu string - artık kesinlikle string
          eggNumber: formData.eggNumber ?? nextEggNumber,
          startDate: formData.startDate!,
          status: formData.status!,
          notes: formData.notes || ''
        };
        if (editingEgg?.id) eggData.id = editingEgg.id;
        
        // Artık tamamen tiplenmiş eggData'yı validate et
        const validatedData = validateEggForm(eggData);
        if (validatedData.eggNumber <= 0) {
          toast({
            title: 'Form Hatası',
            description: 'Yumurta numarası 1 veya daha büyük olmalıdır.',
            variant: 'destructive'
          });
          return false;
        }
        if (isFutureDate(validatedData.startDate)) {
          toast({
            title: 'Form Hatası',
            description: 'Başlangıç tarihi gelecekte olamaz.',
            variant: 'destructive'
          });
          return false;
        }
        const success = await onSubmit(eggData);
        if (success) {
          toast({
            title: 'Başarılı',
            description: editingEgg ? 'Yumurta güncellendi.' : 'Yumurta eklendi.',
          });
        }
        return success;
      } catch (error) {
        console.error('Yumurta form hatası:', error);
        toast({
          title: 'Form Hatası',
          description: error instanceof Error ? error.message : 'Form gönderilirken bir hata oluştu.',
          variant: 'destructive'
        });
        return false;
      }
    }
  );

  return (
    <div className="fixed inset-0 z-50 bg-background overflow-y-auto">
      <div className="container mx-auto p-2 sm:p-4 max-w-2xl w-full">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between">
            <CardTitle className="flex items-center gap-2">
              🥚 {editingEgg ? t('egg.edit', 'Yumurta Düzenle') : t('egg.add', 'Yumurta Ekle')}
            </CardTitle>
            <Button
              variant="ghost"
              size="sm"
              onClick={onCancel}
              className="h-8 w-8 p-0"
              disabled={isSubmitting}
            >
              <X className="h-4 w-4" />
            </Button>
          </CardHeader>
          <CardContent>
            <Form {...form}>
              <form onSubmit={handleSubmit} className="space-y-4">
                <EggFormFields
                  form={form}
                  isCalendarOpen={isCalendarOpen}
                  setIsCalendarOpen={setIsCalendarOpen}
                />
                <EggFormActions
                  isSubmitting={isSubmitting}
                  isEditing={!!editingEgg}
                  onCancel={onCancel}
                />
              </form>
            </Form>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default EggForm;
