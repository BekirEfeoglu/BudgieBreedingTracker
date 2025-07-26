import React, { memo } from 'react';
import { Button } from '@/components/ui/button';
import { Plus } from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';

interface SmartEggAddButtonProps {
  breedingId: string;
  onAddEgg: (breedingId: string) => void;
  disabled?: boolean;
}

const SmartEggAddButton = memo(({ 
  breedingId, 
  onAddEgg, 
  disabled = false 
}: SmartEggAddButtonProps) => {
  const { t } = useLanguage();

  const handleClick = () => {
    onAddEgg(breedingId);
  };

  return (
    <Button
      variant="outline"
      size="sm"
      onClick={handleClick}
      disabled={disabled}
      className="h-8 px-2"
    >
      <Plus className="h-4 w-4 mr-1" />
      {t('breeding.addEgg')}
    </Button>
  );
});

SmartEggAddButton.displayName = 'SmartEggAddButton';

export default SmartEggAddButton;
