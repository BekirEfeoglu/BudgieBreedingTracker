import React from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Edit, Trash2 } from 'lucide-react';
import { EggWithClutch } from '@/types/egg';
import { useLanguage } from '@/contexts/LanguageContext';

interface EggListItemProps {
  egg: EggWithClutch;
  onEditEgg: (egg: EggWithClutch) => void;
  onDeleteEgg: (eggId: string, eggNumber: number) => void;
}

const EggListItem: React.FC<EggListItemProps> = ({
  egg,
  onEditEgg,
  onDeleteEgg
}) => {
  const { t } = useLanguage();

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'fertile': return 'bg-green-500';
      case 'hatched': return 'bg-blue-500'; 
      case 'infertile': return 'bg-red-500';
      default: return 'bg-gray-400';
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'laid': return t('egg.status.laid', 'Yumurtlandı');
      case 'fertile': return t('egg.status.fertile', 'Dolu');
      case 'hatched': return t('egg.status.hatched', 'Çıktı');
      case 'infertile': return t('egg.status.infertile', 'Boş');
      default: return t('egg.status.unknown', 'Belirsiz');
    }
  };

  const formatDate = (date: Date | string) => {
    if (!date) return '-';
    const d = typeof date === 'string' ? new Date(date) : date;
    return d.toLocaleDateString('tr-TR');
  };

  const handleEdit = () => {
    onEditEgg(egg);
  };

  const handleDelete = () => {
    if (window.confirm(`${egg.eggNumber}. yumurtayı silmek istediğinizden emin misiniz?`)) {
      onDeleteEgg(egg.id, egg.eggNumber);
    }
  };

  return (
    <Card className="w-full border-l-4 border-l-primary/20 hover:shadow-md transition-shadow">
      <CardContent className="p-4">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2">
          <div className="flex flex-row items-center gap-3 flex-1">
            {/* Yumurta numarası */}
            <div className="w-10 h-10 sm:w-12 sm:h-12 rounded-full bg-primary/10 flex items-center justify-center font-bold text-primary">
              {egg.eggNumber}
            </div>
            
            {/* Yumurta bilgileri */}
            <div className="space-y-1">
              <div className="flex items-center gap-2 flex-wrap">
                <Badge 
                  variant="secondary" 
                  className={`text-white ${getStatusColor(egg.status)}`}
                >
                  {getStatusText(egg.status)}
                </Badge>
                <span className="text-sm text-muted-foreground">
                  {egg.layDate ? formatDate(egg.layDate) : formatDate(egg.startDate)}
                </span>
              </div>
              
              {egg.notes && (
                <p className="text-sm text-muted-foreground line-clamp-1">
                  {egg.notes}
                </p>
              )}
            </div>
          </div>

          {/* Aksiyon butonları */}
          <div className="flex gap-2 mt-2 sm:mt-0">
            <Button
              variant="ghost"
              size="sm"
              onClick={handleEdit}
              className="hover:bg-blue-50 hover:text-blue-600 min-h-[44px] min-w-[44px]"
            >
              <Edit className="w-4 h-4" />
            </Button>
            <Button
              variant="ghost"
              size="sm"
              onClick={handleDelete}
              className="hover:bg-red-50 hover:text-red-600 min-h-[44px] min-w-[44px]"
            >
              <Trash2 className="w-4 h-4" />
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  );
};

export default EggListItem;
