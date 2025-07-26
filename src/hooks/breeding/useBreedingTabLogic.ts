import { useState, useCallback, useMemo } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useClutchesData } from '@/hooks/useClutchesData';
import { useIncubationData } from '@/hooks/useIncubationData';
import { useToast } from '@/hooks/use-toast';
import { useAuth } from '@/hooks/useAuth';

export const useBreedingTabLogic = (birds: any[] = []) => {
  const { user } = useAuth();
  const [isBreedingFormOpen, setIsBreedingFormOpen] = useState(false);
  const [selectedBreeding, setSelectedBreeding] = useState<any>(null);
  const [isIncubationFormOpen, setIsIncubationFormOpen] = useState(false);
  const [editingIncubation, setEditingIncubation] = useState<any>(null);
  const [deleteIncubationData, setDeleteIncubationData] = useState<any>(null);
  const { clutches, loading: clutchesLoading } = useClutchesData();
  const { incubations, loading: incubationDataLoading, optimisticDelete } = useIncubationData();
  const { toast } = useToast();

  // Memoize state to prevent unnecessary re-renders
  const state = useMemo(() => ({
    user: user?.id,
    isBreedingFormOpen,
    isIncubationFormOpen,
    editingIncubation: editingIncubation?.id,
    clutchesCount: clutches?.length,
    incubationsCount: incubations?.length,
    birdsCount: birds?.length
  }), [user?.id, isBreedingFormOpen, isIncubationFormOpen, editingIncubation?.id, clutches?.length, incubations?.length, birds?.length]);

  // Only log when state actually changes (for debugging)
  // console.log('🔄 useBreedingTabLogic - State Update:', state);

  const handleAddBreeding = useCallback(() => {
    setSelectedBreeding(null);
    setIsBreedingFormOpen(true);
  }, []);

  const handleEditBreeding = useCallback((breeding: any) => {
    setSelectedBreeding(breeding);
    setIsBreedingFormOpen(true);
  }, []);

  const handleCloseBreedingForm = useCallback(() => {
    setIsBreedingFormOpen(false);
    setSelectedBreeding(null);
  }, []);

  const handleSaveBreeding = useCallback(async (breedingData: any) => {
    if (!user) {
      toast({
        title: 'Hata',
        description: 'Kullanıcı girişi gerekli',
        variant: 'destructive',
      });
      return;
    }

    try {
      const mapped = {
        name: breedingData.incubationName,
        start_date: breedingData.startDate instanceof Date 
          ? breedingData.startDate.toISOString().slice(0, 10)
          : breedingData.startDate,
        female_bird_id: breedingData.motherId,
        male_bird_id: breedingData.fatherId,
        notes: breedingData.notes || null,
        user_id: user.id,
      };

      if (editingIncubation) {
        // Güncelleme
        const { error } = await supabase
          .from('incubations')
          .update(mapped)
          .eq('id', editingIncubation.id)
          .eq('user_id', user.id);

        if (error) {
          toast({
            title: 'Hata',
            description: 'Kuluçka güncellenirken bir hata oluştu.',
            variant: 'destructive',
          });
          return;
        }

        toast({
          title: 'Başarılı',
          description: 'Kuluçka başarıyla güncellendi.',
        });
      } else {
        // Yeni ekleme
        const { error } = await supabase
          .from('incubations')
          .insert([mapped]);

        if (error) {
          toast({
            title: 'Hata',
            description: 'Kuluçka eklenirken bir hata oluştu.',
            variant: 'destructive',
          });
          return;
        }

        toast({
          title: 'Başarılı',
          description: 'Kuluçka başarıyla eklendi.',
        });
      }

      handleCloseBreedingForm();
    } catch (error) {
      toast({
        title: 'Hata',
        description: 'Kuluçka kaydedilirken bir hata oluştu.',
        variant: 'destructive',
      });
    }
  }, [user, editingIncubation, toast, handleCloseBreedingForm]);

  const handleDeleteBreeding = useCallback(async (breedingId: string) => {
    if (!user) {
      toast({
        title: 'Hata',
        description: 'Kullanıcı girişi gerekli',
        variant: 'destructive',
      });
      return;
    }

    // Optimistic update - immediately remove from UI
    optimisticDelete(breedingId);

    try {
      const { error } = await supabase
        .from('incubations')
        .delete()
        .eq('id', breedingId)
        .eq('user_id', user.id);

      if (error) {
        // Revert optimistic update if database operation failed
        // The realtime subscription will handle this automatically
        toast({
          title: 'Hata',
          description: 'Kuluçka silinirken bir hata oluştu.',
          variant: 'destructive',
        });
        return;
      }

      toast({
        title: 'Başarılı',
        description: 'Kuluçka başarıyla silindi.',
      });
    } catch (error) {
      // Revert optimistic update if database operation failed
      // The realtime subscription will handle this automatically
      toast({
        title: 'Hata',
        description: 'Kuluçka silinirken bir hata oluştu.',
        variant: 'destructive',
      });
    }
  }, [user, toast, optimisticDelete]);

  // Incubation handlers
  const handleAddIncubation = useCallback(() => {
    setEditingIncubation(null);
    setIsIncubationFormOpen(true);
  }, []);

  const handleEditIncubation = useCallback((incubation: any) => {
    setEditingIncubation(incubation);
    setIsIncubationFormOpen(true);
  }, []);

  const handleDeleteIncubation = useCallback(async (incubationId: string) => {
    if (!user) {
      toast({
        title: 'Hata',
        description: 'Kullanıcı girişi gerekli',
        variant: 'destructive',
      });
      return;
    }

    // Optimistic update - immediately remove from UI
    optimisticDelete(incubationId);

    try {
      const { error } = await supabase
        .from('incubations')
        .delete()
        .eq('id', incubationId)
        .eq('user_id', user.id);

      if (error) {
        // Revert optimistic update if database operation failed
        // The realtime subscription will handle this automatically
        toast({
          title: 'Hata',
          description: 'Kuluçka silinirken bir hata oluştu.',
          variant: 'destructive',
        });
        return;
      }

      toast({
        title: 'Başarılı',
        description: 'Kuluçka başarıyla silindi.',
      });
    } catch (error) {
      // Revert optimistic update if database operation failed
      // The realtime subscription will handle this automatically
      toast({
        title: 'Hata',
        description: 'Kuluçka silinirken bir hata oluştu.',
        variant: 'destructive',
      });
    }
  }, [user, toast, optimisticDelete]);

  const handleIncubationFormSubmit = useCallback(async (data: any) => {
    if (!user) {
      toast({
        title: 'Hata',
        description: 'Kullanıcı girişi gerekli',
        variant: 'destructive',
      });
      return;
    }

    try {
      const mapped = {
        name: data.nestName || data.incubationName, // Her iki alanı da kontrol et
        start_date: data.pairDate ? new Date(data.pairDate).toISOString().slice(0, 10) : 
                   data.startDate instanceof Date 
                     ? data.startDate.toISOString().slice(0, 10)
                     : data.startDate,
        female_bird_id: data.femaleBirdId || data.motherId,
        male_bird_id: data.maleBirdId || data.fatherId,
        notes: data.notes || null,
        user_id: user.id,
      };

      if (editingIncubation) {
        // Güncelleme
        const { error } = await supabase
          .from('incubations')
          .update(mapped)
          .eq('id', editingIncubation.id)
          .eq('user_id', user.id);

        if (error) {
          toast({
            title: 'Hata',
            description: 'Kuluçka güncellenirken bir hata oluştu.',
            variant: 'destructive',
          });
          return;
        }

        toast({
          title: 'Başarılı',
          description: 'Kuluçka başarıyla güncellendi.',
        });
      } else {
        // Yeni ekleme
        const { error } = await supabase
          .from('incubations')
          .insert([mapped]);

        if (error) {
          toast({
            title: 'Hata',
            description: 'Kuluçka eklenirken bir hata oluştu.',
            variant: 'destructive',
          });
          return;
        }

        toast({
          title: 'Başarılı',
          description: 'Kuluçka başarıyla eklendi.',
        });
      }

      setIsIncubationFormOpen(false);
      setEditingIncubation(null);
    } catch (error) {
      toast({
        title: 'Hata',
        description: 'Kuluçka kaydedilirken bir hata oluştu.',
        variant: 'destructive',
      });
    }
  }, [user, editingIncubation, toast]);

  const handleIncubationFormCancel = useCallback(() => {
    setIsIncubationFormOpen(false);
    setEditingIncubation(null);
  }, []);

  const handleShowDeleteConfirmation = useCallback((incubation: any) => {
    setDeleteIncubationData(incubation);
  }, []);

  return {
    // State
    isBreedingFormOpen,
    selectedBreeding,
    clutches,
    birds,
    incubations,
    loading: clutchesLoading || incubationDataLoading,
    isIncubationFormOpen,
    editingIncubation,
    deleteIncubationData,
    setDeleteIncubationData,

    // Handlers
    handleAddBreeding,
    handleEditBreeding,
    handleCloseBreedingForm,
    handleSaveBreeding,
    handleDeleteBreeding,
    handleAddIncubation,
    handleEditIncubation,
    handleDeleteIncubation,
    handleIncubationFormSubmit,
    handleIncubationFormCancel,
    handleShowDeleteConfirmation,
  };
}; 