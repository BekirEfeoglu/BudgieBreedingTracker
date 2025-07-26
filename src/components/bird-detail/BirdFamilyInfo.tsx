import React, { memo, useMemo } from 'react';
import { Card } from '@/components/ui/card';
import { Heart } from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';
import { Bird } from '@/types';

interface BirdFamilyInfoProps {
  bird: Bird;
  existingBirds: Bird[];
}

const BirdFamilyInfo = memo(({ bird, existingBirds }: BirdFamilyInfoProps) => {
  const { t } = useLanguage();

  const motherBird = useMemo(() => 
    existingBirds.find(b => b.id === bird.motherId), 
    [existingBirds, bird.motherId]
  );

  const fatherBird = useMemo(() => 
    existingBirds.find(b => b.id === bird.fatherId), 
    [existingBirds, bird.fatherId]
  );

  if (!motherBird && !fatherBird) {
    return null;
  }

  return (
    <Card className="p-4 space-y-3" role="region" aria-label="Kuş aile bilgileri">
      <div className="flex items-center gap-2 mb-2">
        <Heart className="w-4 h-4 text-red-500" aria-hidden="true" />
        <span className="font-medium">{t('genealogy.familyTree')}</span>
      </div>
      
      {motherBird && (
        <div className="flex items-center gap-2">
          <span className="text-pink-600" aria-label={t('birds.female')}>{t('birds.femaleIcon')}</span>
          <span className="font-medium">{t('birds.mother')}:</span>
          <span>{motherBird.name}</span>
        </div>
      )}
      
      {fatherBird && (
        <div className="flex items-center gap-2">
          <span className="text-blue-600" aria-label={t('birds.male')}>{t('birds.maleIcon')}</span>
          <span className="font-medium">{t('birds.father')}:</span>
          <span>{fatherBird.name}</span>
        </div>
      )}
    </Card>
  );
});

BirdFamilyInfo.displayName = 'BirdFamilyInfo';

export default BirdFamilyInfo;
