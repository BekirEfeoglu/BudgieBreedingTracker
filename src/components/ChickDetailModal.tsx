import React, { useMemo } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from '@/components/ui/alert-dialog';
import { Edit, Trash2, Calendar, User } from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';
import { Bird, Chick } from '@/types';

interface ChickDetailModalProps {
  chick: Chick | null;
  birds: Bird[];
  isOpen: boolean;
  onClose: () => void;
  onEdit: (chick: Chick) => void;
  onDelete: (chickId: string) => void;
}

const ChickDetailModal: React.FC<ChickDetailModalProps> = ({
  chick,
  birds,
  isOpen,
  onClose,
  onEdit,
  onDelete
}) => {
  const { t } = useLanguage();

  // Move all useMemo hooks to the top level, before any conditional returns
  const calculateAge = useMemo(() => {
    if (!chick) return '';
    const birth = new Date(chick.hatchDate);
    const now = new Date();
    const diffTime = now.getTime() - birth.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    
    if (diffDays < 30) return `${diffDays} ${t('chicks.days')}`;
    if (diffDays < 365) return `${Math.floor(diffDays / 30)} ${t('chicks.months')}`;
    return `${Math.floor(diffDays / 365)} ${t('chicks.years')}`;
  }, [chick?.hatchDate, t]);

  const getAgeStage = useMemo(() => {
    if (!chick) return { stage: '', color: '' };
    const birth = new Date(chick.hatchDate);
    const now = new Date();
    const diffTime = now.getTime() - birth.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    
    if (diffDays <= 7) return { stage: t('chicks.ageStages.newborn'), color: 'bg-pink-500' };
    if (diffDays <= 21) return { stage: t('chicks.ageStages.nestling'), color: 'bg-orange-500' };
    if (diffDays <= 35) return { stage: t('chicks.ageStages.fledging'), color: 'bg-yellow-500' };
    if (diffDays <= 60) return { stage: t('chicks.ageStages.learning'), color: 'bg-green-500' };
    return { stage: t('chicks.ageStages.young'), color: 'bg-blue-500' };
  }, [chick?.hatchDate, t]);

  const getParentName = useMemo(() => (parentId?: string) => {
    if (!parentId) return t('chicks.unknownParent');
    const parent = birds.find(bird => bird.id === parentId);
    return parent?.name || t('chicks.unknownParent');
  }, [birds, t]);

  const getGenderIcon = useMemo(() => (gender: 'male' | 'female' | 'unknown') => {
    switch (gender) {
      case 'male': return '♂';
      case 'female': return '♀';
      default: return '?';
    }
  }, []);

  const getGenderColor = useMemo(() => (gender: 'male' | 'female' | 'unknown') => {
    switch (gender) {
      case 'male': return 'text-blue-500';
      case 'female': return 'text-pink-500';
      default: return 'text-gray-500';
    }
  }, []);

  if (!chick) return null;

  const ageStage = getAgeStage;
  const motherName = getParentName(chick.motherId);
  const fatherName = getParentName(chick.fatherId);

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Escape') {
      onClose();
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent 
        className="max-w-2xl max-h-[90vh] overflow-y-auto sm:max-w-2xl max-w-[95vw] sm:max-h-[90vh] max-h-[95vh]"
        onKeyDown={handleKeyDown}
        aria-describedby="chick-detail-description"
      >
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2 text-xl">
            <span aria-hidden="true">🐣</span> {chick.name}
            <span className={`text-2xl ${getGenderColor(chick.gender)}`} aria-hidden="true">
              {getGenderIcon(chick.gender)}
            </span>
          </DialogTitle>
          <DialogDescription>
            {chick.name} yavru detaylarını görüntüleyin, düzenleyin veya silin.
          </DialogDescription>
          <div id="chick-detail-description" className="sr-only">
            Yavru detayları
          </div>
        </DialogHeader>

        <div className="space-y-6 mobile-spacing-y">
          {/* Fotoğraf Bölümü */}
          <div className="flex justify-center">
            <div className="w-32 h-32 rounded-full bg-gradient-to-br from-budgie-yellow to-budgie-green flex items-center justify-center text-4xl shadow-lg" aria-hidden="true">
              {chick.photo ? (
                <img 
                  src={chick.photo} 
                  alt={chick.name}
                  className="w-full h-full rounded-full object-cover"
                />
              ) : (
                '🐣'
              )}
            </div>
          </div>

          {/* Yaş ve Durum Rozeti */}
          <div className="flex justify-center gap-2 flex-wrap">
            <Badge className={`text-white ${ageStage.color}`}>
              {ageStage.stage}
            </Badge>
            <Badge variant="outline">
              {calculateAge}
            </Badge>
            {chick.gender !== 'unknown' && (
              <Badge variant="secondary">
                {chick.gender === 'male' ? t('chicks.male') : t('chicks.female')}
              </Badge>
            )}
          </div>

          {/* Temel Bilgiler */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mobile-grid">
            <div className="space-y-3">
              <div className="flex items-center gap-2">
                <Calendar className="w-4 h-4 text-muted-foreground" aria-hidden="true" />
                <div>
                  <p className="text-sm font-medium">{t('chicks.birthDate')}</p>
                  <p className="text-sm text-muted-foreground">
                    {new Date(chick.hatchDate).toLocaleDateString('tr-TR')}
                  </p>
                </div>
              </div>

              {chick.color && (
                <div>
                  <p className="text-sm font-medium">{t('chicks.color')}</p>
                  <p className="text-sm text-muted-foreground">{chick.color}</p>
                </div>
              )}

              {chick.ringNumber && (
                <div>
                  <p className="text-sm font-medium">{t('chicks.ringNumber')}</p>
                  <p className="text-sm text-muted-foreground">{chick.ringNumber}</p>
                </div>
              )}
            </div>

            <div className="space-y-3">
              <div className="flex items-center gap-2">
                <User className="w-4 h-4 text-muted-foreground" aria-hidden="true" />
                <div>
                  <p className="text-sm font-medium">{t('chicks.mother')}</p>
                  <p className="text-sm text-muted-foreground">{motherName}</p>
                </div>
              </div>

              <div className="flex items-center gap-2">
                <User className="w-4 h-4 text-muted-foreground" aria-hidden="true" />
                <div>
                  <p className="text-sm font-medium">{t('chicks.father')}</p>
                  <p className="text-sm text-muted-foreground">{fatherName}</p>
                </div>
              </div>
            </div>
          </div>

          {/* Sağlık Notları */}
          {chick.healthNotes && (
            <div>
              <p className="text-sm font-medium mb-2">{t('chicks.healthNotes')}</p>
              <div className="bg-muted p-3 rounded-lg">
                <p className="text-sm text-muted-foreground">{chick.healthNotes}</p>
              </div>
            </div>
          )}

          {/* Eylem Butonları */}
          <div className="flex flex-col sm:flex-row gap-2 pt-4 border-t">
            <Button 
              onClick={() => onEdit(chick)}
              className="flex-1 budgie-button mobile-form-button"
              aria-label={t('chicks.edit')}
            >
              <Edit className="w-4 h-4 mr-2" aria-hidden="true" />
              {t('chicks.edit')}
            </Button>

            <AlertDialog>
              <AlertDialogTrigger asChild>
                <Button variant="destructive" className="flex-1 mobile-form-button" aria-label={t('chicks.delete')}>
                  <Trash2 className="w-4 h-4 mr-2" aria-hidden="true" />
                  {t('chicks.delete')}
                </Button>
              </AlertDialogTrigger>
              <AlertDialogContent>
                <AlertDialogHeader>
                  <AlertDialogTitle>{t('chicks.deleteChick')}</AlertDialogTitle>
                  <AlertDialogDescription>
                    "{chick.name}" {t('chicks.confirmDelete')} 
                    {t('chicks.deleteDescription')}
                  </AlertDialogDescription>
                </AlertDialogHeader>
                <AlertDialogFooter>
                  <AlertDialogCancel>{t('chicks.cancel')}</AlertDialogCancel>
                  <AlertDialogAction 
                    onClick={() => {
                      onDelete(chick.id);
                      onClose();
                    }}
                    className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
                  >
                    {t('chicks.delete')}
                  </AlertDialogAction>
                </AlertDialogFooter>
              </AlertDialogContent>
            </AlertDialog>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
};

ChickDetailModal.displayName = 'ChickDetailModal';

export default ChickDetailModal;
