import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { Card } from '@/components/ui/card';
import { toast } from '@/hooks/use-toast';
import { useLanguage } from '@/contexts/LanguageContext';
import BreedingCardHeader from '@/components/breeding/BreedingCardHeader';
import BreedingCardProgress from '@/components/breeding/BreedingCardProgress';
import BreedingCardEggs from '@/components/breeding/BreedingCardEggs';
import BreedingCardFooter from '@/components/breeding/BreedingCardFooter';
import EggManagement from '@/components/eggs/EggManagement';
import { useEggCrud } from '@/hooks/egg/useEggCrud';
import { useEggData } from '@/hooks/egg/useEggData';
import { EggFormData } from '@/types/egg';

import ComponentErrorBoundary from '@/components/errors/ComponentErrorBoundary';
import { Egg, BreedingRecord } from '@/types';

interface BreedingCardProps {
  breeding: BreedingRecord;
  onEdit: (breeding: BreedingRecord) => void;
  onAddEgg: (breedingId: string) => void;
  onEditEgg: (breedingId: string, egg: Egg) => void;
  onDeleteEgg: (breedingId: string, eggId: string) => void;
  onDelete: (breedingId: string) => void;
  onEggStatusChange: (breedingId: string, eggId: string, newStatus: string) => void;
}

