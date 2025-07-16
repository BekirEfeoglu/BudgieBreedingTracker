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
      <div className="mobile-spacing-y mobile-container">
        <div className="mobile-header">
          <h2 className="mobile-header-title" aria-label={t('genealogy.title')}>
            {t('genealogy.title')}
          </h2>
        </div>
        
        {birds.length === 0 ? (
          <div className="mobile-empty-state" role="status" aria-live="polite">
            <div className="mobile-empty-icon" aria-hidden="true">🌳</div>
            <p className="mobile-empty-text">{t('genealogy.emptyStateTitle')}</p>
            <p className="mobile-caption mt-2 max-w-sm mx-auto">
              {t('genealogy.emptyStateDescription')}
            </p>
          </div>
        ) : (
          <div className="mobile-card mobile-card-content">
            <GenealogyView 
              birds={birds} 
              chicks={chicks}
              onBirdSelect={handleBirdSelect}
            />
          </div>
        )}
      </div>
    </ComponentErrorBoundary>
  );
});

GenealogyTab.displayName = 'GenealogyTab';

export default GenealogyTab;
