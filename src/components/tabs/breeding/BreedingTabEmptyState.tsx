import React, { memo } from 'react';
import { Button } from '@/components/ui/button';
import { Plus } from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';

interface BreedingTabEmptyStateProps {
  onAddIncubation: () => void;
}

const BreedingTabEmptyState = memo(({ onAddIncubation }: BreedingTabEmptyStateProps) => {
  const { t } = useLanguage();

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      onAddIncubation();
    }
  };

  return (
    <div className="text-center py-12" role="status" aria-label="Kuluçka kaydı bulunamadı">
      <div className="text-6xl mb-4" aria-hidden="true">🥚</div>
      <h3 className="text-lg font-semibold mb-2">
        {t('breeding.emptyStateTitle')}
      </h3>
      <p className="text-muted-foreground mb-4 max-w-md mx-auto">
        {t('breeding.emptyStateDescription')}
      </p>
      <Button 
        onClick={onAddIncubation}
        onKeyDown={handleKeyDown}
        className="flex items-center gap-2 bg-blue-600 hover:bg-blue-700"
        aria-label={t('breeding.firstIncubation')}
      >
        <Plus className="w-4 h-4" aria-hidden="true" />
        {t('breeding.firstIncubation')}
      </Button>
    </div>
  );
});

BreedingTabEmptyState.displayName = 'BreedingTabEmptyState';

export default BreedingTabEmptyState;
