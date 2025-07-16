import { useState } from 'react';
import { toast } from '@/hooks/use-toast';
import { Bird } from '@/types';

interface UseBirdManagementReturn {
  birds: Bird[];
  setBirds: React.Dispatch<React.SetStateAction<Bird[]>>;
  editingBird: Bird | null;
  isBirdFormOpen: boolean;
  handleAddBird: () => void;
  handleEditBird: (bird: Bird) => void;
  handleDeleteBird: (birdId: string) => void;
  handleSaveBird: (birdData: Partial<Bird> & { birthDate?: Date }) => void;
  handleCloseBirdForm: () => void;
}

export const useBirdManagement = (initialBirds: Bird[]): UseBirdManagementReturn => {
  const [birds, setBirds] = useState<Bird[]>(initialBirds);
  const [editingBird, setEditingBird] = useState<Bird | null>(null);
  const [isBirdFormOpen, setIsBirdFormOpen] = useState(false);

  const handleAddBird = () => {
    setEditingBird(null);
    setIsBirdFormOpen(true);
  };

  const handleEditBird = (bird: Bird) => {
    setEditingBird(bird);
    setIsBirdFormOpen(true);
  };

  const handleDeleteBird = (birdId: string) => {
    const birdToDelete = birds.find(b => b.id === birdId);
    setBirds(prev => prev.filter(bird => bird.id !== birdId));
    
    toast({
      title: 'Başarılı',
      description: `"${birdToDelete?.name}" adlı kuş başarıyla silindi.`,
    });
  };

  const handleSaveBird = (birdData: Partial<Bird> & { birthDate?: Date }) => {
    if (editingBird) {
      const updatedBird = {
        ...editingBird,
        ...birdData,
        birthDate: birdData.birthDate ? birdData.birthDate.toISOString().split('T')[0] : editingBird.birthDate
      };
      
      setBirds(prev => prev.map(bird => 
        bird.id === editingBird.id ? updatedBird : bird
      ));
      
      toast({
        title: 'Başarılı',
        description: `"${updatedBird.name}" adlı kuş başarıyla güncellendi.`,
      });
    } else {
      const newBird = {
        id: Date.now().toString(),
        ...birdData,
        birthDate: birdData.birthDate ? birdData.birthDate.toISOString().split('T')[0] : undefined
      };
      
      setBirds(prev => [...prev, newBird]);
      
      toast({
        title: 'Başarılı',
        description: `"${newBird.name}" adlı kuş başarıyla eklendi.`,
      });
    }
    
    setIsBirdFormOpen(false);
    setEditingBird(null);
  };

  const handleCloseBirdForm = () => {
    setIsBirdFormOpen(false);
    setEditingBird(null);
  };

  return {
    birds,
    setBirds,
    editingBird,
    isBirdFormOpen,
    handleAddBird,
    handleEditBird,
    handleDeleteBird,
    handleSaveBird,
    handleCloseBirdForm
  };
};
