import React from 'react';
import { Button } from '@/components/ui/button';
import { ArrowLeft, Save, Loader2 } from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';

interface IncubationFormActionsProps {
  onCancel: () => void;
  onSubmit: () => void;
  isSubmitting: boolean;
  isLoading?: boolean;
  isValid?: boolean;
}

const IncubationFormActions: React.FC<IncubationFormActionsProps> = ({
  onCancel,
  onSubmit,
  isSubmitting,
  isLoading = false,
  isValid = true
}) => {
  const { t } = useLanguage();

  return (
    <div className="fixed bottom-0 left-0 right-0 z-50 bg-background/95 backdrop-blur-lg border-t border-border/50 shadow-lg">
      <div className="p-4 pb-safe">
        <div className="max-w-2xl mx-auto">
          <div className="flex flex-col gap-3">
            <Button
              type="button"
              onClick={onSubmit}
              disabled={isSubmitting || isLoading || !isValid}
              className="w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold py-4 text-base shadow-lg"
            >
              {isSubmitting || isLoading ? (
                <div className="flex items-center gap-2">
                  <Loader2 className="w-5 h-5 animate-spin" />
                  <span>{t('common.loading')}</span>
                </div>
              ) : (
                <span>
                  <Save className="w-4 h-4 mr-2 inline" />
                  {t('breeding.save')}
                </span>
              )}
            </Button>
            
            <Button
              type="button"
              variant="outline"
              onClick={onCancel}
              disabled={isSubmitting || isLoading}
              className="w-full py-4 text-base"
            >
              <ArrowLeft className="w-4 h-4 mr-2" />
              {t('common.cancel')}
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default IncubationFormActions;
