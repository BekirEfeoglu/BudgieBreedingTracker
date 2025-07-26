import React from 'react';
import { useLanguage } from '@/contexts/LanguageContext';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Plus } from 'lucide-react';

interface EggListEmptyProps {
  onAddEgg: () => void;
}

const EggListEmpty: React.FC<EggListEmptyProps> = ({ onAddEgg }) => {
  const { t } = useLanguage();

  return (
    <Card>
      <CardContent className="p-8 text-center">
        <div className="text-6xl mb-4">🥚</div>
        <h4 className="text-lg font-medium mb-2">
          {t('egg.list.empty.title', 'Henüz yumurta eklenmemiş')}
        </h4>
        <p className="text-muted-foreground mb-4">
          {t('egg.list.empty.description', 'Bu kuluçka için yumurta eklemeye başlayın.')}
        </p>
        <Button onClick={onAddEgg} className="min-h-[44px]">
          <Plus className="w-4 h-4 mr-2" />
          {t('egg.add', 'Yumurta Ekle')}
        </Button>
      </CardContent>
    </Card>
  );
};

export default EggListEmpty;
