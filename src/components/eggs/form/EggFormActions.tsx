
import React from 'react';
import { useLanguage } from '@/contexts/LanguageContext';
import { Button } from '@/components/ui/button';
import { EggWithClutch } from '@/types/egg';

interface EggFormActionsProps {
  isSubmitting: boolean;
  editingEgg?: EggWithClutch | null;
  onCancel: () => void;
}

const EggFormActions: React.FC<EggFormActionsProps> = ({
  isSubmitting,
  editingEgg,
  onCancel
}) => {
  const { t } = useLanguage();
  const isEditing = !!editingEgg;

  return (
    <div className="flex gap-2 pt-4">
      <Button
        type="submit"
        disabled={isSubmitting}
        className="flex-1"
      >
        {isSubmitting ? (
          <>
            <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2" />
            {t('common.saving', 'Kaydediliyor...')}
          </>
        ) : (
          isEditing ? t('common.update', 'Güncelle') : t('common.add', 'Ekle')
        )}
      </Button>
      <Button
        type="button"
        variant="outline"
        onClick={onCancel}
        disabled={isSubmitting}
      >
        {t('common.cancel', 'İptal')}
      </Button>
    </div>
  );
};

export default EggFormActions;
