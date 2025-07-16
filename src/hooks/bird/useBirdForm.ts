import { useState } from 'react';
import { useToast } from '@/hooks/use-toast';

interface Bird {
  id: string;
  name: string;
  gender: 'male' | 'female' | 'unknown';
  color?: string;
  birthDate?: string;
  ringNumber?: string;
  photo?: string;
  healthNotes?: string;
  motherId?: string;
  fatherId?: string;
}

export const useBirdForm = (
  birds: Bird[],
  addBird: (bird: Bird) => void,
  editBird: (bird: Bird) => void,
  deleteBird: (birdId: string) => void
) => {
  const [isBirdFormOpen, setIsBirdFormOpen] = useState(false);
  const [editingBird, setEditingBird] = useState<Bird | null>(null);
  const { toast } = useToast();

  const handleAddBird = () => {
    setEditingBird(null);
    setIsBirdFormOpen(true);
  };

  const handleEditBird = (bird: Bird) => {
    setEditingBird(bird);
    setIsBirdFormOpen(true);
  };

  const handleSaveBird = (data: {
    name?: string;
    gender?: 'male' | 'female' | 'unknown';
    color?: string;
    birthDate?: Date;
    ringNumber?: string;
    healthNotes?: string;
    photo?: string;
    motherId?: string;
    fatherId?: string;
  }) => {
    try {
      // Ring number duplicate kontrolü
      if (data.ringNumber && data.ringNumber.trim()) {
        const existingBird = birds.find(bird => 
          bird.ringNumber === data.ringNumber && 
          bird.id !== editingBird?.id
        );
        
        if (existingBird) {
          toast({
            title: 'Hata',
            description: 'Bu halka numarası zaten kullanılıyor.',
            variant: 'destructive'
          });
          return;
        }
      }

      const birdData: Bird = {
        id: editingBird?.id || Date.now().toString(),
        name: data.name || '',
        gender: data.gender || 'unknown',
        color: data.color || '',
        birthDate: data.birthDate ? data.birthDate.toISOString().split('T')[0] : '',
        ringNumber: data.ringNumber || '',
        photo: data.photo || '',
        healthNotes: data.healthNotes || '',
        motherId: data.motherId || '',
        fatherId: data.fatherId || ''
      };

      if (editingBird) {
        editBird(birdData);
        toast({
          title: 'Başarılı',
          description: `"${birdData.name}" adlı kuş başarıyla güncellendi.`,
        });
      } else {
        addBird(birdData);
        toast({
          title: 'Başarılı',
          description: `"${birdData.name}" adlı kuş başarıyla eklendi.`,
        });
      }
      
      setIsBirdFormOpen(false);
      setEditingBird(null);
    } catch (_error) {
      toast({
        title: 'Hata',
        description: 'İşlem sırasında bir hata oluştu.',
        variant: 'destructive'
      });
    }
  };

  const handleCloseBirdForm = () => {
    setIsBirdFormOpen(false);
    setEditingBird(null);
  };

  const handleDeleteBird = (birdId: string) => {
    deleteBird(birdId);
  };

  return {
    isBirdFormOpen,
    editingBird,
    handleAddBird,
    handleEditBird,
    handleSaveBird,
    handleCloseBirdForm,
    handleDeleteBird
  };
};
