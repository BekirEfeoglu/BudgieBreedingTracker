import React, { memo } from 'react';
import { useLanguage } from '@/contexts/LanguageContext';
import { Bird, Chick } from '@/types';
import ComponentErrorBoundary from '@/components/errors/ComponentErrorBoundary';
import GenealogyView from '@/components/GenealogyView';

interface GenealogyTabProps {
  birds: Bird[];
  chicks?: Chick[];
}

const GenealogyTab = memo(({ birds, chicks = [] }: GenealogyTabProps) => {
  const { t } = useLanguage();

  const handleBirdSelect = (bird: Bird | Chick) => {
    // Handle bird selection - for now just log it
    console.log('Selected bird:', bird.name);
  };

  return (
    <ComponentErrorBoundary>
      <div className="space-y-4 sm:space-y-6 pb-20 md:pb-4 px-2 md:px-0 min-w-0" role="main" aria-label={t('genealogy.title')}>
        <div className="mobile-header min-w-0">
          <h2 className="mobile-header-title truncate max-w-full min-w-0" aria-label={t('genealogy.title')}>
            {t('genealogy.title')}
          </h2>
          <p className="mobile-subtitle truncate max-w-full min-w-0">
            Kuşlarınızın soy ağacını görüntüleyin
          </p>
        </div>
        
        {birds.length === 0 ? (
          <div className="mobile-empty-state min-w-0" role="status" aria-live="polite">
            <div className="mobile-empty-icon flex-shrink-0" aria-hidden="true">🌳</div>
            <p className="mobile-empty-text truncate max-w-full min-w-0">{t('genealogy.emptyStateTitle')}</p>
            <p className="mobile-caption mt-2 max-w-sm mx-auto truncate max-w-full min-w-0">
              {t('genealogy.emptyStateDescription')}
            </p>
          </div>
        ) : (
          <div className="mobile-card min-w-0">
            <div className="mobile-card-content min-w-0">
              <GenealogyView 
                birds={birds} 
                chicks={chicks}
                onBirdSelect={handleBirdSelect}
              />
            </div>
          </div>
        )}
      </div>
    </ComponentErrorBoundary>
  );
});

GenealogyTab.displayName = 'GenealogyTab';

export default GenealogyTab;
