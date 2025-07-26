import React, { memo } from 'react';
import { useLanguage } from '@/contexts/LanguageContext';
import EggCard from '@/components/breeding/EggCard';
import { Plus } from 'lucide-react';
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

  const handleAddEggClick = () => {
    onAddEgg();
  };

  return (
    <div className="space-y-3" role="region" aria-label="Yumurta listesi">
      <div className="flex items-center justify-between gap-2">
        <h4 className="font-medium text-sm flex-shrink-0">
          {t('breeding.addEgg')} ({eggs.length})
        </h4>
        <button
          onClick={handleAddEggClick}
          className="px-4 py-2 bg-blue-500 text-white rounded text-xs flex-shrink-0 flex items-center gap-2"
        >
          <Plus className="w-4 h-4" />
          {t('breeding.addEgg')}
        </button>
      </div>

      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-2">
        {eggs.map((egg) => (
          <EggCard
            key={egg.id}
            egg={egg}
            breedingId={breedingId}
            _onEdit={onEditEgg}
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
