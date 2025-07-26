import React from 'react';
import { useLanguage } from '@/contexts/LanguageContext';
import { Button } from '@/components/ui/button';
import { Plus } from 'lucide-react';

interface EggListHeaderProps {
  eggCount: number;
  onAddEgg: () => void;
  disabled?: boolean;
}

const EggListHeader: React.FC<EggListHeaderProps> = ({
  eggCount,
  onAddEgg,
  disabled = false
}) => {
  const { t } = useLanguage();

  const displayCount = eggCount || 0;

  return (
    <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
      <h3 className="text-lg font-semibold">
        {t('egg.list.title', 'Yumurtalar')} ({displayCount})
      </h3>
      <Button
        onClick={onAddEgg}
        disabled={disabled}
        className="flex items-center gap-2 min-h-[44px]"
      >
        <Plus className="w-4 h-4" />
        {t('egg.add', 'Yumurta Ekle')}
      </Button>
    </div>
  );
};

export default EggListHeader;
