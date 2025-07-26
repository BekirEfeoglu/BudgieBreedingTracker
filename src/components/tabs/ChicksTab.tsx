import React, { useState, Suspense, lazy, memo } from 'react';
import { Button } from '@/components/ui/button';
import { Plus } from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';
import { Bird, Chick } from '@/types';
import ComponentErrorBoundary from '@/components/errors/ComponentErrorBoundary';

// Lazy load heavy components
const ChickCard = lazy(() => import('@/components/ChickCard'));
const ChickDetailModal = lazy(() => import('@/components/ChickDetailModal'));
const ChickForm = lazy(() => import('@/components/ChickForm'));

interface ChicksTabProps {
  chicks: Chick[];
  birds: Bird[];
  editingChick: Chick | null;
  isChickFormOpen: boolean;
  onEditChick: (chick: Chick) => void;
  onSaveChick: (data: any) => void;
  onCloseChickForm: () => void;
  onDeleteChick: (chickId: string) => void;
  onAddChick: () => void;
  promoteChickToBird: (chick: Chick) => void;
}

const ChicksTab = memo<ChicksTabProps>(({ 
  chicks, 
  birds, 
  editingChick,
  isChickFormOpen,
  onEditChick, 
  onSaveChick,
  onCloseChickForm,
  onDeleteChick,
  onAddChick,
  promoteChickToBird
}: ChicksTabProps) => {
  const { t } = useLanguage();
  const [selectedChick, setSelectedChick] = useState<Chick | null>(null);
  const [isDetailModalOpen, setIsDetailModalOpen] = useState(false);

  const handleChickClick = (chick: Chick) => {
    setSelectedChick(chick);
    setIsDetailModalOpen(true);
  };

  const handleCloseDetailModal = () => {
    setIsDetailModalOpen(false);
    setSelectedChick(null);
  };

  return (
    <ComponentErrorBoundary>
      <div className="space-y-4 sm:space-y-6 pb-20 md:pb-4 px-2 md:px-0 min-w-0" role="main" aria-label={t('chicks.title')}>
        {/* Header */}
        <div className="mobile-header min-w-0">
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 min-w-0">
            <div className="min-w-0 flex-1">
              <h2 className="mobile-header-title truncate max-w-full min-w-0" aria-label={t('chicks.title')}>
                {t('chicks.title')}
              </h2>
              <p className="mobile-subtitle truncate max-w-full min-w-0">
                {chicks.length} {t('chicks.chick')} kayıtlı
              </p>
            </div>
            <div className="mobile-header-actions min-w-0 flex-shrink-0">
              <Button 
                className="enhanced-button-primary touch-target mobile-form-button w-full sm:w-auto min-w-0"
                size="default"
                onClick={onAddChick}
                aria-label={t('chicks.addChick')}
              >
                <Plus className="w-4 h-4 mr-2 flex-shrink-0" aria-hidden="true" />
                <span className="truncate max-w-full min-w-0">{t('chicks.addChick')}</span>
              </Button>
            </div>
          </div>
        </div>
        
        {/* Content */}
        {chicks.length === 0 ? (
          <div className="mobile-empty-state min-w-0" role="status" aria-live="polite">
            <div className="mobile-empty-icon flex-shrink-0" aria-hidden="true">🐣</div>
            <p className="mobile-empty-text truncate max-w-full min-w-0">{t('chicks.emptyStateTitle')}</p>
            <p className="mobile-caption mt-2 max-w-sm mx-auto truncate max-w-full min-w-0">
              {t('chicks.emptyStateDescription')}
            </p>
          </div>
        ) : (
          <div className="mobile-grid mobile-grid-cols-1 gap-4 min-w-0" role="region" aria-label={t('chicks.chickList')}>
            {chicks.map((chick) => (
              <Suspense key={chick.id} fallback={
                <div className="w-full h-32 bg-muted rounded-lg animate-pulse min-w-0" aria-hidden="true"></div>
              }>
                <ChickCard 
                  chick={chick} 
                  birds={birds}
                  onEdit={onEditChick}
                  onDelete={onDeleteChick}
                  onClick={() => handleChickClick(chick)}
                  onPromote={promoteChickToBird}
                />
              </Suspense>
            ))}
          </div>
        )}

        {/* Modals */}
        <Suspense fallback={
          <div className="w-full h-96 bg-muted rounded-lg animate-pulse min-w-0" aria-hidden="true"></div>
        }>
          <ChickDetailModal
            chick={selectedChick}
            birds={birds}
            isOpen={isDetailModalOpen}
            onClose={handleCloseDetailModal}
            onEdit={onEditChick}
            onDelete={onDeleteChick}
          />
        </Suspense>

        <Suspense fallback={
          <div className="w-full h-96 bg-muted rounded-lg animate-pulse min-w-0" aria-hidden="true"></div>
        }>
          <ChickForm
            isOpen={isChickFormOpen}
            onClose={onCloseChickForm}
            onSave={onSaveChick}
            birds={birds}
            editingChick={editingChick}
          />
        </Suspense>
      </div>
    </ComponentErrorBoundary>
  );
});

ChicksTab.displayName = 'ChicksTab';

export default ChicksTab;
