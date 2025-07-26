
import React from 'react';
import { Alert, AlertDescription } from '@/components/ui/alert';

interface IncubationPromptMessagesProps {
  type: 'add' | 'edit' | 'delete';
  incubationData?: {
    femaleBird?: string;
    maleBird?: string;
    startDate?: string;
    nestName?: string;
    name?: string;
  };
}

const IncubationPromptMessages: React.FC<IncubationPromptMessagesProps> = ({
  type,
  incubationData
}) => {
  if (type === 'edit' && incubationData) {
    return (
      <Alert className="bg-blue-50 border-blue-200">
        <AlertDescription>
          <strong>{incubationData.nestName || incubationData.name}</strong> adlı kuluçkayı düzenlemektesiniz.
        </AlertDescription>
      </Alert>
    );
  }

  if (type === 'delete' && incubationData) {
    return (
      <Alert className="bg-red-50 border-red-200">
        <AlertDescription>
          <strong>{incubationData.nestName || incubationData.name}</strong> adlı kuluçka silinecek.
          <br />
          <span className="text-sm text-muted-foreground">
            {incubationData.femaleBird && incubationData.maleBird && (
              <>Çift: {incubationData.femaleBird} × {incubationData.maleBird}</>
            )}
            {incubationData.startDate && (
              <><br />Başlangıç: {incubationData.startDate}</>
            )}
          </span>
        </AlertDescription>
      </Alert>
    );
  }

  return null;
};

export default IncubationPromptMessages;
