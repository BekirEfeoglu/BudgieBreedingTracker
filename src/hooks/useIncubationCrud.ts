
import { useState } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';
import { IncubationFormData } from '@/components/forms/IncubationFormValidation';

export const useIncubationCrud = () => {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const { user } = useAuth();
  const { toast } = useToast();

  const addIncubation = async (formData: IncubationFormData): Promise<boolean> => {
    if (!user) {
      console.error('❌ No user found for incubation creation');
      return false;
    }

    setIsSubmitting(true);
    console.log('🐣 Starting incubation creation:', formData);

    try {
      const startDate = formData.startDate.toISOString().split('T')[0];
      
      const incubationData = {
        name: formData.incubationName,
        male_bird_id: formData.fatherId,
        female_bird_id: formData.motherId,
        start_date: startDate,
        enable_notifications: formData.enableNotifications,
        notes: formData.notes || '',
        user_id: user.id
      };

      console.log('📤 Inserting incubation:', incubationData);

      const { data, error } = await supabase
        .from('incubations')
        .insert(incubationData as any)
        .select()
        .single();

      if (error) {
        console.error('❌ Failed to create incubation:', error);
        toast({
          title: 'Hata',
          description: 'Kuluçka oluşturulurken bir hata oluştu.',
          variant: 'destructive'
        });
        return false;
      }

      console.log('✅ Incubation created successfully:', data);
      toast({
        title: 'Başarılı',
        description: `"${formData.incubationName}" kuluçkası başarıyla oluşturuldu.`
      });

      return true;

    } catch (error) {
      console.error('💥 Exception during incubation creation:', error);
      toast({
        title: 'Hata',
        description: 'Kuluçka oluşturulurken beklenmedik bir hata oluştu.',
        variant: 'destructive'
      });
      return false;
    } finally {
      setIsSubmitting(false);
    }
  };

  const updateIncubation = async (incubationId: string, formData: IncubationFormData): Promise<boolean> => {
    if (!user) {
      console.error('❌ No user found for incubation update');
      return false;
    }

    setIsSubmitting(true);
    console.log('✏️ Starting incubation update:', incubationId, formData);

    try {
      const updateStartDate = formData.startDate.toISOString().split('T')[0];
      
      const updateData = {
        name: formData.incubationName,
        male_bird_id: formData.fatherId,
        female_bird_id: formData.motherId,
        start_date: updateStartDate,
        enable_notifications: formData.enableNotifications,
        notes: formData.notes || '',
        updated_at: new Date().toISOString()
      };

      console.log('📤 Updating incubation:', updateData);

      const { data, error } = await supabase
        .from('incubations')
        .update(updateData as any)
        .eq('id', incubationId)
        .eq('user_id', user.id)
        .select()
        .single();

      if (error) {
        console.error('❌ Failed to update incubation:', error);
        toast({
          title: 'Hata',
          description: 'Kuluçka güncellenirken bir hata oluştu.',
          variant: 'destructive'
        });
        return false;
      }

      console.log('✅ Incubation updated successfully:', data);
      toast({
        title: 'Başarılı',
        description: `"${formData.incubationName}" kuluçkası başarıyla güncellendi.`
      });

      return true;

    } catch (error) {
      console.error('💥 Exception during incubation update:', error);
      toast({
        title: 'Hata',
        description: 'Kuluçka güncellenirken beklenmedik bir hata oluştu.',
        variant: 'destructive'
      });
      return false;
    } finally {
      setIsSubmitting(false);
    }
  };

  return {
    addIncubation,
    updateIncubation,
    isSubmitting
  };
};
