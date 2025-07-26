import React, { memo, useMemo, useCallback } from 'react';
import { Badge } from '@/components/ui/badge';
import { Card } from '@/components/ui/card';
import { Calendar, User } from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';
import { Bird } from '@/types';
import { getAgeCategoryLabel, getDetailedAge } from '@/utils/dateUtils';
import { resolveAgeCategoryKey, normalizeAgeCategory, extractAgeCategory } from '@/utils/translationHelpers';

interface BirdBasicInfoProps {
  bird: Bird;
}

const BirdBasicInfo = memo(({ bird }: BirdBasicInfoProps) => {
  const { t } = useLanguage();

  const calculateAge = useCallback((birthDate: string) => {
    const birth = new Date(birthDate);
    const now = new Date();
    const diffTime = now.getTime() - birth.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    
    if (diffDays < 30) return `${diffDays} ${t('birds.days')}`;
    if (diffDays < 365) return `${Math.floor(diffDays / 30)} ${t('birds.months')}`;
    return `${Math.floor(diffDays / 365)} ${t('birds.years')}`;
  }, [t]);

  // Yaş kategorisi bilgilerini hesapla
  const ageInfo = useMemo(() => {
    if (!bird.birthDate) return null;
    return getDetailedAge(bird.birthDate);
  }, [bird.birthDate]);

  const genderColor = useMemo(() => {
    return bird.gender === 'male' ? 'text-blue-600' : 
           bird.gender === 'female' ? 'text-pink-600' : 
           'text-gray-600';
  }, [bird.gender]);

  const genderText = useMemo(() => {
    return t(`birds.${bird.gender}`);
  }, [bird.gender, t]);

  const formattedBirthDate = useMemo(() => {
    if (!bird.birthDate) return null;
    return new Date(bird.birthDate).toLocaleDateString('tr-TR');
  }, [bird.birthDate]);

  const age = useMemo(() => {
    if (!bird.birthDate) return null;
    return calculateAge(bird.birthDate);
  }, [bird.birthDate, calculateAge]);

  const motherId = bird.motherId || '';

  return (
    <Card className="p-4 space-y-3" role="region" aria-label="Kuş temel bilgileri">
      <div className="flex items-center gap-2">
        <User className="w-4 h-4 text-muted-foreground" aria-hidden="true" />
        <span className="font-medium">{t('birds.gender')}:</span>
        <Badge variant="secondary" className={genderColor}>
          {genderText}
        </Badge>
      </div>

      {bird.color && (
        <div className="flex items-center gap-2">
          <div className="w-4 h-4 rounded-full bg-gradient-to-r from-yellow-400 to-green-400" aria-hidden="true"></div>
          <span className="font-medium">{t('birds.color')}:</span>
          <span>{bird.color}</span>
        </div>
      )}

      {formattedBirthDate && (
        <div className="flex items-center gap-2">
          <Calendar className="w-4 h-4 text-muted-foreground" aria-hidden="true" />
          <span className="font-medium">{t('birds.birthDate')}:</span>
          <span>{formattedBirthDate}</span>
          {age && (
            <Badge variant="outline" className="ml-2">
              {age}
            </Badge>
          )}
        </div>
      )}

      {/* Yaş Kategorisi */}
      {ageInfo && (
        <div className="flex items-center gap-2">
          <span className="text-lg" role="img" aria-hidden="true">
            {ageInfo.icon}
          </span>
          <span className="font-medium">Yaş Kategorisi:</span>
          <Badge variant="outline" className="ml-2">
            {ageInfo.category === 'chick' ? 'Yavru' : 'Yetişkin'}
          </Badge>
        </div>
      )}

      {bird.ringNumber && (
        <div className="flex items-center gap-2">
          <div className="w-4 h-4 rounded-full border-2 border-muted-foreground" aria-hidden="true"></div>
          <span className="font-medium">{t('birds.ringNumber')}:</span>
          <Badge variant="outline">#{bird.ringNumber}</Badge>
        </div>
      )}


    </Card>
  );
});

BirdBasicInfo.displayName = 'BirdBasicInfo';

export default BirdBasicInfo;
