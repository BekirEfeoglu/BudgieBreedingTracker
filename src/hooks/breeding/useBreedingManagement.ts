import { useBreedingOperations } from '@/hooks/breeding/useBreedingOperations';
import { useEggOperations } from '@/hooks/useEggOperations';
import { useChickOperations } from '@/hooks/chick/useChickOperations';
import { Bird, Chick, Breeding } from '@/types';

export const useBreedingManagement = (
  initialBreeding: Breeding[],
  initialChicks: Chick[],
  birds: Bird[]
) => {
  // Use breeding operations hook
  const {
    breeding,
    setBreeding,
    editingBreeding,
    setEditingBreeding,
    isBreedingFormOpen,
    handleAddBreeding,
    handleEditBreeding,
    handleDeleteBreeding,
    handleSaveBreeding,
    handleCloseBreedingForm
  } = useBreedingOperations(initialBreeding, birds);

  // Use chick operations hook
  const {
    chicks,
    setChicks,
    editingChick,
    isChickFormOpen,
    handleEditChick,
    handleSaveChick,
    handleCloseChickForm,
    handleDeleteChick
  } = useChickOperations(initialChicks);

  // Use egg operations hook
  const {
    handleAddEgg,
    handleEditEgg,
    handleDeleteEgg,
    handleEggStatusChange
  } = useEggOperations(
    breeding,
    setBreeding,
    setEditingBreeding,
    () => {}, // No need for setEditingEgg
    handleCloseBreedingForm,
    birds,
    chicks,
    setChicks
  );

  return {
    breeding,
    chicks,
    editingBreeding,
    editingChick,
    isBreedingFormOpen,
    isChickFormOpen,
    handleAddBreeding,
    handleEditBreeding,
    handleDeleteBreeding,
    handleAddEgg,
    handleEditEgg,
    handleDeleteEgg,
    handleEggStatusChange,
    handleSaveBreeding,
    handleCloseBreedingForm,
    handleEditChick,
    handleSaveChick,
    handleCloseChickForm,
    handleDeleteChick
  };
};
