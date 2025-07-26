import React, { memo, useMemo, useCallback, useEffect, useState } from 'react';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from '@/components/ui/alert-dialog';
import { Edit, Calendar, Trash2, UserPlus } from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';
import { Bird, Chick } from '@/types';
import { getAgeCategoryIcon, getAgeCategoryLabel, getDetailedAge } from '@/utils/dateUtils';
import { resolveAgeCategoryKey } from '@/utils/translationHelpers';
import { supabase } from '@/integrations/supabase/client';

// Cinsiyet ikonları ve renkleri için yardımcı fonksiyonlar
const getGenderIcon = (gender: string) => {
  switch (gender) {
    case 'male': return '♂️';
    case 'female': return '♀️';
    default: return '❓';
  }
};

const getGenderColor = (gender: string) => {
  switch (gender) {
    case 'male': return 'text-blue-600';
    case 'female': return 'text-pink-600';
    default: return 'text-gray-500';
  }
};

interface ChickCardProps {
  chick: Chick;
  birds: Bird[];
  onEdit: (chick: Chick) => void;
  onDelete: (chickId: string) => void;
  onClick: (chick: Chick) => void;
  onPromote: (chick: Chick) => void;
}

const ChickCard = memo(({ chick, birds, onEdit, onDelete, onClick, onPromote }: ChickCardProps) => {
  const { t } = useLanguage();
  const [incubationInfo, setIncubationInfo] = useState<{ name: string } | null>(null);
  const [eggInfo, setEggInfo] = useState<{ egg_number: number | null } | null>(null);
  const [parentInfo, setParentInfo] = useState<{ mother: string; father: string } | null>(null);

  // Incubation ve egg bilgilerini çek
  useEffect(() => {
    const fetchAdditionalInfo = async () => {
      try {
        // Incubation bilgilerini çek
        const incubationId = chick.incubationId || chick.incubation_id || chick.breedingId;
        
        if (incubationId) {
          const { data: incubationData, error: incError } = await supabase
            .from('incubations')
            .select(`
              name, 
              id,
              male_bird_id,
              female_bird_id
            `)
            .eq('id', incubationId)
            .maybeSingle();
          
          if (incubationData && incubationData.name) {
            setIncubationInfo(incubationData);
            
            // Anne baba bilgilerini incubation'dan al
            if (incubationData.male_bird_id || incubationData.female_bird_id) {
              const motherName = incubationData.female_bird_id ? 
                birds.find(b => b.id === incubationData.female_bird_id)?.name || 'Bilinmeyen' : 'Bilinmeyen';
              const fatherName = incubationData.male_bird_id ? 
                birds.find(b => b.id === incubationData.male_bird_id)?.name || 'Bilinmeyen' : 'Bilinmeyen';
              
              setParentInfo({
                mother: motherName,
                father: fatherName
              });
            }
          }
        }

        // Egg bilgilerini chick'ten al (artık chicks tablosunda egg_number var)
        if (chick.eggNumber) {
          setEggInfo({ egg_number: chick.eggNumber });
        }
      } catch (error) {
        console.error('Error fetching additional chick info:', error);
      }
    };

    fetchAdditionalInfo();
  }, [chick.incubationId, chick.eggId]);

  const calculateAge = useMemo(() => {
    const birth = new Date(chick.hatchDate);
    const now = new Date();
    const diffTime = now.getTime() - birth.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    
    if (diffDays < 30) return `${diffDays} ${t('chicks.days')}`;
    if (diffDays < 365) return `${Math.floor(diffDays / 30)} ${t('chicks.months')}`;
    return `${Math.floor(diffDays / 365)} ${t('chicks.years')}`;
  }, [chick.hatchDate, t]);

  // Yaş kategorisi bilgilerini hesapla (yavrular için)
  const ageInfo = useMemo(() => {
    return getDetailedAge(chick.hatchDate);
  }, [chick.hatchDate]);

  const getAgeStage = useMemo(() => {
    const birth = new Date(chick.hatchDate);
    const now = new Date();
    const diffTime = now.getTime() - birth.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    
    if (diffDays <= 7) return { stage: t('chicks.ageStages.newborn'), color: 'bg-pink-500' };
    if (diffDays <= 21) return { stage: t('chicks.ageStages.nestling'), color: 'bg-orange-500' };
    if (diffDays <= 35) return { stage: t('chicks.ageStages.fledging'), color: 'bg-yellow-500' };
    if (diffDays <= 60) return { stage: t('chicks.ageStages.learning'), color: 'bg-green-500' };
    return { stage: t('chicks.ageStages.young'), color: 'bg-blue-500' };
  }, [chick.hatchDate, t]);

  const getParentName = useMemo(() => (parentId?: string) => {
    if (!parentId || !birds) return t('chicks.unknownParent');
    const parent = birds.find(bird => bird.id === parentId);
    return parent?.name || t('chicks.unknownParent');
  }, [birds, t]);

  const ageStage = getAgeStage;
  const motherName = getParentName(chick.motherId);
  const fatherName = getParentName(chick.fatherId);

  // Debug logları kaldırıldı - artık gerekli değil

  const handleCardClick = (e: React.MouseEvent) => {
    // Buton tıklamalarını engelle
    if ((e.target as HTMLElement).closest('button')) {
      return;
    }
    onClick(chick);
  };

  const handleEdit = useCallback((e: React.MouseEvent) => {
    e.stopPropagation();
    onEdit(chick);
  }, [onEdit, chick]);

  const handleDelete = useCallback((e: React.MouseEvent) => {
    e.stopPropagation();
    onDelete(chick.id);
  }, [onDelete, chick.id]);

  const handlePromote = useCallback((e: React.MouseEvent) => {
    e.stopPropagation();
    onPromote(chick);
  }, [onPromote, chick]);

  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      onClick(chick);
    }
  }, [onClick, chick]);

  const formattedHatchDate = useMemo(() => {
    return new Date(chick.hatchDate).toLocaleDateString('tr-TR');
  }, [chick.hatchDate]);

  return (
    <Card 
      className="chick-card p-4 animate-fade-in cursor-pointer hover:shadow-lg transition-shadow" 
      role="article" 
                  aria-label={`${chick.name || `Yavru ${chick.egg_id ? '#' + chick.egg_id.slice(-4) : ''}`} yavrusu`}
      tabIndex={0}
      onClick={handleCardClick}
      onKeyDown={handleKeyDown}
    >
      <div className="flex items-start gap-4">
        <div className="w-16 h-16 rounded-full bg-gradient-to-br from-yellow-400 to-orange-400 flex items-center justify-center text-2xl shadow-lg flex-shrink-0" aria-hidden="true">
          {chick.photo ? (
            <img 
              src={chick.photo} 
              alt={chick.name || `Yavru ${chick.egg_id ? '#' + chick.egg_id.slice(-4) : ''}`}
              className="w-full h-full rounded-full object-cover"
              loading="lazy"
            />
          ) : (
            // Yavrular için 🐣 ikonu
            '🐣'
          )}
        </div>
        
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-2">
            <h3 className="font-semibold text-lg truncate">
              {chick.name || `Yavru ${chick.egg_id ? '#' + chick.egg_id.slice(-4) : ''}`}
            </h3>
            {/* Yaş kategorisi ikonu ve etiketi */}
            <span 
              className="text-lg"
              aria-label={resolveAgeCategoryKey(getAgeCategoryLabel(chick.hatchDate, t), t)}
              title={resolveAgeCategoryKey(getAgeCategoryLabel(chick.hatchDate, t), t)}
            >
              {getAgeCategoryIcon(chick.hatchDate)}
            </span>
            <span className="text-xs text-muted-foreground">
              {resolveAgeCategoryKey(getAgeCategoryLabel(chick.hatchDate, t), t)}
            </span>
            {/* Cinsiyet ikonu */}
            <span 
              className={`text-lg ${getGenderColor(chick.gender || 'unknown')}`}
              aria-label={chick.gender === 'male' ? t('chicks.male') : chick.gender === 'female' ? t('chicks.female') : t('chicks.unknown')}
              title={chick.gender === 'male' ? t('chicks.male') : chick.gender === 'female' ? t('chicks.female') : t('chicks.unknown')}
            >
              {getGenderIcon(chick.gender || 'unknown')}
            </span>
          </div>
          
          <div className="flex flex-wrap gap-1 mb-2">
            {chick.color && (
              <Badge variant="secondary" className="text-xs">
                {chick.color}
              </Badge>
            )}
            {calculateAge && (
              <Badge variant="outline" className="text-xs">
                {calculateAge}
              </Badge>
            )}
            {/* Anne ve Baba Bilgisi */}
            <Badge variant="outline" className="text-xs">
              {t('chicks.mother')}: {parentInfo?.mother || (chick.motherId ? (birds.find(b => b.id === chick.motherId)?.name || t('chicks.unknownParent')) : t('chicks.unknownParent'))}
            </Badge>
            <Badge variant="outline" className="text-xs">
              {t('chicks.father')}: {parentInfo?.father || (chick.fatherId ? (birds.find(b => b.id === chick.fatherId)?.name || t('chicks.unknownParent')) : t('chicks.unknownParent'))}
            </Badge>
            {incubationInfo && (
              <Badge variant="outline" className="text-xs bg-blue-50 text-blue-700 border-blue-200">
                🏠 {incubationInfo.name}
              </Badge>
            )}
            {eggInfo && (
              <Badge variant="outline" className="text-xs bg-green-50 text-green-700 border-green-200">
                🥚 #{eggInfo.egg_number || '?'}
              </Badge>
            )}
            <Badge 
              variant="outline" 
              className={`text-xs ${ageStage.color} text-white`}
            >
              {ageStage.stage}
            </Badge>
            {/* Cinsiyet badge'i */}
            <Badge variant="outline" className="text-xs">
              {chick.gender === 'male' ? t('chicks.male') : chick.gender === 'female' ? t('chicks.female') : t('chicks.unknown')}
            </Badge>
            {chick.ringNumber && (
              <Badge variant="outline" className="text-xs">
                #{chick.ringNumber}
              </Badge>
            )}
          </div>
          
          <div className="flex items-center gap-1 text-xs text-muted-foreground mb-2">
            <Calendar className="w-3 h-3" aria-hidden="true" />
            <span>{formattedHatchDate}</span>
          </div>
          
          <div className="text-xs text-muted-foreground mb-2">
            <div>{t('chicks.mother')}: {parentInfo?.mother || motherName}</div>
            <div>{t('chicks.father')}: {parentInfo?.father || fatherName}</div>
            {incubationInfo && (
              <div className="flex items-center gap-1 mt-1">
                <span className="text-blue-600">🏠</span>
                <span>Yuva: {incubationInfo.name}</span>
              </div>
            )}
            {eggInfo && (
              <div className="flex items-center gap-1 mt-1">
                <span className="text-green-600">🥚</span>
                <span>Yumurta: #{eggInfo.egg_number || '?'}</span>
              </div>
            )}
          </div>
          
          <div className="flex gap-2">
            <Button
              size="sm"
              variant="outline"
              onClick={handlePromote}
              className="flex-1 bg-green-50 text-green-700 hover:bg-green-100 border-green-200"
              aria-label={`${chick.name || `Yavru ${chick.egg_id ? '#' + chick.egg_id.slice(-4) : ''}`} yavrusunu kuşa aktar`}
            >
              <UserPlus className="w-3 h-3 mr-1" aria-hidden="true" />
              {t('chicks.promoteToBird')}
            </Button>
            <Button
              size="sm"
              variant="outline"
              onClick={handleEdit}
              aria-label={`${chick.name || `Yavru ${chick.egg_id ? '#' + chick.egg_id.slice(-4) : ''}`} yavrusunu düzenle`}
            >
              <Edit className="w-3 h-3" aria-hidden="true" />
            </Button>
            <Button
              size="sm"
              variant="outline"
              onClick={handleDelete}
              className="text-red-600 hover:text-red-700 hover:bg-red-50"
              aria-label={`${chick.name || `Yavru ${chick.egg_id ? '#' + chick.egg_id.slice(-4) : ''}`} yavrusunu sil`}
            >
              <Trash2 className="w-3 h-3" aria-hidden="true" />
            </Button>
          </div>
        </div>
      </div>
    </Card>
  );
});

ChickCard.displayName = 'ChickCard';

export default ChickCard;
