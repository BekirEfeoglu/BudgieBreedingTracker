import React, { memo, useCallback } from 'react';
import BreedingCard from '@/components/BreedingCard';
import { BreedingCardSkeleton } from '@/components/ui/breeding-skeleton';
import { BreedingRecord, Egg } from '@/types';
import { useLanguage } from '@/contexts/LanguageContext';

interface BreedingTabContentProps {
  allBreedingRecords: BreedingRecord[];
  isLoading: boolean;
  incubationDataLoading: boolean;
  onEdit: (record: BreedingRecord) => void;
  onDelete: (recordId: string) => void;
  onAddEgg: (breedingId: string) => void;
  onEditEgg: (breedingId: string, egg: Egg) => void;
  onDeleteEgg: (breedingId: string, eggId: string) => void;
  onEggStatusChange: (breedingId: string, eggId: string, newStatus: string) => void;
}

const BreedingTabContent = memo(({
  allBreedingRecords,
  isLoading,
  incubationDataLoading,
  onEdit,
  onDelete,
  onAddEgg,
  onEditEgg,
  onDeleteEgg,
  onEggStatusChange
}: BreedingTabContentProps) => {
  const { t } = useLanguage();

  const handleEdit = useCallback((record: BreedingRecord) => {
    onEdit(record);
  }, [onEdit]);

  const handleDelete = useCallback((recordId: string) => {
    onDelete(recordId);
  }, [onDelete]);

  const handleAddEgg = useCallback((breedingId: string) => {
    onAddEgg(breedingId);
  }, [onAddEgg]);

  const handleEditEgg = useCallback((breedingId: string, egg: Egg) => {
    onEditEgg(breedingId, egg);
  }, [onEditEgg]);

  const handleDeleteEgg = useCallback((breedingId: string, eggId: string) => {
    console.log('🗑️ BreedingTabContent.handleDeleteEgg - Yumurta silme başlıyor:', {
      breedingId,
      eggId
    });
    onDeleteEgg(breedingId, eggId);
  }, [onDeleteEgg]);

  const handleEggStatusChange = useCallback((breedingId: string, eggId: string, newStatus: string) => {
    onEggStatusChange(breedingId, eggId, newStatus);
  }, [onEggStatusChange]);

  if (isLoading || incubationDataLoading) {
    return (
      <div 
        className="grid gap-4" 
        role="status" 
        aria-label={t('breeding.loadingRecords')}
      >
        {Array.from({ length: 3 }).map((_, index) => (
          <BreedingCardSkeleton key={index} />
        ))}
      </div>
    );
  }

  return (
    <div 
      className="grid gap-4" 
      role="region" 
      aria-label={t('breeding.recordsList')}
      aria-live="polite"
      aria-atomic="false"
    >
      {allBreedingRecords.map((record) => (
        <BreedingCard 
          key={record.id} 
          breeding={record} 
          onEdit={() => handleEdit(record)}
          onAddEgg={handleAddEgg}
          onEditEgg={handleEditEgg}
          onDelete={() => handleDelete(record.id)}
          onDeleteEgg={handleDeleteEgg}
          onEggStatusChange={handleEggStatusChange}
        />
      ))}
    </div>
  );
});

BreedingTabContent.displayName = 'BreedingTabContent';

export default BreedingTabContent;
