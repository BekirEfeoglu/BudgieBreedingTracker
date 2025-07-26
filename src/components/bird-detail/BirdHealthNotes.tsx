import React, { memo } from 'react';
import { Card } from '@/components/ui/card';
import { FileText } from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';

interface BirdHealthNotesProps {
  healthNotes: string;
}

const BirdHealthNotes = memo(({ healthNotes }: BirdHealthNotesProps) => {
  const { t } = useLanguage();

  if (!healthNotes) {
    return null;
  }

  return (
    <Card className="p-4" role="region" aria-label="Kuş sağlık notları">
      <div className="flex items-center gap-2 mb-2">
        <FileText className="w-4 h-4 text-muted-foreground" aria-hidden="true" />
        <span className="font-medium">{t('birds.healthNotes')}</span>
      </div>
      <p className="text-sm text-muted-foreground">{healthNotes}</p>
    </Card>
  );
});

BirdHealthNotes.displayName = 'BirdHealthNotes';

export default BirdHealthNotes;
