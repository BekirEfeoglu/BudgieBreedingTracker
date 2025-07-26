import React, { memo, useCallback } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { useLanguage } from '@/contexts/LanguageContext';
import ComponentErrorBoundary from '@/components/errors/ComponentErrorBoundary';

interface QuickActionsProps {
  onAddBird?: () => void;
  onTabChange?: (tab: string) => void;
}

const QuickActions: React.FC<QuickActionsProps> = ({ onAddBird, onTabChange }) => {
  const { t } = useLanguage();

  // Memoized handlers with improved error handling
  const handleAddBird = useCallback(() => {
    try {
      if (onAddBird) {
        onAddBird();
      }
    } catch (error) {
      console.error('Error adding bird:', error);
    }
  }, [onAddBird]);

  const handleAddIncubation = useCallback(() => {
    try {
      if (onTabChange) {
        onTabChange('breeding');
      }
    } catch (error) {
      console.error('Error changing to breeding tab:', error);
    }
  }, [onTabChange]);

  return (
    <ComponentErrorBoundary>
      <Card className="overflow-hidden border-l-4 border-l-indigo-500" role="region" aria-label={t('home.quickActions')}>
        <CardHeader className="pb-3">
          <CardTitle className="flex items-center gap-2 text-lg">
            <div className="w-8 h-8 bg-indigo-100 dark:bg-indigo-900/20 rounded-full flex items-center justify-center">
              <span className="text-lg" role="img" aria-label="Hızlı işlemler ikonu">⚡</span>
            </div>
            {t('home.quickActions')}
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 gap-3">
            <button 
              className="text-center p-4 bg-gradient-to-br from-blue-50 to-blue-100 dark:from-blue-950/20 dark:to-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800 hover:shadow-md hover:scale-105 transition-all duration-200 cursor-pointer focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 active:scale-95"
              onClick={handleAddBird}
              aria-label={t('home.addBird')}
              data-testid="add-bird-button"
            >
              <div className="text-3xl mb-2" role="img" aria-label="Kuş ikonu">🐦</div>
              <div className="text-sm font-medium">{t('home.addBird')}</div>
            </button>
            <button 
              className="text-center p-4 bg-gradient-to-br from-orange-50 to-orange-100 dark:from-orange-950/20 dark:to-orange-900/20 rounded-lg border border-orange-200 dark:border-orange-800 hover:shadow-md hover:scale-105 transition-all duration-200 cursor-pointer focus:outline-none focus:ring-2 focus:ring-orange-500 focus:ring-offset-2 active:scale-95"
              onClick={handleAddIncubation}
              aria-label={t('home.addIncubation')}
              data-testid="add-incubation-button"
            >
              <div className="text-3xl mb-2" role="img" aria-label="Yumurta ikonu">🥚</div>
              <div className="text-sm font-medium">{t('home.addIncubation')}</div>
            </button>
          </div>
        </CardContent>
      </Card>
    </ComponentErrorBoundary>
  );
};

QuickActions.displayName = 'QuickActions';

export default memo(QuickActions);