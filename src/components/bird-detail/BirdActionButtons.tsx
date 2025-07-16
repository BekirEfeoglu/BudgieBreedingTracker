import React, { memo, useCallback } from 'react';
import { Button } from '@/components/ui/button';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from '@/components/ui/alert-dialog';
import { Edit, Trash2 } from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';
import { Bird } from '@/types';

interface BirdActionButtonsProps {
  bird: Bird;
  onEdit: (bird: Bird) => void;
  onDelete: (birdId: string) => void;
  onClose: () => void;
}

const BirdActionButtons = memo(({ bird, onEdit, onDelete, onClose }: BirdActionButtonsProps) => {
  const { t } = useLanguage();

  const handleDelete = useCallback(() => {
    onDelete(bird.id);
    onClose();
  }, [onDelete, bird.id, onClose]);

  const handleEdit = useCallback(() => {
    onEdit(bird);
  }, [onEdit, bird]);

  const handleKeyDown = useCallback((e: React.KeyboardEvent, action: () => void) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      action();
    }
  }, []);

  return (
    <div className="flex space-x-2 pt-4" role="group" aria-label="Kuş işlem butonları">
      <Button
        onClick={handleEdit}
        onKeyDown={(e) => handleKeyDown(e, handleEdit)}
        className="flex-1 budgie-button"
        aria-label={t('birds.edit')}
      >
        <Edit className="w-4 h-4 mr-2" aria-hidden="true" />
        {t('birds.edit')}
      </Button>
      
      <AlertDialog>
        <AlertDialogTrigger asChild>
          <Button 
            variant="destructive" 
            className="flex-1"
            aria-label={t('birds.delete')}
          >
            <Trash2 className="w-4 h-4 mr-2" aria-hidden="true" />
            {t('birds.delete')}
          </Button>
        </AlertDialogTrigger>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>{t('birds.deleteBird')}</AlertDialogTitle>
            <AlertDialogDescription>
              "{bird.name}" {t('birds.confirmDelete')} {t('birds.deleteDescription')}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>{t('birds.cancel')}</AlertDialogCancel>
            <AlertDialogAction 
              onClick={handleDelete} 
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              {t('birds.delete')}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
});

BirdActionButtons.displayName = 'BirdActionButtons';

export default BirdActionButtons;
