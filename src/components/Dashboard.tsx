import { useState, useEffect, useCallback, Suspense, lazy, memo } from 'react';
import TabContent from '@/components/TabContent';
import Navigation from '@/components/Navigation';
import { useLanguage } from '@/contexts/LanguageContext';
import { useChickOperations } from '@/hooks/chick/useChickOperations';
import { useChicksData } from '@/hooks/chick/useChicksData';
import { useIncubationData } from '@/hooks/useIncubationData';
import { Bird, Chick, Breeding, Egg } from '@/types';
import ComponentErrorBoundary from '@/components/errors/ComponentErrorBoundary';
import { Skeleton } from '@/components/ui/skeleton';

// Lazy load heavy components
const ModernDashboard = lazy(() => import('@/components/dashboard/ModernDashboard'));

interface DashboardProps {
  birds: Bird[];
  clutches: Breeding[];
  eggs: Egg[];
  chicks: Chick[];
  isLoading: boolean;
  onBirdAdd: () => void;
  onBirdEdit: (bird: Bird) => void;
  onBirdDelete: (birdId: string) => void;
  onBirdSave: (birdData: Partial<Bird>) => void;
  onBirdFormClose: () => void;
  isBirdFormOpen: boolean;
  editingBird: Bird | null;
}

// Loading component for dashboard
const DashboardLoading = () => (
  <div className="space-y-4 sm:space-y-6 p-4 min-w-0" role="status" aria-label="Dashboard yükleniyor">
    <div className="space-y-4 min-w-0">
      <Skeleton className="h-8 w-64 mx-auto min-w-0" />
      <Skeleton className="h-4 w-96 mx-auto min-w-0" />
    </div>
    <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 min-w-0">
      {Array.from({ length: 4 }).map((_, i) => (
        <Skeleton key={i} className="h-24 w-full min-w-0" />
      ))}
    </div>
    <div className="space-y-4 min-w-0">
      <Skeleton className="h-48 w-full min-w-0" />
      <Skeleton className="h-48 w-full min-w-0" />
    </div>
  </div>
);

