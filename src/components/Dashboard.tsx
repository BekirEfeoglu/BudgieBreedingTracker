import React, { useState, useCallback, useEffect, useMemo, Suspense, lazy, memo, forwardRef, useImperativeHandle } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { useLanguage } from '@/contexts/LanguageContext';
import { Bird, Chick, Egg } from '@/types';
import { useIncubationData } from '@/hooks/useIncubationData';
import { useEggCrud } from '@/hooks/egg/useEggCrud';
import { useChicksData } from '@/hooks/chick/useChicksData';
import { useChickCrud } from '@/hooks/chick/useChickCrud';
import { useChickPromotion } from '@/hooks/chick/useChickPromotion';
import TabContent from '@/components/TabContent';
import Navigation from '@/components/Navigation';
import ComponentErrorBoundary from '@/components/errors/ComponentErrorBoundary';
import { Skeleton } from '@/components/ui/skeleton';
import { toast } from '@/hooks/use-toast';

// Lazy load heavy components
const ModernDashboard = lazy(() => import('@/components/dashboard/ModernDashboard'));

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

interface DashboardProps {
  birds: Bird[];
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



const Dashboard = forwardRef<{ handleTabChange: (tab: string) => void }, DashboardProps>(({
  birds,
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
}, ref) => {
  const { t } = useLanguage();
  
  // Default to 'home' tab
  const [activeTab, setActiveTab] = useState('home');

  // Use real-time incubation data
  const { incubations, loading: incubationLoading } = useIncubationData();

  // Use real-time chicks data
  const { chicks: realTimeChicks, loading: chicksLoading, refetchChicks } = useChicksData();
  
  // Use chick CRUD operations
  const { deleteChick: deleteChickCrud, updateChick: updateChickCrud } = useChickCrud();
  
  // Use chick promotion operations
  const { promoteChickToBird: promoteChickToBirdCrud } = useChickPromotion();

  // Simple chick state management
  const [editingChick, setEditingChick] = useState<Chick | null>(null);
  const [isChickFormOpen, setIsChickFormOpen] = useState(false);

  const handleEditChick = useCallback((chick: Chick) => {
    setEditingChick(chick);
    setIsChickFormOpen(true);
  }, []);

  const handleSaveChick = useCallback(async (chickData: Partial<Chick> & { hatchDate?: Date }) => {
    if (!editingChick) {
      console.error('❌ handleSaveChick - Düzenlenecek yavru bulunamadı');
      return;
    }

    try {
      console.log('🔄 Dashboard.handleSaveChick - Yavru güncelleme başlıyor:', { 
        chickId: editingChick.id, 
        chickData 
      });

      // Veritabanı alan adlarını kullan
      const updatedChickData: any = {
        name: chickData.name,
        gender: chickData.gender,
        color: chickData.color,
        hatch_date: chickData.hatchDate ? chickData.hatchDate.toISOString().split('T')[0] : editingChick.hatchDate,
        ring_number: chickData.ringNumber,
        mother_id: chickData.motherId,
        father_id: chickData.fatherId,
        health_notes: chickData.healthNotes,
        photo_url: chickData.photo
      };

      const result = await updateChickCrud(editingChick.id, updatedChickData);
      
      if (result.success) {
        console.log('✅ Dashboard.handleSaveChick - Yavru başarıyla güncellendi');
        
        // Force refresh chicks after update since realtime subscription might not work
        setTimeout(() => {
          if (refetchChicks) {
            console.log('🔄 Dashboard.handleSaveChick - Yavru listesi yenileniyor');
            refetchChicks();
          }
        }, 500);
        
        setIsChickFormOpen(false);
        setEditingChick(null);
      } else {
        console.error('❌ Dashboard.handleSaveChick - Yavru güncelleme başarısız:', result.error);
      }
    } catch (error) {
      console.error('💥 Dashboard.handleSaveChick - Beklenmedik hata:', error);
    }
  }, [editingChick, updateChickCrud, refetchChicks]);

  const handleCloseChickForm = useCallback(() => {
    setIsChickFormOpen(false);
    setEditingChick(null);
  }, []);

  const handleDeleteChick = useCallback(async (chickId: string) => {
    console.log('🗑️ Dashboard.handleDeleteChick - Yavru silme başlıyor:', { chickId });
    
    try {
      const result = await deleteChickCrud(chickId);
      
      if (result.success) {
        console.log('✅ Dashboard.handleDeleteChick - Yavru başarıyla silindi');
        
        // Force refresh chicks after deletion since realtime subscription might not work
        setTimeout(() => {
          if (refetchChicks) {
            console.log('🔄 Dashboard.handleDeleteChick - Yavru listesi yenileniyor');
            refetchChicks();
          }
        }, 500);
      } else {
        console.error('❌ Dashboard.handleDeleteChick - Yavru silme başarısız:', result.error);
      }
    } catch (error) {
      console.error('💥 Dashboard.handleDeleteChick - Beklenmedik hata:', error);
    }
  }, [deleteChickCrud, refetchChicks]);

  const handleAddChick = useCallback(() => {
    setEditingChick(null);
    setIsChickFormOpen(true);
  }, []);

  const promoteChickToBird = useCallback(async (chick: Chick) => {
    console.log('🔄 Dashboard.promoteChickToBird - Yavru kuşa aktarma başlıyor:', { chickId: chick.id, chickName: chick.name });
    
    try {
      const result = await promoteChickToBirdCrud(chick, refetchChicks);
      
      if (result.success) {
        console.log('✅ Dashboard.promoteChickToBird - Yavru başarıyla kuşa aktarıldı');
        // Force refresh chicks after promotion since realtime subscription might not work
        if (refetchChicks) {
          console.log('🔄 Dashboard.promoteChickToBird - Yavru listesi hemen yenileniyor');
          await refetchChicks();
          
          // Double check
          setTimeout(async () => {
            console.log('🔄 Dashboard.promoteChickToBird - Yavru listesi tekrar yenileniyor (double check)');
            await refetchChicks();
          }, 100);
        }
      } else {
        console.error('❌ Dashboard.promoteChickToBird - Yavru kuşa aktarma başarısız:', result.error);
      }
    } catch (error) {
      console.error('💥 Dashboard.promoteChickToBird - Beklenmedik hata:', error);
    }
  }, [promoteChickToBirdCrud, refetchChicks]);

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
    
    // Tab değişikliği - gerçek zamanlı veri zaten otomatik güncelleniyor
  }, []);

