
import React from 'react';
import { useLanguage } from '@/contexts/LanguageContext';
import { Button } from '@/components/ui/button';
import { ArrowLeft, RefreshCw } from 'lucide-react';

interface EggManagementHeaderProps {
  clutchName: string;
  onBack: () => void;
  onRefresh: () => void;
}

const EggManagementHeader: React.FC<EggManagementHeaderProps> = ({
  clutchName,
  onBack,
  onRefresh
}) => {
  const { t } = useLanguage();

  return (
    <div className="flex items-center justify-between">
      <div className="flex items-center gap-4">
        <Button variant="ghost" onClick={onBack}>
          <ArrowLeft className="w-4 h-4 mr-2" />
          {t('common.back', 'Geri')}
        </Button>
        <h2 className="text-2xl font-bold">
          {clutchName} - {t('egg.management', 'Yumurta Yönetimi')}
        </h2>
      </div>
      <Button onClick={onRefresh} variant="outline" size="sm">
        <RefreshCw className="w-4 h-4" />
      </Button>
    </div>
  );
};

export default EggManagementHeader;
