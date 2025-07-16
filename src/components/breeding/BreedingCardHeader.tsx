import React, { memo } from 'react';
import { Button } from '@/components/ui/button';
import { Edit, Trash2 } from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from '@/components/ui/alert-dialog';
import { Bird, Egg } from '@/types';

interface BreedingRecord {
  id: string;
  nestName: string;
  maleBird: string;
  femaleBird: string;
  startDate: string;
  eggs: Egg[];
}

interface BreedingCardHeaderProps {
  breeding: BreedingRecord;
  onEdit: (breeding: BreedingRecord) => void;
  onDelete: (breedingId: string) => void;
}

const BreedingCardHeader = memo(({ breeding, onEdit, onDelete }: BreedingCardHeaderProps) => {
  const { t } = useLanguage();

  const handleKeyDown = (e: React.KeyboardEvent, action: () => void) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      action();
    }
  };

  return (
    <div className="flex items-start justify-between mb-4 gap-3">
      <div className="flex-1 min-w-0">
        <h3 className="font-semibold text-lg mb-1 break-words hyphens-auto">
          {breeding.nestName}
        </h3>
        <div className="text-sm text-muted-foreground space-y-1">
          <p className="break-words">
            <span className="font-medium">{t('breeding.maleBird')}:</span> {breeding.maleBird}
          </p>
          <p className="break-words">
            <span className="font-medium">{t('breeding.femaleBird')}:</span> {breeding.femaleBird}
          </p>
        </div>
      </div>
      <div className="flex gap-2 flex-shrink-0">
        <Button
          variant="ghost"
          size="sm"
          onClick={() => onEdit(breeding)}
          onKeyDown={(e) => handleKeyDown(e, () => onEdit(breeding))}
          className="text-blue-600 hover:text-blue-800 h-8 w-8 p-0"
          aria-label={t('breeding.edit')}
        >
          <Edit className="w-4 h-4" aria-hidden="true" />
        </Button>
        <AlertDialog>
          <AlertDialogTrigger asChild>
            <Button
              variant="ghost"
              size="sm"
              className="text-red-600 hover:text-red-800 h-8 w-8 p-0"
              aria-label={t('breeding.delete')}
            >
              <Trash2 className="w-4 h-4" aria-hidden="true" />
            </Button>
          </AlertDialogTrigger>
          <AlertDialogContent>
            <AlertDialogHeader>
              <AlertDialogTitle>{t('breeding.deleteBreeding')}</AlertDialogTitle>
              <AlertDialogDescription>
                "{breeding.nestName}" {t('breeding.confirmDelete')} 
                {t('breeding.deleteDescription')}
              </AlertDialogDescription>
            </AlertDialogHeader>
            <AlertDialogFooter>
              <AlertDialogCancel>{t('breeding.cancel')}</AlertDialogCancel>
              <AlertDialogAction 
                onClick={() => onDelete(breeding.id)} 
                className="bg-red-600 hover:bg-red-700"
              >
                {t('breeding.delete')}
              </AlertDialogAction>
            </AlertDialogFooter>
          </AlertDialogContent>
        </AlertDialog>
      </div>
    </div>
  );
});

BreedingCardHeader.displayName = 'BreedingCardHeader';

export default BreedingCardHeader;
