import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { useLanguage } from '@/contexts/LanguageContext';
import { Globe, ChevronRight } from 'lucide-react';

const LanguageSettings = () => {
  const { language, setLanguage, t } = useLanguage();

  const handleLanguageChange = () => {
    const newLanguage = language === 'tr' ? 'en' : 'tr';
    setLanguage(newLanguage);
  };

  return (
    <Card className="budgie-card shadow-sm">
      <CardHeader className="pb-4">
        <CardTitle className="flex items-center gap-2 text-lg">
          <Globe className="w-5 h-5" />
          {t('settings.language', 'Dil')}
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="flex items-center justify-between py-2">
          <div className="flex-1">
            <p className="font-medium text-base">{t('settings.language')}</p>
            <p className="text-sm text-muted-foreground">
              {language === 'tr' ? 'Türkçe' : 'English'}
            </p>
          </div>
          <Button 
            variant="outline" 
            size="sm" 
            onClick={handleLanguageChange}
            className="min-h-[44px] px-4 flex items-center gap-2 touch-manipulation"
          >
            {language === 'tr' ? t('common.changeLanguage') : t('common.changeLanguage')}
            <ChevronRight className="w-4 h-4" />
          </Button>
        </div>
      </CardContent>
    </Card>
  );
};

export default LanguageSettings;
