
import React from 'react';
import { useLanguage } from '@/contexts/LanguageContext';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { RefreshCw } from 'lucide-react';

interface EggManagementErrorProps {
  error: string;
  onRefresh: () => void;
}

const EggManagementError: React.FC<EggManagementErrorProps> = ({
  error,
  onRefresh
}) => {
  const { t } = useLanguage();

  return (
    <Card>
      <CardContent className="p-8 text-center">
        <div className="text-red-500 text-6xl mb-4">⚠️</div>
        <h3 className="text-lg font-medium mb-2">
          {t('common.error', 'Hata')}
        </h3>
        <p className="text-muted-foreground mb-4">
          {error}
        </p>
        <Button onClick={onRefresh} variant="outline">
          <RefreshCw className="w-4 h-4 mr-2" />
          Yeniden Dene
        </Button>
      </CardContent>
    </Card>
  );
};

export default EggManagementError;
