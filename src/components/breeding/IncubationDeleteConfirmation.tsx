import React, { memo, useCallback, useMemo } from 'react';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { useLanguage } from '@/contexts/LanguageContext';
import IncubationPromptMessages from '../forms/IncubationPromptMessages';

interface IncubationDeleteConfirmationProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  incubationData: {
    name?: string;
    femaleBird?: string;
    maleBird?: string;
    startDate?: string;
  };
}

const IncubationDeleteConfirmation = memo(({
  isOpen,
  onClose,
  onConfirm,
  incubationData
}: IncubationDeleteConfirmationProps) => {
  const { t } = useLanguage();
  const [confirmText, setConfirmText] = React.useState('');
  const [isConfirmed, setIsConfirmed] = React.useState(false);

  React.useEffect(() => {
    const isValid = confirmText.toLowerCase() === 'sil';
    setIsConfirmed(isValid);
  }, [confirmText]);

  const handleConfirm = useCallback(() => {
    if (isConfirmed) {
      onConfirm();
      setConfirmText('');
    }
  }, [isConfirmed, onConfirm]);

  const handleClose = useCallback(() => {
    setConfirmText('');
    setIsConfirmed(false);
    onClose();
  }, [onClose]);

  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && isConfirmed) {
      e.preventDefault();
      handleConfirm();
    }
  }, [isConfirmed, handleConfirm]);

  const formattedStartDate = useMemo(() => {
    if (!incubationData.startDate) return '';
    return new Date(incubationData.startDate).toLocaleDateString('tr-TR');
  }, [incubationData.startDate]);

  return (
    <AlertDialog open={isOpen} onOpenChange={handleClose}>
      <AlertDialogContent className="max-w-md mx-auto" role="alertdialog" aria-labelledby="delete-title" aria-describedby="delete-description">
        <AlertDialogHeader>
          <AlertDialogTitle id="delete-title" className="text-red-600">
            🗑️ {t('breeding.deleteBreeding')}
          </AlertDialogTitle>
          <AlertDialogDescription id="delete-description">
            {t('breeding.confirmDelete')} {t('breeding.deleteDescription')}
          </AlertDialogDescription>
        </AlertDialogHeader>
        
        <div className="space-y-4">
          <div className="bg-destructive/10 p-4 rounded-lg border border-destructive/20">
            <div className="flex items-start gap-3">
              <div className="text-2xl" aria-hidden="true">⚠️</div>
              <div className="space-y-3">
                <h4 className="font-semibold text-destructive">{t('breeding.deleteDescription')}</h4>
                <div className="space-y-2">
                  <p className="text-sm font-medium">{t('breeding.deleteDescription')}:</p>
                  <ul className="text-sm space-y-1 list-disc list-inside text-muted-foreground pl-2">
                    <li>{t('breeding.title')} {t('breeding.status')}: <strong>{incubationData.name}</strong></li>
                    <li>{t('breeding.addEgg')}</li>
                    <li>{t('chicks.title')}</li>
                    <li>{t('calendar.title')} {t('calendar.addEvent')}</li>
                  </ul>
                  <div className="mt-3 p-2 bg-muted rounded text-xs">
                    <p><strong>{t('breeding.femaleBird')}:</strong> {incubationData.femaleBird} × {incubationData.maleBird}</p>
                    <p><strong>{t('breeding.pairDate')}:</strong> {formattedStartDate}</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
          <IncubationPromptMessages 
            type="delete"
            incubationData={incubationData}
          />
          
          <div className="space-y-2">
            <Label htmlFor="confirm-text" className="text-sm font-medium">
              {t('breeding.confirmDelete')} <strong>"SİL"</strong>:
            </Label>
            <Input
              id="confirm-text"
              value={confirmText}
              onChange={(e) => setConfirmText(e.target.value)}
              onKeyDown={handleKeyDown}
              placeholder="SİL yazın"
              className="text-center font-medium"
              autoComplete="off"
              aria-describedby="confirm-help"
            />
            <p id="confirm-help" className="text-xs text-muted-foreground">
              {t('breeding.deleteDescription')}
            </p>
          </div>
        </div>

        <AlertDialogFooter className="flex gap-2">
          <AlertDialogCancel onClick={handleClose}>
            {t('breeding.cancel')}
          </AlertDialogCancel>
          <AlertDialogAction
            onClick={handleConfirm}
            disabled={!isConfirmed}
            className="bg-red-600 hover:bg-red-700 disabled:bg-gray-300"
            aria-label={isConfirmed ? t('breeding.deleteBreeding') : t('breeding.deleteDescription')}
          >
            {t('breeding.deleteBreeding')}
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
});

IncubationDeleteConfirmation.displayName = 'IncubationDeleteConfirmation';

export default IncubationDeleteConfirmation;
