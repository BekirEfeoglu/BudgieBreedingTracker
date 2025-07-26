import React, { Suspense, lazy, memo, useState, useCallback, useMemo } from 'react';
import { Button } from '@/components/ui/button';
import { Plus, Loader2, Search } from 'lucide-react';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { useLanguage } from '@/contexts/LanguageContext';
import { useDebounce } from '@/hooks/useDebounce';
import { usePremiumGuard } from '@/hooks/subscription/usePremiumGuard';
import { Bird } from '@/types';
import ComponentErrorBoundary from '@/components/errors/ComponentErrorBoundary';

// Lazy load heavy components
const BirdCard = lazy(() => import('@/components/BirdCard'));
const BirdDetailModal = lazy(() => import('@/components/BirdDetailModal'));

interface BirdsTabProps {
  birds: Bird[];
  onAddBird: () => void;
  onEditBird: (bird: Bird) => void;
  onDeleteBird: (birdId: string) => void;
  loading?: boolean;
}

// Loading skeleton component - removed unused variable

const BirdsTab = memo(({ birds, onAddBird, onEditBird, onDeleteBird, loading = false }: BirdsTabProps) => {
  const { t } = useLanguage();
  const { requireFeatureLimit, subscriptionLimits, subscriptionError } = usePremiumGuard();
  
  // Debug log'ları kaldırıldı
  const [selectedBird, setSelectedBird] = useState<Bird | null>(null);
  const [isDetailModalOpen, setIsDetailModalOpen] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [genderFilter, setGenderFilter] = useState<'all' | 'male' | 'female' | 'unknown'>('all');
  const [sortBy, setSortBy] = useState<'name' | 'birthDate' | 'gender'>('name');

  // Debounced search for better performance
  const debouncedSearchTerm = useDebounce(searchTerm, 300);

  // Memoized filtered and sorted birds
  const filtered = useMemo(() => {
    // Remove duplicates by ID first
    const uniqueBirds = birds.filter((bird, index, self) => 
      index === self.findIndex(b => b.id === bird.id)
    );

    const filtered = uniqueBirds.filter(bird => {
      const matchesSearch = !debouncedSearchTerm || 
        bird.name?.toLowerCase().includes(debouncedSearchTerm.toLowerCase()) ||
        bird.ringNumber?.toLowerCase().includes(debouncedSearchTerm.toLowerCase()) ||
        bird.color?.toLowerCase().includes(debouncedSearchTerm.toLowerCase());
      
      const matchesGender = genderFilter === 'all' || bird.gender === genderFilter;
      
      return matchesSearch && matchesGender;
    });

    // Sort birds
    filtered.sort((a, b) => {
      switch (sortBy) {
        case 'name':
          return (a.name || '').localeCompare(b.name || '');
        case 'birthDate':
          if (!a.birthDate && !b.birthDate) return 0;
          if (!a.birthDate) return 1;
          if (!b.birthDate) return -1;
          return new Date(b.birthDate).getTime() - new Date(a.birthDate).getTime();
        case 'gender':
          return (a.gender || '').localeCompare(b.gender || '');
        default:
          return 0;
      }
    });

    return filtered;
  }, [birds, debouncedSearchTerm, genderFilter, sortBy]);

  const handleViewBirdDetails = useCallback((bird: Bird) => {
    setSelectedBird(bird);
    setIsDetailModalOpen(true);
  }, []);

  const handleCloseDetailModal = useCallback(() => {
    setIsDetailModalOpen(false);
    setSelectedBird(null);
  }, []);

  const handleEditFromModal = useCallback((bird: Bird) => {
    setIsDetailModalOpen(false);
    setSelectedBird(null);
    onEditBird(bird);
  }, [onEditBird]);

  const handleDeleteFromModal = useCallback((birdId: string) => {
    onDeleteBird(birdId);
    setIsDetailModalOpen(false);
    setSelectedBird(null);
  }, [onDeleteBird]);

  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      handleAddBirdWithLimit();
    }
  }, []);

  const handleAddBirdWithLimit = useCallback(() => {
    // Premium guard kontrolü yap
    const canAddBird = requireFeatureLimit('birds', birds.length, { feature: 'kuş kaydı', showToast: true });
    
    if (canAddBird) {
      onAddBird();
    }
  }, [requireFeatureLimit, birds.length, onAddBird]);

  const handleSearchChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    setSearchTerm(e.target.value);
  }, []);

  const handleGenderFilterChange = useCallback((value: string) => {
    setGenderFilter(value as 'all' | 'male' | 'female' | 'unknown');
  }, []);

  const handleSortChange = useCallback((value: string) => {
    setSortBy(value as 'name' | 'birthDate' | 'gender');
  }, []);

  return (
    <ComponentErrorBoundary>
      <div className="space-y-6 pb-20 md:pb-4 px-2 md:px-0 min-w-0" role="main" aria-label={t('birds.title')}>
        {/* Header */}
        <div className="mobile-header min-w-0">
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 min-w-0">
            <div className="min-w-0 flex-1">
              <h2 className="mobile-header-title truncate max-w-full min-w-0" aria-label={t('birds.myBirds')}>
                {t('birds.myBirds')}
              </h2>
              <p className="text-sm text-muted-foreground truncate max-w-full min-w-0">
                {birds.length} {t('birds.bird')}, {filtered.length} {t('common.view')}
              </p>
            </div>
            <div className="mobile-header-actions min-w-0 flex-shrink-0">
              <Button 
                className="enhanced-button-primary touch-target mobile-form-button w-full sm:w-auto min-w-0" 
                onClick={handleAddBirdWithLimit}
                onKeyDown={handleKeyDown}
                size="default"
                aria-label={t('birds.addBird')}
                data-testid="add-bird-button"
              >
                <Plus className="w-4 h-4 mr-2 flex-shrink-0" aria-hidden="true" />
                <span className="truncate max-w-full min-w-0">{t('birds.addBird')}</span>
              </Button>
            </div>
          </div>
        </div>

        {/* Search and Filters */}
        <div className="space-y-4 min-w-0">
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 min-w-0">
            <div className="relative min-w-0">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground w-4 h-4 flex-shrink-0" />
              <Input
                placeholder={t('birds.searchPlaceholder')}
                value={searchTerm}
                onChange={handleSearchChange}
                className="pl-10 min-h-[48px] min-w-0 mobile-form-input"
                aria-label={t('birds.searchPlaceholder')}
              />
            </div>
            
            <Select value={genderFilter} onValueChange={handleGenderFilterChange}>
              <SelectTrigger className="min-h-[48px] min-w-0 mobile-form-input">
                <SelectValue placeholder={t('birds.genderFilter')} />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">{t('birds.allGenders')}</SelectItem>
                <SelectItem value="male">{t('birds.male')}</SelectItem>
                <SelectItem value="female">{t('birds.female')}</SelectItem>
                <SelectItem value="unknown">{t('birds.unknown')}</SelectItem>
              </SelectContent>
            </Select>

            <Select value={sortBy} onValueChange={handleSortChange}>
              <SelectTrigger className="min-h-[48px] min-w-0 mobile-form-input">
                <SelectValue placeholder={t('birds.sortBy')} />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="name">{t('birds.sortByName')}</SelectItem>
                <SelectItem value="birthDate">{t('birds.sortByBirthDate')}</SelectItem>
                <SelectItem value="gender">{t('birds.sortByGender')}</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>
        
        {/* Content */}
        {loading ? (
          <div className="mobile-empty-state min-w-0" role="status" aria-label={t('birds.birdsLoading')}>
            <Loader2 className="w-8 h-8 animate-spin mx-auto mb-4 text-primary flex-shrink-0" aria-hidden="true" />
            <p className="mobile-empty-text truncate max-w-full min-w-0">{t('birds.birdsLoading')}</p>
          </div>
        ) : filtered.length === 0 ? (
          <div className="mobile-empty-state min-w-0" role="status" aria-label={t('birds.emptyStateTitle')}>
            <div className="mobile-empty-icon flex-shrink-0" aria-hidden="true">🦜</div>
            <p className="mobile-empty-text truncate max-w-full min-w-0">
              {birds.length === 0 ? t('birds.emptyStateTitle') : t('birds.noSearchResults')}
            </p>
            <p className="mobile-caption mt-2 max-w-sm mx-auto truncate max-w-full min-w-0">
              {birds.length === 0 ? t('birds.emptyStateDescription') : t('birds.tryDifferentSearch')}
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-4 sm:gap-6 min-w-0" role="region" aria-label={t('birds.birdList')}>
            {filtered.map((bird) => (
              <Suspense key={bird.id} fallback={
                <div className="w-full h-32 bg-muted rounded-lg animate-pulse min-w-0" aria-hidden="true"></div>
              }>
                <BirdCard 
                  bird={bird} 
                  onEdit={onEditBird}
                  onDelete={onDeleteBird}
                  onViewDetails={handleViewBirdDetails}
                  birds={birds}
                />
              </Suspense>
            ))}
          </div>
        )}
      </div>

      {/* Bird Detail Modal */}
      <Suspense fallback={
        <div className="w-full h-96 bg-muted rounded-lg animate-pulse min-w-0" aria-hidden="true"></div>
      }>
        <BirdDetailModal
          bird={selectedBird}
          isOpen={isDetailModalOpen}
          onClose={handleCloseDetailModal}
          onEdit={handleEditFromModal}
          onDelete={handleDeleteFromModal}
          existingBirds={birds}
        />
      </Suspense>
    </ComponentErrorBoundary>
  );
});

BirdsTab.displayName = 'BirdsTab';

// Performance optimization: Only re-render if props actually changed
export default memo(BirdsTab, (prevProps, nextProps) => {
  return (
    prevProps.loading === nextProps.loading &&
    prevProps.birds.length === nextProps.birds.length &&
    prevProps.birds.every((bird, index) => bird.id === nextProps.birds[index]?.id)
  );
});
