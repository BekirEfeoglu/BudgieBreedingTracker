import React, { useState, Suspense } from 'react';
import { useAuth } from '@/hooks/useAuth';
import LoadingSpinner from '@/components/ui/loading-spinner';
import { Bird, Chick, Egg } from '@/types';

// Lazy load tab components
const BirdsTab = React.lazy(() => import('@/components/tabs/BirdsTab'));
const BreedingTab = React.lazy(() => import('@/components/tabs/BreedingTab'));
const ChicksTab = React.lazy(() => import('@/components/tabs/ChicksTab'));
const HomeTab = React.lazy(() => import('@/components/tabs/HomeTab'));
const GenealogyView = React.lazy(() => import('@/components/GenealogyView'));
const CalendarTab = React.lazy(() => import('@/components/tabs/CalendarTab'));
const PremiumPage = React.lazy(() => import('@/components/premium/PremiumPage'));

const SettingsTab = React.lazy(() => import('@/components/tabs/SettingsTab'));

interface TabContentProps {
  activeTab: string;
  birds: Bird[];
  eggs: Egg[];
  chicks: Chick[];
  incubations: any[];
  editingChick: Chick | null;
  isChickFormOpen: boolean;
  onAddBird: () => void;
  onEditBird: (bird: Bird) => void;
  onAddEgg: (breedingId: string) => void;
  onEditChick: (chick: Chick) => void;
  onSaveChick: (chickData: Partial<Chick>) => void;
  onCloseChickForm: () => void;
  onDeleteBird: (birdId: string) => void;
  onDeleteChick: (chickId: string) => void;
  onEditEgg: (breedingId: string, egg: Egg) => void;
  onDeleteEgg: (breedingId: string, eggId: string) => void;
  onEggStatusChange: (breedingId: string, eggId: string, status: Egg['status'], hatchDate?: string) => void;
  onTabChange: (tab: string) => void;
  onAddChick: () => void;
  isLoading: boolean;
  promoteChickToBird: (chick: Chick) => void;
}

const TabContent = React.memo(({ 
  activeTab, 
  birds, 
  eggs,
  chicks,
  incubations,
  editingChick,
  isChickFormOpen,
  onAddBird,
  onEditBird,
  onAddEgg,
  onEditChick,
  onSaveChick,
  onCloseChickForm,
  onDeleteBird,
  onDeleteChick,
  onEditEgg,
  onDeleteEgg,
  onEggStatusChange,
  onTabChange,
  onAddChick,
  isLoading,
  promoteChickToBird
}: TabContentProps) => {
  const { user, loading } = useAuth();

  // Show loading state
  if (loading || isLoading) {
    return <LoadingSpinner />;
  }

  const renderTabContent = () => {
    switch (activeTab) {
      case 'home':
        return (
          <HomeTab
            birds={birds}
            eggs={eggs}
            chicks={chicks}
            incubations={incubations}
            isLoading={isLoading}
            onAddBird={onAddBird}
            onTabChange={onTabChange}
          />
        );

      case 'birds':
        return (
          <BirdsTab
            birds={birds}
            onAddBird={onAddBird}
            onEditBird={onEditBird}
            onDeleteBird={onDeleteBird}
            isLoading={isLoading}
          />
        );

      case 'breeding':
        return (
          <BreedingTab
            birds={birds}
            onAddEgg={onAddEgg}
            onEditEgg={onEditEgg}
            onDeleteEgg={onDeleteEgg}
            onEggStatusChange={onEggStatusChange}
            isLoading={isLoading}
          />
        );

      case 'chicks':
        return (
          <ChicksTab
            chicks={chicks}
            birds={birds}
            editingChick={editingChick}
            isChickFormOpen={isChickFormOpen}
            onAddChick={onAddChick}
            onEditChick={onEditChick}
            onSaveChick={onSaveChick}
            onCloseChickForm={onCloseChickForm}
            onDeleteChick={onDeleteChick}
            promoteChickToBird={promoteChickToBird}
            isLoading={isLoading}
          />
        );

      case 'genealogy':
        return (
          <GenealogyView 
            birds={birds} 
            chicks={chicks}
            onBirdSelect={(bird) => {
              // Soyağacı sekmesinde kuş seçildiğinde sadece soyağacı verilerini göster
              // Düzenleme modu açılmıyor
              if ('hatchDate' in bird) {
                // Chick seçildi - sadece soyağacı verilerini göster
                // console.log('Selected chick:', bird.name);
              } else {
                // Bird seçildi - sadece soyağacı verilerini göster
                // console.log('Selected bird:', bird.name);
              }
            }}
            isLoading={isLoading}
          />
        );

      case 'calendar':
        return (
          <CalendarTab
            birds={birds}
            eggs={eggs}
            chicks={chicks}
            incubations={incubations}
            isLoading={isLoading}
          />
        );

      case 'premium':
        return (
          <PremiumPage />
        );

      case 'settings':
        return (
          <SettingsTab
            isLoading={isLoading}
          />
        );

      default:
        return (
          <HomeTab
            birds={birds}
            eggs={eggs}
            chicks={chicks}
            incubations={incubations}
            isLoading={isLoading}
            onAddBird={onAddBird}
            onTabChange={onTabChange}
          />
        );
    }
  };

  return (
    <div className="min-h-screen bg-background">
      <Suspense fallback={<LoadingSpinner />}>
        {renderTabContent()}
      </Suspense>
    </div>
  );
});

TabContent.displayName = 'TabContent';

export default TabContent;