const Dashboard = memo(({
  birds,
  clutches,
  eggs,
  chicks: _propChicks,
  isLoading,
  onBirdAdd,
  onBirdEdit,
  onBirdDelete,
  onBirdSave: _onBirdSave,
  onBirdFormClose: _onBirdFormClose,
  isBirdFormOpen: _isBirdFormOpen,
  editingBird: _editingBird
}: DashboardProps) => {
  const { t } = useLanguage();
  
  // Default to 'home' tab
  const [activeTab, setActiveTab] = useState('home');

  // Use real-time chicks data
  const { chicks: realTimeChicks, loading: chicksLoading, refreshChicks } = useChicksData();
  
  // Use real-time incubation data
  const { incubations, loading: incubationLoading, refetch: refetchIncubations } = useIncubationData();

  // Use the chick operations hook with real-time data
  const {
    chicks: _managedChicks,
    editingChick,
    isChickFormOpen,
    handleEditChick,
    handleSaveChick,
    handleCloseChickForm,
    handleDeleteChick,
    handleAddChick,
    promoteChickToBird: basePromoteChickToBird
  } = useChickOperations();

  // Yavruyu kuşa aktardıktan sonra listeyi güncelle
  const promoteChickToBird = useCallback(async (chick: Chick) => {
    try {
      await basePromoteChickToBird(chick);
      refreshChicks();
    } catch (error) {
      console.error('Yavru kuşa aktarılırken hata:', error);
    }
  }, [basePromoteChickToBird, refreshChicks]);

  // Listen for navigation events from EggManagement
  useEffect(() => {
    const handleNavigateToBreeding = () => {
      setActiveTab('breeding');
    };

    window.addEventListener('navigateToBreeding', handleNavigateToBreeding);
    
    return () => {
      window.removeEventListener('navigateToBreeding', handleNavigateToBreeding);
    };
  }, []);

  // Memoized tab change handler to prevent unnecessary re-renders
  const handleTabChange = useCallback((tab: string) => {
    setActiveTab(tab);
    
    // Trigger refetch for real-time data only when necessary
    if (tab === 'chicks') {
      refreshChicks();
    } else if (tab === 'breeding') {
      refetchIncubations();
    }
  }, [refreshChicks, refetchIncubations]);

  // Optimized handlers with proper error handling
  const handleAddBird = useCallback(() => {
    try {
      onBirdAdd();
    } catch (error) {
      console.error('Kuş eklenirken hata:', error);
    }
  }, [onBirdAdd]);

  const handleEditBird = useCallback((bird: Bird) => {
    try {
      onBirdEdit(bird);
    } catch (error) {
      console.error('Kuş düzenlenirken hata:', error);
    }
  }, [onBirdEdit]);

  const handleDeleteBird = useCallback((birdId: string) => {
    try {
      onBirdDelete(birdId);
    } catch (error) {
      console.error('Kuş silinirken hata:', error);
    }
  }, [onBirdDelete]);

  const handleAddBreeding = useCallback(() => {
    // Handler for adding breeding records - implemented in parent component
  }, []);

  const handleEditBreeding = useCallback((_breeding: Breeding) => {
    // Handler for editing breeding records - implemented in parent component
  }, []);

  const handleDeleteBreeding = useCallback((_breedingId: string) => {
    // Handler for deleting breeding records - implemented in parent component
  }, []);

  const handleAddEgg = useCallback((_breedingId: string) => {
    // Handler for adding eggs - implemented in parent component
  }, []);

  const handleEditEgg = useCallback((_breedingId: string, _egg: Egg) => {
    // Handler for editing eggs - implemented in parent component
  }, []);

  const handleDeleteEgg = useCallback((_breedingId: string, _eggId: string) => {
    // Handler for deleting eggs - implemented in parent component
  }, []);

  const handleEggStatusChange = useCallback((
    _breedingId: string, 
    _eggId: string, 
    _status: Egg['status'], 
    _hatchDate?: string
  ) => {
    // Handler for egg status changes - implemented in parent component
  }, []);

  const isDataLoading = isLoading || chicksLoading || incubationLoading;

  return (
    <div className="min-h-screen bg-background min-w-0" role="main" aria-label={t('home.dashboardTitle')}>
      {/* Main Content */}
      <div className="min-w-0">
        <ComponentErrorBoundary>
          <Suspense fallback={<DashboardLoading />}>
            <TabContent
              activeTab={activeTab}
              birds={birds}
              breeding={clutches}
              eggs={eggs}
              chicks={realTimeChicks}
              incubations={incubations}
              editingChick={editingChick}
              isChickFormOpen={isChickFormOpen}
              onAddBird={handleAddBird}
              onAddBreeding={handleAddBreeding}
              onEditBird={handleEditBird}
              onEditBreeding={handleEditBreeding}
              onAddEgg={handleAddEgg}
              onEditChick={handleEditChick}
              onSaveChick={handleSaveChick}
              onCloseChickForm={handleCloseChickForm}
              onDeleteBird={handleDeleteBird}
              onDeleteBreeding={handleDeleteBreeding}
              onDeleteChick={handleDeleteChick}
              onEditEgg={handleEditEgg}
              onDeleteEgg={handleDeleteEgg}
              onEggStatusChange={handleEggStatusChange}
              onTabChange={handleTabChange}
              onAddChick={handleAddChick}
              isLoading={isDataLoading}
              promoteChickToBird={promoteChickToBird}
            />
          </Suspense>
        </ComponentErrorBoundary>
      </div>

      {/* Bottom Navigation */}
      <Navigation 
        activeTab={activeTab} 
        onTabChange={handleTabChange}
      />
    </div>
  );
});

Dashboard.displayName = 'Dashboard';

export default Dashboard;
