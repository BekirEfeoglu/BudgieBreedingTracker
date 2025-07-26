import React, { memo } from 'react';
import { Button } from '@/components/ui/button';
import { Plus } from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';

interface BreedingCardEggsProps {
  breedingId: string;
  eggsCount: number;
  onAddEgg?: (breedingId: string) => void;
}

const BreedingCardEggs = memo(({ 
  breedingId, 
  eggsCount, 
  onAddEgg 
}: BreedingCardEggsProps) => {
  const { t } = useLanguage();

  const handleAddEgg = () => {
    if (onAddEgg) {
      onAddEgg(breedingId);
    }
  };

  return (
    <div className="flex items-center justify-between p-3 bg-muted/50 rounded-lg">
      <div className="flex items-center gap-2">
        <span className="text-sm font-medium">
          {t('breeding.eggs')}: {eggsCount}
        </span>
      </div>
      
      {onAddEgg && (
        <Button
          variant="outline"
          size="sm"
          onClick={handleAddEgg}
          className="h-8 px-2"
        >
          <Plus className="h-4 w-4 mr-1" />
          {t('breeding.addEgg')}
        </Button>
      )}
    </div>
  );
});

BreedingCardEggs.displayName = 'BreedingCardEggs';

export default BreedingCardEggs; 