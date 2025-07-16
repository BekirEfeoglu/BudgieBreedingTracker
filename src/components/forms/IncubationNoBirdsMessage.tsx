
import React from 'react';
import { Button } from '@/components/ui/button';

interface IncubationNoBirdsMessageProps {
  onCancel: () => void;
}

const IncubationNoBirdsMessage: React.FC<IncubationNoBirdsMessageProps> = ({
  onCancel
}) => {
  return (
    <div className="fixed inset-0 z-50 bg-background">
      <div className="flex flex-col items-center justify-center min-h-[400px] p-6">
        <div className="text-6xl mb-4">🐦</div>
        <h3 className="text-lg font-semibold mb-2">Çift Bulunamadı</h3>
        <p className="text-muted-foreground mb-4 text-center">
          Kuluçka eklemek için önce erkek ve dişi kuş eklemeniz gerekiyor.
        </p>
        <Button onClick={onCancel} variant="outline">
          Geri Dön
        </Button>
      </div>
    </div>
  );
};

export default IncubationNoBirdsMessage;