  // Expose handleTabChange to parent component via ref
  useImperativeHandle(ref, () => ({
    handleTabChange
  }), [handleTabChange]);

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

  const handleAddEgg = useCallback((_breedingId: string) => {
    // Handler for adding eggs - implemented in parent component
  }, []);

  const handleEditEgg = useCallback((_breedingId: string, _egg: Egg) => {
    // Handler for editing eggs - implemented in parent component
  }, []);

  // Use egg CRUD operations
  const { deleteEgg: deleteEggCrud } = useEggCrud();

  const handleDeleteEgg = useCallback(async (breedingId: string, eggId: string) => {
    console.log('🗑️ Dashboard.handleDeleteEgg - Yumurta silme başlıyor:', {
      breedingId,
      eggId
    });
    
    try {
      const result = await deleteEggCrud(eggId);
      
      if (result.success) {
        console.log('✅ Dashboard.handleDeleteEgg - Yumurta başarıyla silindi');
        // Realtime subscription will handle the UI update automatically
      } else {
        console.error('❌ Dashboard.handleDeleteEgg - Yumurta silme başarısız:', result.error);
      }
    } catch (error) {
      console.error('💥 Dashboard.handleDeleteEgg - Beklenmedik hata:', error);
    }
  }, [deleteEggCrud]);

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
              eggs={eggs}
              chicks={realTimeChicks}
              incubations={incubations}
              editingChick={editingChick}
              isChickFormOpen={isChickFormOpen}
              onAddBird={handleAddBird}
              onEditBird={handleEditBird}
              onAddEgg={handleAddEgg}
              onEditChick={handleEditChick}
              onSaveChick={handleSaveChick}
              onCloseChickForm={handleCloseChickForm}
              onDeleteBird={handleDeleteBird}
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
