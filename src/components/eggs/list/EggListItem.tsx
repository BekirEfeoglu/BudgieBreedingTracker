import React, { memo } from 'react';
import { useLanguage } from '@/contexts/LanguageContext';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Edit, Trash2, Calendar, Hash } from 'lucide-react';
import { EggWithClutch } from '@/types/egg';
import { formatDate } from '@/utils/dateUtils';

interface EggListItemProps {
  egg: EggWithClutch;
  onEditEgg: (egg: EggWithClutch) => void;
  onDeleteEgg: (eggId: string, eggNumber: number) => void;
}

const EggListItem = memo(({ 
  egg, 
  onEditEgg, 
  onDeleteEgg 
}: EggListItemProps) => {
  const { t } = useLanguage();

  const getStatusConfig = (status: string) => {
    switch (status) {
      case 'laid':
        return {
          color: 'bg-blue-500 hover:bg-blue-600',
          text: t('egg.status.laid', 'Yumurtlandı'),
          icon: '🥚'
        };
      case 'fertile':
        return {
          color: 'bg-green-500 hover:bg-green-600',
          text: t('egg.status.fertile', 'Dolu'),
          icon: '✅'
        };
      case 'hatched':
        return {
          color: 'bg-purple-500 hover:bg-purple-600',
          text: t('egg.status.hatched', 'Çıktı'),
          icon: '🐣'
        };
      case 'infertile':
        return {
          color: 'bg-red-500 hover:bg-red-600',
          text: t('egg.status.infertile', 'Boş'),
          icon: '❌'
        };
      default:
        return {
          color: 'bg-gray-500 hover:bg-gray-600',
          text: t('egg.status.unknown', 'Belirsiz'),
          icon: '❓'
        };
    }
  };

  const statusConfig = getStatusConfig(egg.status);

  const handleEdit = () => {
    onEditEgg(egg);
  };

  const handleDelete = () => {
    onDeleteEgg(egg.id, egg.eggNumber);
  };

  return (
    <Card className="hover:shadow-md transition-shadow duration-200">
      <CardContent className="p-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4 flex-1">
            {/* Yumurta Numarası */}
            <div className="flex items-center gap-2">
              <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
                <Hash className="w-4 h-4 text-primary" />
                <span className="text-sm font-bold text-primary ml-1">
                  {egg.eggNumber}
                </span>
              </div>
            </div>

            {/* Durum Badge */}
            <Badge className={`text-white ${statusConfig.color} flex items-center gap-1`}>
              <span>{statusConfig.icon}</span>
              <span>{statusConfig.text}</span>
            </Badge>

            {/* Tarih Bilgisi */}
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <Calendar className="w-4 h-4" />
              <span>{formatDate(egg.startDate)}</span>
            </div>

            {/* Notlar (varsa) */}
            {egg.notes && (
              <div className="flex-1 max-w-xs">
                <p className="text-sm text-muted-foreground truncate" title={egg.notes}>
                  {egg.notes}
                </p>
              </div>
            )}
          </div>

          {/* Aksiyon Butonları */}
          <div className="flex gap-2">
            <Button
              variant="ghost"
              size="sm"
              onClick={handleEdit}
              className="h-8 w-8 p-0 hover:bg-blue-50"
            >
              <Edit className="w-4 h-4 text-blue-600" />
            </Button>
            <Button
              variant="ghost"
              size="sm"
              onClick={handleDelete}
              className="h-8 w-8 p-0 hover:bg-red-50"
            >
              <Trash2 className="w-4 h-4 text-red-600" />
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  );
});

export default EggListItem;
