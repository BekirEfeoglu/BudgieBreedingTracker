import React, { memo } from 'react';
import { useLanguage } from '@/contexts/LanguageContext';
import EggCard from '@/components/breeding/EggCard';
import SmartEggAddButton from '@/components/breeding/SmartEggAddButton';
import { Egg } from '@/types';

interface BreedingCardEggsProps {
  eggs: Egg[];
  breedingId: string;
  onAddEgg: () => void;
  onEditEgg: (breedingId: string, egg: Egg) => void;
  onDeleteEgg: (eggId: string, eggNumber: number) => void;
  onEggStatusChange: (eggId: string, newStatus: string) => void;
}

const BreedingCardEggs = memo(({ 
  eggs, 
  breedingId, 
  onAddEgg, 
  onEditEgg, 
  onDeleteEgg, 
  onEggStatusChange 
}: BreedingCardEggsProps) => {
  const { t } = useLanguage();

  return (
    <div className="space-y-3" role="region" aria-label="Yumurta listesi">
      <div className="flex items-center justify-between gap-2">
        <h4 className="font-medium text-sm flex-shrink-0">
          {t('breeding.addEgg')} ({eggs.length})
        </h4>
        <SmartEggAddButton
          hasNests={true}
          onAddEgg={onAddEgg}
          className="text-xs flex-shrink-0"
        />
      </div>

      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-2">
        {eggs.map((egg) => (
          <EggCard
            key={egg.id}
            egg={egg}
            breedingId={breedingId}
            onEdit={onEditEgg}
            onDelete={onDeleteEgg}
            onStatusChange={onEggStatusChange}
          />
        ))}
      </div>
    </div>
  );
});

BreedingCardEggs.displayName = 'BreedingCardEggs';

export default BreedingCardEggs;
