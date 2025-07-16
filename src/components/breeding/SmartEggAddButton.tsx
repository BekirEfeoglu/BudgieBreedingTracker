import React, { memo } from 'react';
import { Plus } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useLanguage } from '@/contexts/LanguageContext';

interface SmartEggAddButtonProps {
  hasNests: boolean;
  onAddEgg: () => void;
  className?: string;
  size?: 'sm' | 'default' | 'lg';
  variant?: 'default' | 'outline' | 'secondary' | 'ghost';
}

const SmartEggAddButton = memo(({ 
  hasNests, 
  onAddEgg, 
  className = '',
  size = 'default',
  variant = 'outline'
}: SmartEggAddButtonProps) => {
  const { t } = useLanguage();

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      onAddEgg();
    }
  };

  return (
    <Button
      variant={variant}
      size={size}
      onClick={onAddEgg}
      onKeyDown={handleKeyDown}
      disabled={!hasNests}
      className={`min-h-[48px] touch-manipulation ${className}`}
      aria-label={t('breeding.addEgg')}
      title={!hasNests ? t('breeding.noNests') : t('breeding.addEgg')}
    >
      <Plus className="w-4 h-4 mr-2" aria-hidden="true" />
      {t('breeding.addEgg')}
    </Button>
  );
});

SmartEggAddButton.displayName = 'SmartEggAddButton';

export default SmartEggAddButton;
