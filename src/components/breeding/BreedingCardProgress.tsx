import React, { memo } from 'react';
import { Progress } from '@/components/ui/progress';
import { useLanguage } from '@/contexts/LanguageContext';
import { calculateIncubationProgress, formatIncubationStatus } from '@/utils/incubationUtils';

interface BreedingCardProgressProps {
  startDate: string;
}

const BreedingCardProgress = memo(({ startDate }: BreedingCardProgressProps) => {
  const { t } = useLanguage();
  const progress = React.useMemo(() => 
    calculateIncubationProgress(new Date(startDate)), 
    [startDate]
  );

  return (
    <div className="mb-4 p-4 bg-gradient-to-r from-primary/5 to-primary/10 rounded-lg" role="progressbar" aria-label="Kuluçka ilerlemesi">
      <div className="flex items-center justify-between text-sm mb-3">
        <span className="font-semibold text-primary">{t('breeding.title')} {t('breeding.status')}</span>
        <span className="text-muted-foreground font-medium">{progress.daysElapsed} {t('breeding.days')}</span>
      </div>
      <Progress 
        value={progress.percentageComplete} 
        className="h-3 mb-2" 
        aria-valuenow={progress.percentageComplete}
        aria-valuemin={0}
        aria-valuemax={100}
      />
      <div className="flex justify-center text-xs text-primary font-semibold mb-1">
        {progress.daysElapsed}/{progress.daysElapsed + progress.daysRemaining} {t('breeding.days')} (%{Math.round(progress.percentageComplete)})
      </div>
      <div className="flex justify-between text-xs text-muted-foreground">
        <span>0 {t('breeding.days')}</span>
        <span className="font-semibold text-primary text-sm">
          {formatIncubationStatus(progress)}
        </span>
        <span>18 {t('breeding.days')}</span>
      </div>
    </div>
  );
});

BreedingCardProgress.displayName = 'BreedingCardProgress';

export default BreedingCardProgress;
