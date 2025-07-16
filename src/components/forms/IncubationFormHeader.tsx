import React from 'react';
import { Button } from '@/components/ui/button';
import { ArrowLeft, Loader2 } from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';

interface IncubationFormHeaderProps {
  onCancel: () => void;
  isSubmitting: boolean;
  formType: 'add' | 'edit';
}

const IncubationFormHeader: React.FC<IncubationFormHeaderProps> = ({
  onCancel,
  isSubmitting,
  formType
}) => {
  const { t } = useLanguage();

  return (
    <div className="flex items-center justify-between p-3 sm:p-4 border-b border-border/50 bg-background/95 backdrop-blur-sm">
      <div className="flex items-center gap-2 sm:gap-3">
        <Button
          variant="ghost"
          size="sm"
          onClick={onCancel}
          className="flex items-center gap-1 sm:gap-2 min-h-[44px] min-w-[44px]"
          disabled={isSubmitting}
        >
          <ArrowLeft className="w-4 h-4" />
          <span className="hidden sm:inline">{t('common.back')}</span>
        </Button>
      </div>
      
      <h1 className="text-sm sm:text-lg font-semibold text-center">
        {formType === 'add' 
          ? `🥚 ${t('breeding.addBreeding')}`
          : `🛠️ ${t('breeding.editBreeding')}`
        }
      </h1>
      
      <div className="w-12 sm:w-20">
        {isSubmitting && (
          <Loader2 className="w-4 h-4 animate-spin" />
        )}
      </div>
    </div>
  );
};

export default IncubationFormHeader;
