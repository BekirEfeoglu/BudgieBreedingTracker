import React, { memo, useMemo } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { X } from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';
import { Bird } from '@/types';
import BirdPhoto from '@/components/bird-detail/BirdPhoto';
import BirdBasicInfo from '@/components/bird-detail/BirdBasicInfo';
import BirdFamilyInfo from '@/components/bird-detail/BirdFamilyInfo';
import BirdHealthNotes from '@/components/bird-detail/BirdHealthNotes';
import BirdActionButtons from '@/components/bird-detail/BirdActionButtons';

interface BirdDetailModalProps {
  bird: Bird | null;
  isOpen: boolean;
  onClose: () => void;
  onEdit: (bird: Bird) => void;
  onDelete: (birdId: string) => void;
  existingBirds: Bird[];
}

const BirdDetailModal = memo(({ bird, isOpen, onClose, onEdit, onDelete, existingBirds }: BirdDetailModalProps) => {
  const { t } = useLanguage();

  // Tüm hook'lar koşulsuz çağrılır
  const genderIcon = useMemo(() => {
    if (!bird) return '';
    return bird.gender === 'male' ? t('birds.maleIcon') : 
           bird.gender === 'female' ? t('birds.femaleIcon') : 
           t('birds.unknownIcon');
  }, [bird, t]);

  const genderColor = useMemo(() => {
    if (!bird) return '';
    return bird.gender === 'male' ? 'text-blue-600' : 
           bird.gender === 'female' ? 'text-pink-600' : 
           'text-gray-600';
  }, [bird, t]);

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Escape') {
      e.preventDefault();
      onClose();
    }
  };

  // Koşullu render hook'lardan sonra
  if (!bird) return null;

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent 
        className="max-w-md mx-auto max-h-[90vh] overflow-y-auto sm:max-w-md max-w-[95vw] sm:max-h-[90vh] max-h-[95vh]"
        aria-describedby="bird-detail-description"
        onKeyDown={handleKeyDown}
      >
        <DialogHeader>
          <DialogTitle className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className={`text-xl ${genderColor}`} aria-label={`${t(`birds.${bird.gender}`)} cinsiyet`}>
                {genderIcon}
              </span>
              <span>{bird.name}</span>
            </div>
            <Button 
              variant="ghost" 
              size="icon" 
              onClick={onClose}
              aria-label={t('birds.cancel')}
              className="min-h-[44px] min-w-[44px]"
            >
              <X className="w-4 h-4" aria-hidden="true" />
            </Button>
          </DialogTitle>
          <DialogDescription>
            {bird.name} detaylarını görüntüleyin, düzenleyin veya silin.
          </DialogDescription>
          <div id="bird-detail-description" className="sr-only">
            {bird.name} {t('birds.birdDetailsDescription')}
          </div>
        </DialogHeader>

        <div className="space-y-4 mobile-spacing-y">
          <BirdPhoto bird={bird} />
          <BirdBasicInfo bird={bird} />
          <BirdFamilyInfo bird={bird} existingBirds={existingBirds} />
          <BirdHealthNotes healthNotes={bird.healthNotes || ''} />
          <BirdActionButtons 
            bird={bird} 
            onEdit={onEdit} 
            onDelete={onDelete} 
            onClose={onClose} 
          />
        </div>
      </DialogContent>
    </Dialog>
  );
});

BirdDetailModal.displayName = 'BirdDetailModal';

export default BirdDetailModal;
