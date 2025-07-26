import React, { useState, useEffect, useCallback } from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { useEggManagement } from '@/hooks/useEggManagement';
import { EggFormData, EggWithClutch } from '@/types/egg';
import EggList from './EggList';
import EggForm from './EggForm';

interface EggManagementContentProps {
  clutchId: string;
  autoOpenForm: boolean;
  onNavigateToBreeding?: () => void;
}

const EggManagementContent: React.FC<EggManagementContentProps> = ({
  clutchId,
  autoOpenForm,
  onNavigateToBreeding
}) => {
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingEgg, setEditingEgg] = useState<EggWithClutch | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [hasAutoOpened, setHasAutoOpened] = useState(false);

  const {
    eggs,
    loading,
    error,
    addEgg,
    updateEgg,
    deleteEgg,
    getNextEggNumber,
    refetch
  } = useEggManagement(clutchId);

  const actualEggCount = eggs.length;
  const nextEggNumber = getNextEggNumber();

  // Auto-open form only if no eggs exist and hasn't been auto-opened before
  useEffect(() => {
    if (autoOpenForm && !loading && actualEggCount === 0 && !isFormOpen && !hasAutoOpened) {
      setIsFormOpen(true);
      setHasAutoOpened(true);
    }
  }, [autoOpenForm, loading, actualEggCount, isFormOpen, hasAutoOpened]);

  const handleAddEgg = useCallback(() => {
    setEditingEgg(null);
    setIsFormOpen(true);
  }, []);

  const handleEditEgg = useCallback((egg: EggWithClutch) => {
    setEditingEgg(egg);
    setIsFormOpen(true);
  }, []);

  const handleDeleteEgg = useCallback(async (eggId: string, _eggNumber: number) => {
    console.log('🗑️ EggManagementContent.handleDeleteEgg - Yumurta silme başlıyor:', {
      eggId,
      eggNumber: _eggNumber,
      clutchId
    });
    
    const success = await deleteEgg(eggId);
    
    console.log('📊 EggManagementContent.handleDeleteEgg - Silme sonucu:', {
      success,
      eggId
    });
    
    // Realtime subscription will handle the UI update automatically
    // No need to navigate or refresh manually
  }, [deleteEgg, clutchId]);

  const handleSubmit = useCallback(async (eggData: EggFormData): Promise<boolean> => {
    setIsSubmitting(true);
    
    try {
      let success = false;
      
      if (editingEgg) {
        success = await updateEgg(editingEgg.id, eggData);
      } else {
        const eggDataWithClutchId = {
          ...eggData,
          clutchId: clutchId
        };
        success = await addEgg(eggDataWithClutchId);
      }
      
      if (success) {
        setIsFormOpen(false);
        setEditingEgg(null);
        
        // Navigate to breeding tab after adding an egg (not when editing)
        if (!editingEgg && onNavigateToBreeding) {
          setTimeout(() => {
            window.dispatchEvent(new CustomEvent('navigateToBreeding'));
          }, 500);
        }
        
        // Trigger immediate refresh
        setTimeout(() => {
          refetch();
        }, 100);
      }
      
      return success;
    } catch (error) {
      console.error('Error in handleSubmit:', error);
      return false;
    } finally {
      setIsSubmitting(false);
    }
  }, [editingEgg, updateEgg, addEgg, clutchId, onNavigateToBreeding, refetch]);

  const handleCancel = useCallback(() => {
    setIsFormOpen(false);
    setEditingEgg(null);
  }, []);

  // Throw error to be caught by ErrorBoundary
  if (error) {
    throw new Error(error);
  }

  return (
    <>
      {/* Egg List - Always show, even when form is open */}
      <Card>
        <CardContent className="p-6">
          <EggList
            eggs={eggs}
            loading={loading}
            onAddEgg={handleAddEgg}
            onEditEgg={handleEditEgg}
            onDeleteEgg={handleDeleteEgg}
          />
        </CardContent>
      </Card>

      {/* Egg Form Modal - Only show when specifically requested */}
      {isFormOpen && (
        <EggForm
          clutchId={clutchId}
          editingEgg={editingEgg}
          nextEggNumber={nextEggNumber}
          onSubmit={handleSubmit}
          onCancel={handleCancel}
          isSubmitting={isSubmitting}
        />
      )}
    </>
  );
};

export default EggManagementContent;
