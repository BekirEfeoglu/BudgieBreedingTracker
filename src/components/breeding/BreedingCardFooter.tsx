import React, { memo } from 'react';
import { useLanguage } from '@/contexts/LanguageContext';

interface BreedingCardFooterProps {
  startDate: string;
}

const BreedingCardFooter = memo(({ startDate }: BreedingCardFooterProps) => {
  const { t } = useLanguage();
  
  const expectedHatchDate = React.useMemo(() => {
    return new Date(new Date(startDate).getTime() + 18 * 24 * 60 * 60 * 1000);
  }, [startDate]);

  const formattedStartDate = React.useMemo(() => {
    return new Date(startDate).toLocaleDateString('tr-TR');
  }, [startDate]);

  const formattedHatchDate = React.useMemo(() => {
    return expectedHatchDate.toLocaleDateString('tr-TR');
  }, [expectedHatchDate]);

  return (
    <div className="mt-4 pt-3 border-t border-border/50" role="contentinfo">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 text-xs text-muted-foreground">
        <span>
          <span className="font-medium">{t('breeding.pairDate')}:</span> {formattedStartDate}
        </span>
        <span>
          <span className="font-medium">{t('breeding.expectedHatchDate')}:</span> {formattedHatchDate}
        </span>
      </div>
    </div>
  );
});

BreedingCardFooter.displayName = 'BreedingCardFooter';

export default BreedingCardFooter;
