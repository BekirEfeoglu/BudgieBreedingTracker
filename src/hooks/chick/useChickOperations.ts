import { useState, useCallback } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';
import { Chick } from '@/types';
import { useChicksData } from '@/hooks/chick/useChicksData';

export const useChickOperations = () => {
  const { user } = useAuth();
  const { toast } = useToast();
  const { chicks, loading, refreshChicks } = useChicksData();
  const [editingChick, setEditingChick] = useState<Chick | null>(null);
  const [isChickFormOpen, setIsChickFormOpen] = useState(false);
  const [isPromoting, setIsPromoting] = useState(false);

  const handleAddChick = () => {
    setEditingChick(null);
    setIsChickFormOpen(true);
  };

  const handleEditChick = (chick: Chick) => {
    setEditingChick(chick);
    setIsChickFormOpen(true);
  };

  const handleSaveChick = async (updatedChickData: Record<string, unknown>) => {
    if (!user) return;

    try {
      if (editingChick) {
        // Update existing chick
        const updatedChick: Chick = {
          ...editingChick,
          name: updatedChickData.name as string,
          gender: updatedChickData.gender as string,
          color: updatedChickData.color as string ?? null,
          hatchDate: updatedChickData.birthDate ? (updatedChickData.birthDate as Date).toISOString().split('T')[0] : editingChick.hatchDate,
          ringNumber: updatedChickData.ringNumber as string ?? null,
          healthNotes: updatedChickData.healthNotes as string ?? null,
          photo: updatedChickData.photo as string ?? null
        };

        // Update in Supabase
        const { error } = await supabase
          .from('chicks')
          .update({
            name: updatedChick.name,
            gender: updatedChick.gender,
            color: updatedChick.color ?? null,
            hatch_date: updatedChick.hatchDate,
            ring_number: updatedChick.ringNumber ?? null,
            health_notes: updatedChick.healthNotes ?? null,
            photo_url: updatedChick.photo ?? null,
            updated_at: new Date().toISOString()
          })
          .eq('id', updatedChick.id)
          .eq('user_id', user.id);

        if (error) {
          toast({
            title: 'Hata',
            description: 'Yavru güncellenirken hata oluştu.',
            variant: 'destructive'
          });
          return;
        }

        // Update local state
        if (typeof refreshChicks === 'function') {
          await refreshChicks();
        }

        toast({
          title: 'Başarılı',
          description: `"${updatedChick.name}" adlı yavru başarıyla güncellendi.`,
        });
      } else {
        // Find or create default incubation for new chick
        let defaultIncubationId = updatedChickData.incubationId as string;
        
        if (!defaultIncubationId) {
          // Try to find an existing incubation
          const { data: existingIncubation } = await supabase
            .from('incubations')
            .select('id')
            .eq('user_id', user.id)
            .order('created_at', { ascending: false })
            .limit(1)
            .single();

          if (existingIncubation) {
            defaultIncubationId = existingIncubation.id;
          } else {
            // Create a default incubation
            const { data: newIncubation, error: incubationError } = await supabase
              .from('incubations')
              .insert({
                user_id: user.id,
                name: 'Varsayılan Kuluçka',
                pair_id: 'default_pair',
                start_date: new Date().toISOString().split('T')[0],
                egg_count: 0
              })
              .select('id')
              .single();

            if (incubationError || !newIncubation) {
              toast({
                title: 'Hata',
                description: 'Varsayılan kuluçka oluşturulamadı.',
                variant: 'destructive'
              });
              return;
            }

            defaultIncubationId = newIncubation.id;
          }
        }

        if (!user?.id) {
          toast({
            title: 'Hata',
            description: 'Kullanıcı bulunamadı, yavru eklenemedi.',
            variant: 'destructive'
          });
          return;
        }
        const newChick = {
          name: updatedChickData.name as string,
          gender: updatedChickData.gender as string,
          color: updatedChickData.color as string ?? null,
          hatch_date: updatedChickData.birthDate ? (updatedChickData.birthDate as Date).toISOString().split('T')[0] : new Date().toISOString().split('T')[0],
          ring_number: updatedChickData.ringNumber as string ?? null,
          health_notes: updatedChickData.healthNotes as string ?? null,
          photo_url: updatedChickData.photo as string ?? null,
          mother_id: updatedChickData.motherId as string ?? null,
          father_id: updatedChickData.fatherId as string ?? null,
          incubation_id: defaultIncubationId,
          user_id: user.id
        };

        const { data, error } = await supabase
          .from('chicks')
          .insert([newChick])
          .select()
          .single();

        if (error) {
          toast({
            title: 'Hata',
            description: 'Yavru eklenirken hata oluştu.',
            variant: 'destructive'
          });
          return;
        }

        toast({
          title: 'Başarılı',
          description: `"${newChick.name}" adlı yavru başarıyla eklendi.`,
        });
      }

      setIsChickFormOpen(false);
      setEditingChick(null);
    } catch (_error) {
      toast({
        title: 'Hata',
        description: 'Beklenmedik bir hata oluştu.',
        variant: 'destructive'
      });
    }
  };

  const handleCloseChickForm = () => {
    setIsChickFormOpen(false);
    setEditingChick(null);
  };

  const handleDeleteChick = async (chickId: string) => {
    if (!user) {
      return;
    }

    try {
      // Delete from Supabase
      const { error } = await supabase
        .from('chicks')
        .delete()
        .eq('id', chickId)
        .eq('user_id', user.id);

      if (error) {
        toast({
          title: 'Hata',
          description: 'Yavru silinirken hata oluştu.',
          variant: 'destructive'
        });
        return;
      }

      // Remove from local state only if database deletion was successful
      const chickToDelete = chicks.find(c => c.id === chickId);
      
      toast({
        title: 'Başarılı',
        description: `"${chickToDelete?.name}" adlı yavru başarıyla silindi.`,
      });

    } catch (_error) {
      toast({
        title: 'Hata',
        description: 'Beklenmedik bir hata oluştu.',
        variant: 'destructive'
      });
    }
  };

  const promoteChickToBird = useCallback(async (chick: Chick): Promise<boolean> => {
    if (!user) {
      return false;
    }

    setIsPromoting(true);

    try {
      // 1. Yavruyu kuş olarak kaydet
      const birdData = {
        user_id: user.id,
        name: chick.name,
        gender: chick.gender || 'unknown',
        color: chick.color ?? null,
        birth_date: chick.hatchDate,
        ring_number: chick.ringNumber ?? null,
        photo_url: chick.photo ?? null,
        health_notes: chick.healthNotes ?? null,
        mother_id: chick.motherId ?? null,
        father_id: chick.fatherId ?? null
      };

      const { data: newBird, error: birdError } = await supabase
        .from('birds')
        .insert(birdData)
        .select()
        .single();

      if (birdError) {
        toast({
          title: 'Hata',
          description: 'Yavru kuşa dönüştürülürken bir hata oluştu.',
          variant: 'destructive'
        });
        return false;
      }

      // 2. Yavruyu sil
      const { error: chickError } = await supabase
        .from('chicks')
        .delete()
        .eq('id', chick.id)
        .eq('user_id', user.id);

      if (chickError) {
        toast({
          title: 'Hata',
          description: 'Yavru silinirken bir hata oluştu.',
          variant: 'destructive'
        });
        return false;
      }

      // 3. Listeyi güncelle
      if (typeof refreshChicks === 'function') {
        await refreshChicks();
      }

      toast({
        title: 'Başarılı! 🦜',
        description: `"${chick.name}" artık kuşlar sekmesinde!`,
      });

      return true;

    } catch (_error) {
      toast({
        title: 'Hata',
        description: 'Yavru kuşa dönüştürülürken beklenmedik bir hata oluştu.',
        variant: 'destructive'
      });
      return false;
    } finally {
      setIsPromoting(false);
    }
  }, [user, toast, refreshChicks]);

  return {
    chicks,
    loading,
    editingChick,
    isChickFormOpen,
    isPromoting,
    setEditingChick,
    setIsChickFormOpen,
    promoteChickToBird,
    handleAddChick,
    handleEditChick,
    handleSaveChick,
    handleCloseChickForm,
    handleDeleteChick
  };
};
