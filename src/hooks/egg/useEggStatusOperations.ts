import { useState } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';

export const useEggStatusOperations = () => {
  const { user } = useAuth();
  const { toast } = useToast();
  const [isUpdating, setIsUpdating] = useState(false);

  const updateEggStatus = async (eggId: string, newStatus: string, incubationId: string) => {
    if (!user) {
      console.error('❌ No user authenticated');
      return false;
    }

    setIsUpdating(true);

    try {
      if (newStatus === 'infertile') {
        // Soft delete the egg but keep it for statistics and calendar
        const { error: updateError } = await supabase
          .from('eggs')
          .update({ 
            status: 'infertile',
            is_deleted: true,
            updated_at: new Date().toISOString()
          })
          .eq('id', eggId)
          .eq('user_id', user.id);

        if (updateError) {
          console.error('❌ Failed to soft delete egg:', updateError);
          toast({
            title: 'Hata',
            description: 'Yumurta durumu güncellenirken hata oluştu.',
            variant: 'destructive'
          });
          return false;
        }

        toast({
          title: 'Başarılı',
          description: 'Yumurta boş olarak işaretlendi.',
        });

      } else if (newStatus === 'hatched') {
        // Get egg details and incubation info for creating chick
        const { data: eggData, error: eggError } = await supabase
          .from('eggs')
          .select(`
            *,
            incubations!inner(
              id,
              name,
              male_bird_id,
              female_bird_id
            )
          `)
          .eq('id', eggId)
          .eq('user_id', user.id)
          .single();

        if (eggError || !eggData) {
          console.error('❌ Failed to get egg data:', eggError);
          toast({
            title: 'Hata',
            description: 'Yumurta bilgileri alınamadı.',
            variant: 'destructive'
          });
          return false;
        }

        // Create chick with incubation_id
        const chickData = {
          user_id: user.id,
          egg_id: eggId,
          incubation_id: incubationId,
          name: `Yavru ${eggData.egg_number} (${eggData.incubations.name})`,
          hatch_date: new Date().toISOString().split('T')[0],
          mother_id: eggData.incubations.female_bird_id,
          father_id: eggData.incubations.male_bird_id,
          health_notes: `${eggData.incubations.name} yuvasından çıktı`
        };

        const { error: chickError } = await supabase
          .from('chicks')
          .insert(chickData);

        if (chickError) {
          console.error('❌ Failed to create chick:', chickError);
          toast({
            title: 'Hata',
            description: 'Yavru oluşturulurken hata oluştu.',
            variant: 'destructive'
          });
          return false;
        }

        // Soft delete the egg (it hatched, so remove from egg list)
        const { error: updateError } = await supabase
          .from('eggs')
          .update({ 
            status: 'hatched',
            hatch_date: new Date().toISOString().split('T')[0] || null,
            is_deleted: true,
            updated_at: new Date().toISOString()
          })
          .eq('id', eggId)
          .eq('user_id', user.id);

        if (updateError) {
          console.error('❌ Failed to update egg status:', updateError);
          toast({
            title: 'Uyarı',
            description: 'Yavru oluşturuldu ancak yumurta durumu güncellenemedi.',
            variant: 'destructive'
          });
          return false;
        }

        toast({
          title: 'Başarılı! 🐣',
          description: 'Yumurta çıktı ve yavru Yavrular sekmesine eklendi!',
        });

      } else {
        // Regular status update (fertile, laid, etc.)
        const { error: updateError } = await supabase
          .from('eggs')
          .update({ 
            status: newStatus,
            updated_at: new Date().toISOString()
          })
          .eq('id', eggId)
          .eq('user_id', user.id);

        if (updateError) {
          console.error('❌ Failed to update egg status:', updateError);
          toast({
            title: 'Hata',
            description: 'Yumurta durumu güncellenirken hata oluştu.',
            variant: 'destructive'
          });
          return false;
        }

        toast({
          title: 'Güncellendi',
          description: 'Yumurta durumu başarıyla güncellendi.',
        });
      }

      return true;

    } catch (error) {
      console.error('💥 Exception updating egg status:', error);
      toast({
        title: 'Hata',
        description: 'Beklenmedik bir hata oluştu.',
        variant: 'destructive'
      });
      return false;
    } finally {
      setIsUpdating(false);
    }
  };

  return {
    updateEggStatus,
    isUpdating
  };
};
