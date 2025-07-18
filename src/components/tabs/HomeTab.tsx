import React, { memo, useMemo, Suspense, useCallback } from 'react';
import { useLanguage } from '@/contexts/LanguageContext';
import WelcomeHeader from '@/components/dashboard/WelcomeHeader';
import BirdStatistics from '@/components/dashboard/BirdStatistics';
import BreedingStatistics from '@/components/dashboard/BreedingStatistics';
import ChickStatistics from '@/components/dashboard/ChickStatistics';
import QuickActions from '@/components/dashboard/QuickActions';
// ChartsSection removed - not implemented yet
import { Bird, Chick, Breeding, Egg } from '@/types';
import type { Incubation } from '@/hooks/useIncubationData';
import ComponentErrorBoundary from '@/components/errors/ComponentErrorBoundary';
import { Skeleton } from '@/components/ui/skeleton';

interface HomeTabProps {
  birds: Bird[];
  breeding: Breeding[];
  eggs: Egg[];
  chicks: Chick[];
  incubations: Incubation[];
  isLoading?: boolean;
  onAddBird?: () => void;
  onTabChange?: (tab: string) => void;
}

// Loading component for home tab
const HomeTabLoading = () => (
  <div className="space-y-4 sm:space-y-6 pb-20 md:pb-4 px-2 md:px-0 min-w-0" role="status" aria-label="Ana sayfa yükleniyor">
    <div className="mobile-empty-state min-w-0">
      <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto flex-shrink-0"></div>
      <p className="mobile-empty-text mt-4 truncate max-w-full min-w-0">Yükleniyor...</p>
    </div>
  </div>
);

// Error state component
const HomeTabError = () => {
  const { t } = useLanguage();
  
  return (
    <div className="space-y-4 sm:space-y-6 pb-20 md:pb-4 px-2 md:px-0 min-w-0" role="alert" aria-label={t('common.error')}>
      <div className="mobile-empty-state min-w-0">
        <div className="text-red-500 text-4xl mb-4 flex-shrink-0">⚠️</div>
        <p className="mobile-empty-text mt-4 truncate max-w-full min-w-0">{t('common.errorMessage')}</p>
      </div>
    </div>
  );
};

const HomeTab = memo<HomeTabProps>(({
  birds,
  breeding,
  eggs,
  chicks,
  incubations,
  isLoading = false,
  onAddBird,
  onTabChange
}: HomeTabProps) => {
  const { t } = useLanguage();

  // Memoized statistics calculations with improved logic
  const statistics = useMemo(() => {
    const totalIncubations = breeding.length + incubations.length;
    const activePairs = breeding.length; // All breeding pairs are considered active
    const totalEggs = eggs.length;
    const fertileEggs = eggs.filter(egg => egg.status === 'fertile').length;
    const hatchedEggs = eggs.filter(egg => egg.status === 'hatched').length;
    const totalChicks = chicks.length;
    const recentChicks = chicks.filter(chick => {
      const hatchDate = new Date(chick.hatchDate);
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
      return hatchDate > thirtyDaysAgo;
    }).length;
    
    return {
      activePairs,
      totalIncubations,
      totalEggs,
      fertileEggs,
      hatchedEggs,
      totalChicks,
      recentChicks
    };
  }, [breeding, incubations, eggs, chicks]);

  // Memoized handlers for better performance
  const handleAddBird = useCallback(() => {
    if (onAddBird) {
      onAddBird();
    }
  }, [onAddBird]);

  const handleTabChange = useCallback((tab: string) => {
    if (onTabChange) {
      onTabChange(tab);
    }
  }, [onTabChange]);

  if (isLoading) {
    return <HomeTabLoading />;
  }

  return (
    <ComponentErrorBoundary fallback={<HomeTabError />}> 
      <div 
        className="space-y-4 sm:space-y-6 pb-20 md:pb-4 px-2 md:px-0 min-w-0" 
        role="main" 
        aria-label={t('home.dashboardTitle')}
        data-testid="home-tab"
      >
        {/* Logo Header - Mobil için optimize edilmiş */}
        <div className="w-full flex justify-center px-2 min-w-0">
          <Suspense fallback={<Skeleton className="h-16 w-64 min-w-0" />}> 
            <WelcomeHeader />
          </Suspense>
        </div>

        {/* İstatistik Kartları - Mobil optimized grid */}
        <div className="w-full space-y-4 min-w-0">
          {/* Kuş İstatistikleri */}
          <Suspense fallback={<Skeleton className="h-24 w-full min-w-0" />}> 
            <div className="mobile-card mobile-stats-card flex flex-col items-center justify-center min-w-0">
              <BirdStatistics 
                birds={birds} 
                activePairs={statistics.activePairs} 
              />
            </div>
          </Suspense>

          {/* Kuluçka & Yumurta İstatistikleri */}
          <Suspense fallback={<Skeleton className="h-24 w-full min-w-0" />}> 
            <div className="mobile-card mobile-stats-card flex flex-col items-center justify-center min-w-0">
              <BreedingStatistics 
                totalIncubations={statistics.totalIncubations} 
                eggs={eggs} 
              />
            </div>
          </Suspense>

          {/* Yavru İstatistikleri */}
          <Suspense fallback={<Skeleton className="h-24 w-full min-w-0" />}> 
            <div className="mobile-card mobile-stats-card flex flex-col items-center justify-center min-w-0">
              <ChickStatistics 
                chicks={chicks} 
                eggs={eggs} 
              />
            </div>
          </Suspense>

          {/* Hızlı Aksiyonlar */}
          <Suspense fallback={<Skeleton className="h-32 w-full min-w-0" />}> 
            <div className="mobile-card mobile-stats-card flex flex-col items-center justify-center min-w-0">
              <QuickActions 
                onAddBird={handleAddBird} 
                onTabChange={handleTabChange} 
              />
            </div>
          </Suspense>
        </div>
      </div>
    </ComponentErrorBoundary>
  );
});

HomeTab.displayName = 'HomeTab';

// Performance optimization: Only re-render if props actually changed
export default HomeTab;
