import { useState } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';
import type { Database } from '@/integrations/supabase/types';
import { useChicksData } from '@/hooks/chick/useChicksData';
import { Chick } from '@/types';

export const useEggStatusOperations = () => {
  const { user } = useAuth();
  const { toast } = useToast();
  const { refetchChicks, optimisticAdd } = useChicksData();
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
            incubations!eggs_incubation_id_fkey(
              id,
              name,
              male_bird_id,
              female_bird_id
            )
          `)
          .eq('id', eggId)
          .eq('user_id', user.id)
          .single();

        // Debug: Log the data (commented out - no longer needed)
        // console.log('🔍 Egg data for chick creation:', eggData);
        // console.log('🔍 Incubation data:', eggData?.incubations);
        // console.log('🔍 Mother ID:', eggData?.incubations?.female_bird_id);
        // console.log('🔍 Father ID:', eggData?.incubations?.male_bird_id);

        if (eggError || !eggData) {
          console.error('❌ Failed to get egg data:', eggError);
          toast({
            title: 'Hata',
            description: 'Yumurta bilgileri alınamadı.',
            variant: 'destructive'
          });
          return false;
        }

        // Debug: Log egg data structure
        // console.log('🔍 Egg data structure:', {
        //   id: eggData?.id,
        //   number: eggData?.number,
        //   egg_number: eggData?.egg_number,
        //   incubation_id: eggData?.incubation_id,
        //   status: eggData?.status
        // });
        // console.log('🔍 Using egg_number first:', eggData?.egg_number);
        // console.log('🔍 Fallback to number:', eggData?.number);

        // Eğer egg data yoksa, egg ID ile fetch et
        let workingEggData = eggData;
        if (!workingEggData || !workingEggData.id) {
          // console.log('🔍 Egg data missing, fetching egg by ID:', eggId);
          const { data: fetchedEgg, error: eggError } = await supabase
            .from('eggs')
            .select('id, egg_number, incubation_id, status')
            .eq('id', eggId)
            .eq('user_id', user.id)
            .single();
          
          if (!eggError && fetchedEgg) {
            // Array olarak gelirse ilk elemanı al
            const eggDataToUse = Array.isArray(fetchedEgg) ? fetchedEgg[0] : fetchedEgg;
            workingEggData = { ...eggData, ...eggDataToUse } as typeof eggData;
            // console.log('✅ Egg data fetched successfully:', eggDataToUse);
          } else {
            console.error('❌ Failed to fetch egg data:', eggError);
          }
        }

        // Eğer incubation verisi yoksa, ayrı sorgu ile al
        let incubationData = workingEggData?.incubations;
        // console.log('🔍 Egg incubation_id:', workingEggData?.incubation_id);
        // console.log('🔍 Function parameter incubationId:', incubationId);
        // console.log('🔍 Initial incubation data:', incubationData);
        
        if (!incubationData && eggData.incubation_id) {
          // console.log('🔍 Fetching incubation data separately...');
          const { data: incData, error: incError } = await supabase
            .from('incubations')
            .select('id, name, male_bird_id, female_bird_id')
            .eq('id', eggData.incubation_id)
            .eq('user_id', user.id)
            .single();
          
          if (!incError && incData) {
            incubationData = incData;
            // console.log('✅ Incubation data fetched separately:', incData);
          } else {
            console.error('❌ Failed to fetch incubation data:', incError);
          }
        }
        
        // Eğer hala yoksa, function parametresindeki incubationId'yi kullan
        if (!incubationData && incubationId) {
          // console.log('🔍 Using function parameter incubationId:', incubationId);
          const { data: incData, error: incError } = await supabase
            .from('incubations')
            .select('id, name, male_bird_id, female_bird_id')
            .eq('id', incubationId)
            .eq('user_id', user.id)
            .single();
          
          if (!incError && incData) {
            // Array olarak gelirse ilk elemanı al
            incubationData = Array.isArray(incData) ? incData[0] : incData;
            // console.log('✅ Incubation data fetched using parameter:', incubationData);
            // console.log('🔍 Incubation female_bird_id:', incubationData.female_bird_id);
            // console.log('🔍 Incubation male_bird_id:', incubationData.male_bird_id);
          } else {
            console.error('❌ Failed to fetch incubation data with parameter:', incError);
          }
        }

        // Create chick with incubation_id
        const incubationName = incubationData?.name || 'Bilinmeyen Kuluçka';
        const hatchDate = new Date().toISOString().split('T')[0];
        
        // Generate better chick name
        const eggNumber = workingEggData?.egg_number;
        const chickName = eggNumber 
          ? `Yavru ${eggNumber}${incubationName !== 'Bilinmeyen Kuluçka' ? ` (${incubationName})` : ''}`
          : `Yavru ${new Date().getTime().toString().slice(-4)}${incubationName !== 'Bilinmeyen Kuluçka' ? ` (${incubationName})` : ''}`;
        
        // console.log('🔍 Egg number calculation:', {
        //   workingEggData_egg_number: workingEggData?.egg_number,
        //   calculated_eggNumber: eggNumber
        // });
        
        // Type-safe chick data
        const chickData = {
          user_id: user.id,
          egg_id: eggId,
          incubation_id: incubationId,
          name: chickName,
          hatch_date: hatchDate,
          mother_id: incubationData?.female_bird_id || null,
          father_id: incubationData?.male_bird_id || null,
          health_notes: `${incubationName} yuvasından çıktı`,
          gender: 'unknown', // Varsayılan olarak bilinmiyor
          egg_number: eggNumber // Yumurta numarasını ekle
        } as any;

        // Create optimistic chick for immediate UI feedback
        const optimisticChick: Chick = {
          id: `temp_${Date.now()}`, // Temporary ID
          name: chickName,
          breedingId: incubationId,
          eggId: eggId,
          egg_id: eggId,
          incubationId: incubationId,
          incubation_id: incubationId,
          incubationName: incubationName || '',
          eggNumber: eggNumber || 0,
          hatchDate: hatchDate,
          hatch_date: hatchDate,
          gender: 'unknown',
          color: undefined,
          ringNumber: undefined,
          ring_number: undefined,
          photo: undefined,
          healthNotes: `${incubationName} yuvasından çıktı`,
          health_notes: `${incubationName} yuvasından çıktı`,
          motherId: incubationData?.female_bird_id || undefined,
          mother_id: incubationData?.female_bird_id || undefined,
          fatherId: incubationData?.male_bird_id || undefined,
          father_id: incubationData?.male_bird_id || undefined,
        };

        // Add optimistically to UI immediately
        optimisticAdd(optimisticChick);
        
        const { data: createdChick, error: chickError } = await supabase
          .from('chicks')
          .insert(chickData)
          .select()
          .single();

        if (chickError) {
          console.error('❌ Failed to create chick:', chickError);
          toast({
            title: 'Hata',
            description: 'Yavru oluşturulurken hata oluştu.',
            variant: 'destructive'
          });
          return false;
        }

        // console.log('✅ Chick created successfully:', createdChick);

        // Realtime subscription will handle the UI update automatically
        // No need to manually refetch since realtime subscription is active

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
