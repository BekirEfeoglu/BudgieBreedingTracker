import React, { memo, useCallback, useMemo } from 'react';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Edit, Trash2, Calendar, MoreVertical, Eye } from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from '@/components/ui/alert-dialog';
import { Bird } from '@/types';
import { getAgeCategoryIcon, getAgeCategoryLabel, getDetailedAge } from '@/utils/dateUtils';
import { resolveAgeCategoryKey, normalizeAgeCategory, extractAgeCategory } from '@/utils/translationHelpers';
import ComponentErrorBoundary from '@/components/errors/ComponentErrorBoundary';

interface BirdCardProps {
  bird: Bird;
  onEdit: (bird: Bird) => void;
  onDelete: (birdId: string) => void;
  onViewDetails: (bird: Bird) => void;
  birds?: Bird[];
}

const BirdCard = memo(({ bird, onEdit, onDelete, onViewDetails, birds }: BirdCardProps) => {
  const { t } = useLanguage();

  // Memoized calculations for better performance
  const birdInfo = useMemo(() => {
    const calculateAge = () => {
      if (!bird.birthDate) return null;
      
      const birth = new Date(bird.birthDate);
      const now = new Date();
      const diffTime = now.getTime() - birth.getTime();
      const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
      
      if (diffDays < 30) return `${diffDays} ${t('birds.days')}`;
      if (diffDays < 365) return `${Math.floor(diffDays / 30)} ${t('birds.months')}`;
      return `${Math.floor(diffDays / 365)} ${t('birds.years')}`;
    };

    const ageInfo = bird.birthDate ? getDetailedAge(bird.birthDate) : null;
    const genderIcon = bird.gender === 'male' ? t('birds.maleIcon') : 
                      bird.gender === 'female' ? t('birds.femaleIcon') : 
                      t('birds.unknownIcon');
    
    const genderColor = bird.gender === 'male' ? 'text-blue-600' : 
                       bird.gender === 'female' ? 'text-pink-600' : 
                       'text-gray-600';

    const formattedBirthDate = bird.birthDate ? new Date(bird.birthDate).toLocaleDateString('tr-TR') : null;

    // Find parent names efficiently
    const findParentName = (parentId?: string) => {
      if (!parentId || !birds) return t('birds.notSpecified', 'Belirtilmemiş');
      if (parentId === bird.id) return t('birds.invalidParent', 'Geçersiz veri');
      const parent = birds.find(b => b.id === parentId);
      return parent?.name || t('birds.notSpecified', 'Belirtilmemiş');
    };

    return {
      age: calculateAge(),
      ageInfo,
      genderIcon,
      genderColor,
      formattedBirthDate,
      motherName: findParentName(bird.motherId),
      fatherName: findParentName(bird.fatherId)
    };
  }, [bird, birds, t]);

  const handleEdit = useCallback((e: React.MouseEvent) => {
    e.stopPropagation();
    onEdit(bird);
  }, [onEdit, bird]);

  const handleDelete = useCallback((e: React.MouseEvent) => {
    e.stopPropagation();
    onDelete(bird.id);
  }, [onDelete, bird.id]);

  const handleViewDetails = useCallback(() => {
    onViewDetails(bird);
  }, [onViewDetails, bird]);

  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      handleViewDetails();
    }
  }, [handleViewDetails]);

  return (
    <ComponentErrorBoundary>
      <Card 
        className="budgie-card p-3 sm:p-4 animate-fade-in cursor-pointer hover:shadow-lg transition-shadow" 
        role="article" 
        aria-label={`${bird.name} kuşu`}
        tabIndex={0}
        onClick={handleViewDetails}
        onKeyDown={handleKeyDown}
      >
        <div className="flex items-start gap-3 sm:gap-4">
          <div className="w-16 h-16 rounded-full bg-gradient-to-br from-budgie-green to-budgie-yellow flex items-center justify-center text-2xl shadow-lg flex-shrink-0" aria-hidden="true">
            {bird.photo ? (
              <img 
                src={bird.photo} 
                alt={bird.name}
                className="w-full h-full rounded-full object-cover"
                loading="lazy"
              />
            ) : (
              (() => {
                if (bird.birthDate) {
                  const birth = new Date(bird.birthDate);
                  const now = new Date();
                  const diffMonths = (now.getFullYear() - birth.getFullYear()) * 12 + (now.getMonth() - birth.getMonth());
                  return diffMonths < 6 ? '🐣' : '🦜';
                }
                return '🦜';
              })()
            )}
          </div>
          
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 mb-2">
              <h3 className="font-semibold text-lg truncate max-w-[140px] sm:max-w-xs">{bird.name}</h3>
              <span className={`text-lg ${birdInfo.genderColor} flex-shrink-0`} aria-label={`${t(`birds.${bird.gender}`)} cinsiyet`}>
                {birdInfo.genderIcon}
              </span>
              {birdInfo.ageInfo && (
                <span 
                  className="text-lg flex-shrink-0" 
                  aria-label={`${birdInfo.ageInfo.category === 'chick' ? 'Yavru' : 'Yetişkin'} yaş kategorisi`}
                  title={birdInfo.ageInfo.category === 'chick' ? 'Yavru' : 'Yetişkin'}
                >
                  {birdInfo.ageInfo.icon}
                </span>
              )}
            </div>
            
            <div className="badge-container mb-3">
              {bird.color && (
                <Badge variant="secondary" className="text-xs truncate max-w-[80px] badge-item">
                  {bird.color}
                </Badge>
              )}
              {birdInfo.age && (
                <Badge variant="outline" className="text-xs truncate max-w-[60px] badge-item">
                  {birdInfo.age}
                </Badge>
              )}
              {bird.ringNumber && (
                <Badge variant="outline" className="text-xs truncate max-w-[60px] badge-item">
                  #{bird.ringNumber}
                </Badge>
              )}
            </div>
            
            {/* Anne ve baba bilgileri için ayrı satır */}
            <div className="parent-info-container mb-3">
              <div className="parent-info-item">
                <span className="parent-info-label">{t('birds.mother')}:</span>
                <span className="parent-info-value">{birdInfo.motherName}</span>
              </div>
              <div className="parent-info-item">
                <span className="parent-info-label">{t('birds.father')}:</span>
                <span className="parent-info-value">{birdInfo.fatherName}</span>
              </div>
            </div>
            
            {birdInfo.formattedBirthDate && (
              <div className="flex items-center gap-1 text-xs text-muted-foreground mb-2">
                <Calendar className="w-3 h-3" aria-hidden="true" />
                <span>{birdInfo.formattedBirthDate}</span>
              </div>
            )}
            
            {bird.healthNotes && (
              <p className="text-xs text-muted-foreground line-clamp-2 max-w-[180px] sm:max-w-full">
                {bird.healthNotes}
              </p>
            )}
            
            <div className="flex gap-2 mt-3">
              <Button
                size="sm"
                variant="outline"
                onClick={handleViewDetails}
                className="flex-1 min-h-[44px] min-w-[44px] text-xs sm:text-sm"
                aria-label={`${bird.name} detaylarını görüntüle`}
              >
                <Eye className="w-3 h-3 mr-1 sm:mr-2" aria-hidden="true" />
                <span className="hidden sm:inline">{t('birds.viewDetails', 'Detaylar')}</span>
                <span className="sm:hidden">Detay</span>
              </Button>
              <Button
                size="sm"
                variant="outline"
                onClick={handleEdit}
                className="min-h-[44px] min-w-[44px]"
                aria-label={`${bird.name} kuşunu düzenle`}
              >
                <Edit className="w-3 h-3" aria-hidden="true" />
              </Button>
              <Button
                size="sm"
                variant="outline"
                onClick={handleDelete}
                className="text-red-600 hover:text-red-700 hover:bg-red-50 min-h-[44px] min-w-[44px]"
                aria-label={`${bird.name} kuşunu sil`}
              >
                <Trash2 className="w-3 h-3" aria-hidden="true" />
              </Button>
            </div>
          </div>
        </div>
      
      {/* Mobil için dropdown menü */}
      <div className="flex justify-end mt-3 sm:hidden">
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button 
              variant="ghost" 
              size="sm" 
              onClick={(e) => e.stopPropagation()}
              aria-label={t('birds.edit')}
            >
              <MoreVertical className="w-4 h-4" aria-hidden="true" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="bg-background border shadow-lg">
            <DropdownMenuItem onClick={handleEdit}>
              <Edit className="w-4 h-4 mr-2" aria-hidden="true" />
              {t('birds.edit')}
            </DropdownMenuItem>
            <DropdownMenuItem asChild>
              <AlertDialog>
                <AlertDialogTrigger asChild>
                  <div className="flex items-center w-full px-2 py-1.5 text-sm cursor-pointer hover:bg-accent rounded-sm text-destructive">
                    <Trash2 className="w-4 h-4 mr-2" aria-hidden="true" />
                    {t('birds.delete')}
                  </div>
                </AlertDialogTrigger>
                <AlertDialogContent onClick={(e) => e.stopPropagation()}>
                  <AlertDialogHeader>
                    <AlertDialogTitle>{t('birds.deleteBird')}</AlertDialogTitle>
                    <AlertDialogDescription>
                      "{bird.name}" {t('birds.confirmDelete')} {t('birds.deleteDescription')}
                    </AlertDialogDescription>
                  </AlertDialogHeader>
                  <AlertDialogFooter>
                    <AlertDialogCancel>{t('birds.cancel')}</AlertDialogCancel>
                    <AlertDialogAction onClick={handleDelete} className="bg-destructive text-destructive-foreground hover:bg-destructive/90">
                      {t('birds.delete')}
                    </AlertDialogAction>
                  </AlertDialogFooter>
                </AlertDialogContent>
              </AlertDialog>
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>

      {/* Desktop için butonlar */}
      <div className="hidden sm:flex justify-end gap-2 mt-3">
        <Button
          variant="ghost"
          size="sm"
          onClick={handleEdit}
          aria-label={t('birds.edit')}
        >
          <Edit className="w-4 h-4" aria-hidden="true" />
        </Button>
        <AlertDialog>
          <AlertDialogTrigger asChild>
            <Button
              variant="ghost"
              size="sm"
              onClick={(e) => e.stopPropagation()}
              aria-label={t('birds.delete')}
            >
              <Trash2 className="w-4 h-4 text-destructive" aria-hidden="true" />
            </Button>
          </AlertDialogTrigger>
          <AlertDialogContent onClick={(e) => e.stopPropagation()}>
            <AlertDialogHeader>
              <AlertDialogTitle>{t('birds.deleteBird')}</AlertDialogTitle>
              <AlertDialogDescription>
                "{bird.name}" {t('birds.confirmDelete')} {t('birds.deleteDescription')}
              </AlertDialogDescription>
            </AlertDialogHeader>
            <AlertDialogFooter>
              <AlertDialogCancel>{t('birds.cancel')}</AlertDialogCancel>
              <AlertDialogAction onClick={handleDelete} className="bg-destructive text-destructive-foreground hover:bg-destructive/90">
                {t('birds.delete')}
              </AlertDialogAction>
            </AlertDialogFooter>
          </AlertDialogContent>
        </AlertDialog>
      </div>
    </Card>
    </ComponentErrorBoundary>
  );
});

BirdCard.displayName = 'BirdCard';

// Performance optimization: Only re-render if props actually changed
export default memo(BirdCard, (prevProps, nextProps) => {
  return (
    prevProps.bird.id === nextProps.bird.id &&
    prevProps.bird.name === nextProps.bird.name &&
    prevProps.bird.gender === nextProps.bird.gender &&
    prevProps.bird.birthDate === nextProps.bird.birthDate &&
    prevProps.bird.color === nextProps.bird.color &&
    prevProps.bird.ringNumber === nextProps.bird.ringNumber &&
    prevProps.bird.photo === nextProps.bird.photo &&
    prevProps.bird.healthNotes === nextProps.bird.healthNotes &&
    prevProps.bird.motherId === nextProps.bird.motherId &&
    prevProps.bird.fatherId === nextProps.bird.fatherId &&
    prevProps.birds?.length === nextProps.birds?.length
  );
});
