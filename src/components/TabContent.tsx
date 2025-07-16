import React, { useState, Suspense } from 'react';
import { useAuth } from '@/hooks/useAuth';
import LoadingSpinner from '@/components/ui/loading-spinner';
import { Bird, Chick, Breeding, Egg } from '@/types';

// Lazy load tab components
const BirdsTab = React.lazy(() => import('@/components/tabs/BirdsTab'));
const BreedingTab = React.lazy(() => import('@/components/tabs/BreedingTab'));
const ChicksTab = React.lazy(() => import('@/components/tabs/ChicksTab'));
const HomeTab = React.lazy(() => import('@/components/tabs/HomeTab'));
const GenealogyView = React.lazy(() => import('@/components/GenealogyView'));
const CalendarTab = React.lazy(() => import('@/components/tabs/CalendarTab'));
const ProfileSettings = React.lazy(() => import('@/components/ProfileSettings'));
const SettingsTab = React.lazy(() => import('@/components/tabs/SettingsTab'));

interface TabContentProps {
  activeTab: string;
  birds: Bird[];
  breeding: Breeding[];
  eggs: Egg[];
  chicks: Chick[];
  incubations: any[];
  editingChick: Chick | null;
  isChickFormOpen: boolean;
  onAddBird: () => void;
  onAddBreeding: () => void;
  onEditBird: (bird: Bird) => void;
  onEditBreeding: (breeding: Breeding) => void;
  onAddEgg: (breedingId: string) => void;
  onEditChick: (chick: Chick) => void;
  onSaveChick: (chickData: Partial<Chick>) => void;
  onCloseChickForm: () => void;
  onDeleteBird: (birdId: string) => void;
  onDeleteBreeding: (breedingId: string) => void;
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
  breeding, 
  eggs,
  chicks,
  incubations,
  editingChick,
  isChickFormOpen,
  onAddBird,
  onAddBreeding,
  onEditBird,
  onEditBreeding,
  onAddEgg,
  onEditChick,
  onSaveChick,
  onCloseChickForm,
  onDeleteBird,
  onDeleteBreeding,
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
            breeding={breeding}
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
            loading={isLoading}
          />
        );

      case 'breeding':
        return (
          <BreedingTab
            breeding={breeding}
            birds={birds}
            onAddBreeding={onAddBreeding}
            onEditBreeding={onEditBreeding}
            onDeleteBreeding={onDeleteBreeding}
            onAddEgg={onAddEgg}
            onEditEgg={onEditEgg}
            onDeleteEgg={onDeleteEgg}
            onEggStatusChange={(breedingId, eggId, newStatus, hatchDate) => 
              onEggStatusChange(breedingId, eggId, newStatus as Egg['status'], hatchDate)
            }
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
            onEditChick={onEditChick}
            onSaveChick={onSaveChick}
            onCloseChickForm={onCloseChickForm}
            onDeleteChick={onDeleteChick}
            onAddChick={onAddChick}
            promoteChickToBird={promoteChickToBird}
          />
        );

      case 'genealogy':
        return (
          <GenealogyView 
            birds={birds} 
            chicks={chicks}
            onBirdSelect={() => {}} 
          />
        );

      case 'calendar':
        return <CalendarTab />;

      case 'profile':
        return <ProfileSettings onBack={() => onTabChange('home')} />;

      case 'settings':
        return <SettingsTab />;

      default:
        return (
          <HomeTab
            birds={birds}
            breeding={breeding}
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
    <div className="animate-fade-in min-h-[50vh] min-w-0">
      <Suspense fallback={<LoadingSpinner />}>
        {renderTabContent()}
      </Suspense>
    </div>
  );
});

TabContent.displayName = 'TabContent';

export default TabContent;