const BreedingCard = React.memo(({ 
  breeding, 
  onEdit, 
  onAddEgg, 
  onEditEgg, 
  onDeleteEgg, 
  onDelete,
  onEggStatusChange
}: BreedingCardProps) => {
  const { t } = useLanguage();
  const [showEggManagement, setShowEggManagement] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const { addEgg } = useEggCrud();
  
  // Use useEggData to get real-time egg count with proper refresh
  const { eggs: realTimeEggs, loading: eggsLoading, refetchEggs } = useEggData(breeding.id);

  // Force refresh eggs when component mounts or breeding changes
  useEffect(() => {
    if (refetchEggs) {
    refetchEggs();
    }
  }, [breeding.id, refetchEggs]);

  const getNextEggNumber = useCallback(() => {
    // Use real-time eggs if available, otherwise fall back to breeding.eggs
    const eggsToUse = realTimeEggs.length > 0 ? realTimeEggs : breeding.eggs;
    if (eggsToUse.length === 0) return 1;
    const maxNumber = Math.max(...eggsToUse.map(egg => {
      // Handle both EggWithClutch and Egg types
      if ('eggNumber' in egg) {
        return egg.eggNumber || 0;
      } else if ('number' in egg) {
        return egg.number || 0;
      }
      return 0;
    }));
    return maxNumber + 1;
  }, [realTimeEggs, breeding.eggs]);

  const handleDeleteBreeding = useCallback(() => {
    try {
      onDelete(breeding.id);
      toast({
        title: t('breeding.success'),
        description: `"${breeding.nestName}" ${t('breeding.incubationDeleted')}`,
      });
    } catch (error) {
      console.error('Error deleting breeding record:', error);
      toast({
        title: t('breeding.error'),
        description: t('common.deleteError'),
        variant: 'destructive',
      });
    }
  }, [onDelete, breeding.id, breeding.nestName, t]);

  const handleEditBreeding = useCallback(() => {
    try {
      onEdit(breeding);
    } catch (error) {
      console.error('Error editing breeding record:', error);
      toast({
        title: t('breeding.error'),
        description: t('common.editError'),
        variant: 'destructive',
      });
    }
  }, [onEdit, breeding, t]);

  const handleDeleteEgg = useCallback((eggId: string, eggNumber: number) => {
    
    try {
      onDeleteEgg(breeding.id, eggId);
      
      // Force refresh eggs after deletion since realtime subscription might not work
      setTimeout(() => {
        if (refetchEggs) {
          refetchEggs();
        }
      }, 500);
      
      toast({
        title: t('breeding.success'),
        description: `${eggNumber}. ${t('breeding.eggDeleted')}`,
      });
    } catch (error) {
      console.error('❌ BreedingCard.handleDeleteEgg - Yumurta silme hatası:', error);
      toast({
        title: t('breeding.error'),
        description: t('common.deleteError'),
        variant: 'destructive',
      });
    }
  }, [onDeleteEgg, breeding.id, breeding.nestName, refetchEggs, t]);

  const handleEggStatusChange = useCallback((eggId: string, newStatus: string) => {
    try {
      onEggStatusChange(breeding.id, eggId, newStatus);
      // Force refresh after status change
      setTimeout(() => {
        if (refetchEggs) {
        refetchEggs();
        }
      }, 500);
    } catch (error) {
      console.error('Error changing egg status:', error);
      toast({
        title: t('breeding.error'),
        description: t('common.updateError'),
        variant: 'destructive',
      });
    }
  }, [onEggStatusChange, breeding.id, refetchEggs, t]);

  const handleAddEggClick = useCallback(() => {
    // Önce parent component'in onAddEgg fonksiyonunu çağır
    onAddEgg(breeding.id);
    // Sonra local state'i güncelle
    setShowEggManagement(true);
  }, [breeding.id, breeding.nestName, onAddEgg]);

  const handleBackFromEggManagement = useCallback(() => {
    setShowEggManagement(false);
    // Force refresh when coming back from egg management
    setTimeout(() => {
      if (refetchEggs) {
      refetchEggs();
      }
    }, 100);
  }, [refetchEggs]);

  const handleNavigateToBreeding = useCallback(() => {
    setShowEggManagement(false);
    // Trigger a custom event to notify the parent components
    window.dispatchEvent(new CustomEvent('navigateToBreeding'));
  }, []);

  // Add navigation to breeding tab after egg addition
  const handleEggAdded = useCallback(() => {
    // Trigger a custom event to notify the parent components
    window.dispatchEvent(new CustomEvent('navigateToBreeding'));
  }, []);

  // Memoize display eggs to avoid recalculation
  const displayEggs = useMemo(() => {
    const fallbackDate = new Date().toISOString().split('T')[0];
    const mapEgg = (egg: any): Egg => ({
      id: egg.id,
      breedingId: egg.breedingId || breeding.id,
      nestId: egg.nestId,
      layDate: egg.layDate || egg.dateAdded || fallbackDate,
      status: egg.status,
      hatchDate: egg.hatchDate,
      notes: egg.notes,
      chickId: egg.chickId,
      number: egg.number || egg.eggNumber || 1,
      motherId: egg.motherId,
      fatherId: egg.fatherId,
      dateAdded: egg.dateAdded || egg.layDate || fallbackDate,
    });
    
    // Use real-time eggs if available and not loading, otherwise fall back to breeding.eggs
    const eggsToUse = !eggsLoading && realTimeEggs.length > 0 ? realTimeEggs : breeding.eggs;
    
    // No need to filter since useEggData now returns only eggs for this breeding
    const filteredEggs = eggsToUse;
    
    return filteredEggs.map(mapEgg);
  }, [realTimeEggs, breeding.eggs, breeding.id, eggsLoading]);

  // If EggManagement is open, render it instead of the card
  if (showEggManagement) {
    return (
      <ComponentErrorBoundary>
        <EggManagement
          clutchId={breeding.id}
          clutchName={breeding.nestName}
          onBack={handleBackFromEggManagement}
          autoOpenForm={true}
          onNavigateToBreeding={handleNavigateToBreeding}
        />
      </ComponentErrorBoundary>
    );
  }

  return (
    <ComponentErrorBoundary>
      <Card 
        className="budgie-card p-4 animate-slide-up" 
        role="article" 
        aria-label={`${t('breeding.nest')}: ${breeding.nestName}`}
        tabIndex={0}
        onKeyDown={(e) => {
          if (e.key === 'Enter' || e.key === ' ') {
            e.preventDefault();
            onEdit(breeding);
          }
        }}
      >
        <BreedingCardHeader
          breeding={breeding}
          onEdit={handleEditBreeding}
          onDelete={handleDeleteBreeding}
        />

        <BreedingCardProgress startDate={breeding.startDate} />

        <BreedingCardEggs
          eggs={displayEggs}
          breedingId={breeding.id}
          onAddEgg={handleAddEggClick}
          onEditEgg={onEditEgg}
          onDeleteEgg={handleDeleteEgg}
          onEggStatusChange={handleEggStatusChange}
        />

        <BreedingCardFooter startDate={breeding.startDate} />
      </Card>
    </ComponentErrorBoundary>
  );
});

BreedingCard.displayName = 'BreedingCard';

export default BreedingCard;
