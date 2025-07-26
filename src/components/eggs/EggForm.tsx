import React from 'react';
import { useLanguage } from '@/contexts/LanguageContext';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Form } from '@/components/ui/form';
import { X, Calendar, Calculator } from 'lucide-react';
import { EggFormData, EggWithClutch } from '@/types/egg';
import { useEggForm } from '@/hooks/useEggForm';
import { useFormValidation } from '@/hooks/useFormValidation';
import { toast } from '@/hooks/use-toast';
import EggFormFields from './form/EggFormFields';
import EggFormActions from './form/EggFormActions';
import { isFutureDate, addDays } from '@/utils/dateUtils';

interface EggFormProps {
  clutchId: string; // Required - no more optional
  editingEgg?: EggWithClutch | null;
  nextEggNumber: number;
  onSubmit: (data: EggFormData) => Promise<boolean>;
  onCancel: () => void;
  isSubmitting?: boolean;
  incubationStartDate?: Date; // Kuluçka başlangıç tarihi
}

const EggForm: React.FC<EggFormProps> = ({
  clutchId,
  editingEgg,
  nextEggNumber,
  onSubmit,
  onCancel,
  isSubmitting = false,
  incubationStartDate
}) => {
  const { t } = useLanguage();
  const { validateEggForm } = useFormValidation();
  
  // Otomatik çatlama tarihi hesaplama (kuluçka başlangıcı + 18 gün)
  const calculateEstimatedHatchDate = () => {
    if (incubationStartDate) {
      return addDays(incubationStartDate, 18);
    }
    return null;
  };

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

        // Kuluçka başlangıç tarihi kontrolü
        if (incubationStartDate && validatedData.startDate < incubationStartDate) {
          toast({
            title: 'Form Hatası',
            description: 'Yumurta tarihi kuluçka başlangıç tarihinden önce olamaz.',
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

  const estimatedHatchDate = calculateEstimatedHatchDate();

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
            >
              <X className="h-4 w-4" />
            </Button>
          </CardHeader>
          <CardContent>
            <Form {...form}>
              <form onSubmit={handleSubmit} className="space-y-6">
                
                {/* Tahmini Çatlama Tarihi Bilgisi */}
                {estimatedHatchDate && (
                  <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                    <div className="flex items-center gap-2 text-blue-800">
                      <Calculator className="w-4 h-4" />
                      <span className="font-medium">Tahmini Çatlama Tarihi:</span>
                      <span className="text-sm">
                        {estimatedHatchDate.toLocaleDateString('tr-TR')}
                      </span>
                    </div>
                    <p className="text-xs text-blue-600 mt-1">
                      Kuluçka başlangıcından 18 gün sonra
                    </p>
                  </div>
                )}

                <EggFormFields 
                  form={form}
                  isCalendarOpen={isCalendarOpen}
                  setIsCalendarOpen={setIsCalendarOpen}
                  estimatedHatchDate={estimatedHatchDate}
                />

                <EggFormActions 
                  onCancel={onCancel}
                  isSubmitting={isSubmitting}
                  editingEgg={editingEgg || null}
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
