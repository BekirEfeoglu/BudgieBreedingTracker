import React, { useState, memo, useCallback, useMemo } from 'react';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Trash2, Check, X } from 'lucide-react';
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
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { useEggStatusOperations } from '@/hooks/egg/useEggStatusOperations';
import { Egg, EggStatus } from '@/types';

interface EggCardProps {
  egg: Egg;
  breedingId: string;
  _onEdit: (breedingId: string, egg: Egg) => void;
  onDelete: (eggId: string, eggNumber: number) => void;
  onStatusChange: (eggId: string, newStatus: string) => void;
}

const EggCard = memo(({ egg, breedingId, _onEdit, onDelete, onStatusChange }: EggCardProps) => {
  const { t } = useLanguage();
  const [showStatusMenu, setShowStatusMenu] = useState(false);
  const [currentStatus, setCurrentStatus] = useState(egg.status);
  const { updateEggStatus, isUpdating } = useEggStatusOperations();

  const getEggStatusColor = useCallback((status: string) => {
    switch (status) {
      case 'fertile': return 'bg-green-500';
      case 'infertile': return 'bg-red-500';
      case 'hatched': return 'bg-blue-500';
      case 'laid': return 'bg-yellow-500';
      default: return 'bg-gray-400';
    }
  }, []);

  const getEggStatusText = useCallback((status: string) => {
    switch (status) {
      case 'fertile': return t('breeding.fertile');
      case 'infertile': return t('breeding.infertile');
      case 'hatched': return t('breeding.hatched');
      case 'laid': return t('breeding.laid', 'Yatırıldı');
      default: return t('breeding.unknown');
    }
  }, [t]);

  const calculateDaysFromAddition = useCallback((dateAdded: string | undefined) => {
    if (!dateAdded) return 0;
    const added = new Date(dateAdded);
    const now = new Date();
    const diffTime = now.getTime() - added.getTime();
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  }, []);

  const handleStatusChange = useCallback(async (newStatus: string) => {
    // Update local state immediately for instant visual feedback
    const previousStatus = currentStatus;
    setCurrentStatus(newStatus as EggStatus);
    setShowStatusMenu(false);
    
    // Use the hook for database operations
    const success = await updateEggStatus(egg.id, newStatus, breedingId);
    
    if (!success) {
      // Revert local state if database update failed
      setCurrentStatus(previousStatus);
    } else {
      // Call parent handler for any additional UI updates
      onStatusChange(egg.id, newStatus);
    }
  }, [currentStatus, updateEggStatus, egg.id, breedingId, onStatusChange]);

  const handleDelete = useCallback(() => {
    console.log('🗑️ EggCard.handleDelete - Yumurta silme butonuna tıklandı:', {
      eggId: egg.id,
      eggNumber: egg.number,
      eggStatus: egg.status,
      breedingId
    });
    onDelete(egg.id, egg.number);
  }, [onDelete, egg.id, egg.number, egg.status, breedingId]);

  const daysFromAddition = useMemo(() => 
    calculateDaysFromAddition(egg.dateAdded || egg.layDate), 
    [calculateDaysFromAddition, egg.dateAdded, egg.layDate]
  );

  const handleKeyDown = useCallback((e: React.KeyboardEvent, action: () => void) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      action();
    }
  }, []);

  return (
    <div className="relative border rounded-lg p-3 hover:bg-muted/50 transition-colors min-h-[120px] flex flex-col" role="article" aria-label={`${egg.number}. yumurta`}>
      {/* Header with egg number and actions */}
      <div className="flex items-center justify-between mb-2">
        <div className={`w-8 h-10 rounded-full ${getEggStatusColor(currentStatus)} flex items-center justify-center text-white text-xs font-medium shadow-sm transition-colors duration-200`}>
          {egg.number}
        </div>
        <div className="flex gap-1">
          <AlertDialog>
            <AlertDialogTrigger asChild>
              <Button
                variant="ghost"
                size="sm"
                className="h-8 w-8 p-0 text-red-600 hover:text-red-800 hover:bg-red-50 touch-target"
                disabled={isUpdating}
                aria-label={t('breeding.deleteEgg')}
              >
                <Trash2 className="w-4 h-4" aria-hidden="true" />
              </Button>
            </AlertDialogTrigger>
            <AlertDialogContent>
              <AlertDialogHeader>
                <AlertDialogTitle>{t('breeding.deleteEgg')}</AlertDialogTitle>
                <AlertDialogDescription>
                  {egg.number}. {t('breeding.confirmEggDelete')} 
                  {t('breeding.eggDeleteDescription')}
                </AlertDialogDescription>
              </AlertDialogHeader>
              <AlertDialogFooter>
                <AlertDialogCancel>{t('breeding.cancel')}</AlertDialogCancel>
                <AlertDialogAction 
                  onClick={handleDelete}
                  className="bg-red-600 hover:bg-red-700"
                >
                  {t('breeding.delete')}
                </AlertDialogAction>
              </AlertDialogFooter>
            </AlertDialogContent>
          </AlertDialog>
          <DropdownMenu open={showStatusMenu} onOpenChange={setShowStatusMenu}>
            <DropdownMenuTrigger asChild>
              <Button
                variant="ghost"
                size="sm"
                className="h-8 w-8 p-0 text-amber-600 hover:text-amber-800 hover:bg-amber-50 touch-target"
                disabled={isUpdating}
                aria-label={t('breeding.selectStatus')}
              >
                🥚
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="w-56 bg-background border shadow-lg z-50">
              <DropdownMenuItem 
                onClick={() => handleStatusChange('fertile')} 
                className="text-green-600 hover:text-green-600 hover:bg-green-50 cursor-pointer py-3"
                onKeyDown={(e) => handleKeyDown(e, () => handleStatusChange('fertile'))}
              >
                <Check className="w-4 h-4 mr-2" aria-hidden="true" />
                {t('breeding.fertile')} {t('breeding.selectStatus')}
              </DropdownMenuItem>
              <DropdownMenuItem 
                onClick={() => handleStatusChange('hatched')} 
                className="text-blue-600 hover:text-blue-600 hover:bg-blue-50 cursor-pointer py-3"
                onKeyDown={(e) => handleKeyDown(e, () => handleStatusChange('hatched'))}
              >
                🐣 {t('breeding.hatched')} {t('breeding.selectStatus')}
              </DropdownMenuItem>
              <DropdownMenuItem 
                onClick={() => handleStatusChange('infertile')} 
                className="text-red-600 hover:text-red-600 hover:bg-red-50 cursor-pointer py-3"
                onKeyDown={(e) => handleKeyDown(e, () => handleStatusChange('infertile'))}
              >
                <X className="w-4 h-4 mr-2" aria-hidden="true" />
                {t('breeding.infertile')} {t('breeding.selectStatus')}
              </DropdownMenuItem>
              <DropdownMenuItem 
                onClick={() => handleStatusChange('laid')} 
                className="text-yellow-600 hover:text-yellow-600 hover:bg-yellow-50 cursor-pointer py-3"
                onKeyDown={(e) => handleKeyDown(e, () => handleStatusChange('laid'))}
              >
                🥚 {t('breeding.laid', 'Yatırıldı')} {t('breeding.selectStatus')}
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      </div>

      {/* Status and progress info */}
      <div className="flex-1 flex flex-col justify-center items-center text-center space-y-2">
        <Badge 
          variant="secondary" 
          className={`text-xs px-2 py-1 transition-colors duration-200 ${
            currentStatus === 'fertile' ? 'bg-green-100 text-green-800' :
            currentStatus === 'infertile' ? 'bg-red-100 text-red-800' :
            currentStatus === 'hatched' ? 'bg-blue-100 text-blue-800' :
            currentStatus === 'laid' ? 'bg-yellow-100 text-yellow-800' :
            'bg-gray-100 text-gray-800'
          }`}
        >
          {getEggStatusText(currentStatus)}
        </Badge>
        
        {/* Days information */}
        {currentStatus !== 'hatched' && (
          <div className="text-xs text-muted-foreground">
            {daysFromAddition} {t('breeding.days')}
          </div>
        )}
      </div>
    </div>
  );
});

EggCard.displayName = 'EggCard';

export default EggCard;
