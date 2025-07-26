import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { EggFormData, EggWithClutch } from '@/types/egg';
import { eggFormSchema } from './useFormValidation';

export const useEggForm = (
  incubationId: string,
  editingEgg?: EggWithClutch | null,
  nextEggNumber?: number,
  onSubmit?: (data: EggFormData) => Promise<boolean>
) => {
  const [isCalendarOpen, setIsCalendarOpen] = useState(false);

  const form = useForm<EggFormData>({
    resolver: zodResolver(eggFormSchema),
    defaultValues: {
      id: editingEgg?.id || undefined,
      clutchId: incubationId, // Use incubationId as clutchId for compatibility
      eggNumber: editingEgg?.eggNumber || nextEggNumber || 1,
      startDate: editingEgg?.startDate || new Date(),
      status: editingEgg?.status || 'laid',
      notes: editingEgg?.notes || ''
    }
  });

  const handleSubmit = async (formData: EggFormData) => {
    if (!onSubmit) {
      console.warn('❌ No onSubmit handler provided');
      return;
    }

    try {
      // Ensure all required fields are properly typed
      const eggData: EggFormData = {
        id: editingEgg?.id || undefined,
        clutchId: incubationId, // Always use the incubationId
        eggNumber: formData.eggNumber || 1,
        startDate: formData.startDate || new Date(),
        status: formData.status || 'laid',
        notes: formData.notes || ''
      };
      
      const success = await onSubmit(eggData);
      
      if (success && !editingEgg) {
        form.reset({
          id: undefined,
          clutchId: incubationId,
          eggNumber: (nextEggNumber || 1) + 1,
          startDate: new Date(),
          status: 'laid',
          notes: ''
        });
      }
      
      return success;
    } catch (error) {
      console.error('❌ Error in handleSubmit:', error);
      return false;
    }
  };

  return {
    form,
    isCalendarOpen,
    setIsCalendarOpen,
    handleSubmit: form.handleSubmit(handleSubmit)
  };
};
