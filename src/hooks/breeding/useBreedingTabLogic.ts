import { useState, useCallback } from 'react';
import { useIncubationData } from '@/hooks/useIncubationData';
import { useIncubationOperations } from '@/hooks/useIncubationOperations';
import { useIncubationCrud } from '@/hooks/useIncubationCrud';
import { Bird } from '@/types';

interface Incubation {
  id: string;
  name: string;
  maleBirdId: string;
  femaleBirdId: string;
  startDate: string;
}

interface DeleteIncubationData {
  id: string;
  name: string;
  femaleBird: string;
  maleBird: string;
  startDate: string;
}

export const useBreedingTabLogic = (birds: Bird[]) => {
  const { deleteIncubation } = useIncubationOperations();
  const { addIncubation, updateIncubation } = useIncubationCrud();
  const { incubations, loading: incubationDataLoading, refetch } = useIncubationData();

  // Form state
  const [isIncubationFormOpen, setIsIncubationFormOpen] = useState(false);
  const [editingIncubation, setEditingIncubation] = useState<Incubation | null>(null);
  const [deleteIncubationData, setDeleteIncubationData] = useState<DeleteIncubationData | null>(null);
  
  // Egg management state
  const [selectedClutchForEggs, setSelectedClutchForEggs] = useState<Incubation | null>(null);

  const handleAddIncubation = useCallback(() => {
    setEditingIncubation(null);
    setIsIncubationFormOpen(true);
  }, []);

  const handleEditIncubation = useCallback((incubation: Incubation) => {
    setEditingIncubation(incubation);
    setIsIncubationFormOpen(true);
  }, []);

  const handleDeleteIncubation = useCallback(async (incubationId: string) => {
    const success = await deleteIncubation(incubationId);
    if (success) {
      setDeleteIncubationData(null);
      refetch();
    }
  }, [deleteIncubation, refetch]);

  const handleIncubationFormSubmit = useCallback(async (formData: any) => {
    try {
      let success = false;
      
      if (editingIncubation) {
        // Update existing incubation
        const updateData = {
          incubationName: formData.nestName,
          motherId: formData.femaleBirdId,
          fatherId: formData.maleBirdId,
          startDate: new Date(formData.pairDate),
          enableNotifications: true,
          notes: formData.notes || ''
        };
        success = await updateIncubation(editingIncubation.id, updateData);
      } else {
        // Create new incubation
        const createData = {
          incubationName: formData.nestName,
          motherId: formData.femaleBirdId,
          fatherId: formData.maleBirdId,
          startDate: new Date(formData.pairDate),
          enableNotifications: true,
          notes: formData.notes || ''
        };
        success = await addIncubation(createData);
      }
      
      if (success) {
        setIsIncubationFormOpen(false);
        setEditingIncubation(null);
        refetch();
      }
    } catch (error) {
      console.error('Incubation form submit error:', error);
      // Error handling is done in the respective hooks
    }
  }, [editingIncubation, updateIncubation, addIncubation, refetch]);

  const handleIncubationFormCancel = useCallback(() => {
    setIsIncubationFormOpen(false);
    setEditingIncubation(null);
  }, []);

  const handleShowDeleteConfirmation = useCallback((incubation: Incubation) => {
    const maleBird = birds.find(b => b.id === incubation.maleBirdId);
    const femaleBird = birds.find(b => b.id === incubation.femaleBirdId);
    
    setDeleteIncubationData({
      id: incubation.id,
      name: incubation.name,
      femaleBird: femaleBird?.name || 'Bilinmeyen',
      maleBird: maleBird?.name || 'Bilinmeyen',
      startDate: new Date(incubation.startDate).toLocaleDateString('tr-TR')
    });
  }, [birds]);

  const handleOpenEggManagement = useCallback((clutch: Incubation) => {
    setSelectedClutchForEggs(clutch);
  }, []);

  const handleCloseEggManagement = useCallback(() => {
    setSelectedClutchForEggs(null);
  }, []);

  return {
    incubations,
    incubationDataLoading,
    isIncubationFormOpen,
    editingIncubation,
    deleteIncubationData,
    setDeleteIncubationData,
    selectedClutchForEggs,
    handleAddIncubation,
    handleEditIncubation,
    handleDeleteIncubation,
    handleIncubationFormSubmit,
    handleIncubationFormCancel,
    handleShowDeleteConfirmation,
    handleOpenEggManagement,
    handleCloseEggManagement,
    refetch
  };
};
