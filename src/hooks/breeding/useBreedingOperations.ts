import { useState } from 'react';
import { toast } from '@/hooks/use-toast';

interface Bird {
  id: string;
  name: string;
}

interface BreedingData {
  nestName: string;
  femaleBirdId: string;
  maleBirdId: string;
  startDate: Date;
  eggs: unknown[];
}

interface BreedingRecord {
  id: string;
  nestName: string;
  maleBird: string;
  femaleBird: string;
  startDate: string;
  eggs: unknown[];
}

export const useBreedingOperations = (
  initialBreeding: BreedingRecord[],
  birds: Bird[]
) => {
  const [breeding, setBreeding] = useState<BreedingRecord[]>(initialBreeding);
  const [editingBreeding, setEditingBreeding] = useState<BreedingRecord | null>(null);
  const [isBreedingFormOpen, setIsBreedingFormOpen] = useState(false);

  const handleAddBreeding = () => {
    setEditingBreeding(null);
    setIsBreedingFormOpen(true);
  };

  const handleEditBreeding = (breedingRecord: BreedingRecord) => {
    setEditingBreeding(breedingRecord);
    setIsBreedingFormOpen(true);
  };

  const handleDeleteBreeding = (breedingId: string) => {
    const breedingToDelete = breeding.find(b => b.id === breedingId);
    setBreeding(prev => prev.filter(b => b.id !== breedingId));
    
    toast({
      title: 'Başarılı',
      description: `"${breedingToDelete?.nestName}" adlı kuluçka başarıyla silindi.`,
    });
  };

  const handleSaveBreeding = (breedingData: BreedingData) => {
    const femaleBird = birds.find(b => b.id === breedingData.femaleBirdId);
    const maleBird = birds.find(b => b.id === breedingData.maleBirdId);
    
    if (editingBreeding) {
      const updatedBreeding: BreedingRecord = {
        ...editingBreeding,
        nestName: breedingData.nestName,
        maleBird: maleBird?.name || 'Bilinmeyen',
        femaleBird: femaleBird?.name || 'Bilinmeyen',
        startDate: breedingData.startDate ? breedingData.startDate.toISOString().substring(0, 10) : editingBreeding.startDate || new Date().toISOString().substring(0, 10),
        eggs: breedingData.eggs || []
      };
      
      setBreeding(prev => prev.map(b => 
        b.id === editingBreeding.id ? updatedBreeding : b
      ));
      
      toast({
        title: 'Başarılı',
        description: `"${updatedBreeding.nestName}" adlı kuluçka başarıyla güncellendi.`,
      });
    } else {
      const newBreeding: BreedingRecord = {
        id: Date.now().toString(),
        nestName: breedingData.nestName,
        maleBird: maleBird?.name || 'Bilinmeyen',
        femaleBird: femaleBird?.name || 'Bilinmeyen',
        startDate: breedingData.startDate ? breedingData.startDate.toISOString().split('T')[0] : new Date().toISOString().split('T')[0],
        eggs: breedingData.eggs || []
      };
      
      setBreeding(prev => [...prev, newBreeding]);
      
      toast({
        title: 'Başarılı',
        description: `"${newBreeding.nestName}" adlı kuluçka başarıyla eklendi.`,
      });
    }
    
    setIsBreedingFormOpen(false);
    setEditingBreeding(null);
  };

  const handleCloseBreedingForm = () => {
    setIsBreedingFormOpen(false);
    setEditingBreeding(null);
  };

  return {
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
  };
};
