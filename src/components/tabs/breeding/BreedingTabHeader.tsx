import React, { memo } from 'react';
import { Button } from '@/components/ui/button';
import { Plus } from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';

interface BreedingTabHeaderProps {
  onAddIncubation: () => void;
}

const BreedingTabHeader = memo(({ onAddIncubation }: BreedingTabHeaderProps) => {
  const { t } = useLanguage();

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      onAddIncubation();
    }
  };

  return (
    <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
      <div>
        <h2 className="text-xl sm:text-2xl font-bold" aria-label={t('breeding.trackingTitle')}>
          {t('breeding.trackingTitle')}
        </h2>
        <p className="text-sm text-muted-foreground mt-1">
          {t('breeding.trackingDescription')}
        </p>
      </div>
      <Button 
        onClick={onAddIncubation}
        onKeyDown={handleKeyDown}
        className="min-h-[48px] w-full sm:w-auto touch-manipulation bg-blue-600 hover:bg-blue-700"
        size="default"
        aria-label={t('breeding.addIncubation')}
      >
        <Plus className="w-5 h-5 mr-2" aria-hidden="true" />
        {t('breeding.addIncubation')}
      </Button>
    </div>
  );
});

BreedingTabHeader.displayName = 'BreedingTabHeader';

export default BreedingTabHeader;
