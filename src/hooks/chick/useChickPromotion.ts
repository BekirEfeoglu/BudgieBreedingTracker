import { useCallback } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/hooks/useAuth';
import { useToast } from '@/hooks/use-toast';
import { Chick, Bird } from '@/types';

export const useChickPromotion = () => {
  const { user } = useAuth();
  const { toast } = useToast();

  const promoteChickToBird = useCallback(async (
    chick: Chick, 
    refetchChicks?: () => void,
    refetchBirds?: () => void
  ): Promise<{ success: boolean; bird?: Bird; error?: any }> => {
    if (!user) {
      console.error('❌ promoteChickToBird - Kullanıcı girişi yok');
      return { success: false, error: 'Kullanıcı girişi yok' };
    }

    console.log('🔄 promoteChickToBird - Yavru kuşa aktarma başlıyor:', { 
      chickId: chick.id, 
      chickName: chick.name,
      userId: user.id 
    });

    try {
      // Yeni kuş verisi oluştur
      const birdData = {
        user_id: user.id,
        name: chick.name,
        gender: chick.gender || 'unknown',
        color: chick.color || null,
        ring_number: chick.ringNumber || null,
        birth_date: chick.hatchDate || new Date().toISOString().split('T')[0] || null,
        mother_id: chick.motherId || null,
        father_id: chick.fatherId || null,
        health_notes: `Yavru olarak yetiştirildi. ${chick.healthNotes || ''}`.trim(),
        photo_url: chick.photo || null
      };

      console.log('🔄 promoteChickToBird - Kuş verisi:', birdData);

      // Kuşu veritabanına ekle
      const { data: newBird, error: birdError } = await supabase
        .from('birds')
        .insert(birdData)
        .select()
        .single();

      if (birdError) {
        console.error('❌ promoteChickToBird - Kuş ekleme hatası:', birdError);
        toast({
          title: 'Hata',
          description: `Kuş oluşturulurken hata oluştu: ${birdError.message}`,
          variant: 'destructive'
        });
        return { success: false, error: birdError };
      }

      console.log('✅ promoteChickToBird - Kuş başarıyla oluşturuldu:', newBird);

      // Yavruyu sil
      const { error: deleteError } = await supabase
        .from('chicks')
        .delete()
        .eq('id', chick.id)
        .eq('user_id', user.id);

      if (deleteError) {
        console.error('❌ promoteChickToBird - Yavru silme hatası:', deleteError);
        toast({
          title: 'Uyarı',
          description: 'Kuş oluşturuldu ancak yavru silinemedi.',
          variant: 'destructive'
        });
        return { success: false, error: deleteError };
      }

      console.log('✅ promoteChickToBird - Yavru başarıyla silindi');

      toast({
        title: 'Başarılı! 🐦',
        description: `${chick.name} başarıyla kuşa aktarıldı!`
      });

      // Force refresh chicks and birds lists after promotion since realtime subscription might not work
      setTimeout(() => {
        if (refetchChicks) {
          console.log('🔄 promoteChickToBird - Yavru listesi yenileniyor');
          refetchChicks();
        }
        if (refetchBirds) {
          console.log('🔄 promoteChickToBird - Kuş listesi yenileniyor');
          refetchBirds();
        }
      }, 500);

      return { success: true, bird: newBird as Bird };

    } catch (error) {
      console.error('💥 promoteChickToBird - Beklenmedik hata:', error);
      toast({
        title: 'Hata',
        description: 'Beklenmedik bir hata oluştu',
        variant: 'destructive'
      });
      return { success: false, error };
    }
  }, [user, toast]);

  return {
    promoteChickToBird
  };
}; 