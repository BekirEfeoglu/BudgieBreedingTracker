import React from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { HelpCircle } from 'lucide-react';
import UserGuide from './UserGuide';
import { useState } from 'react';
import { useLanguage } from '@/contexts/LanguageContext';

interface SupportSettingsProps {
  className?: string;
}

export const SupportSettings: React.FC<SupportSettingsProps> = ({ className }) => {
  const [showUserGuide, setShowUserGuide] = useState(false);
  const { t } = useLanguage();

  if (showUserGuide) {
    return <UserGuide onBack={() => setShowUserGuide(false)} />;
  }

  return (
    <Card className="budgie-card shadow-sm">
      <CardHeader className="pb-4">
        <CardTitle className="flex items-center gap-2 text-lg">
          <HelpCircle className="w-5 h-5" />
          {t('settings.support', 'Destek')}
        </CardTitle>
        <CardDescription>
          Uygulama ile ilgili destek alın veya geri bildirim gönderin
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="flex items-center justify-between">
          <Label htmlFor="contact-support" className="text-sm">
            Destek ekibiyle iletişime geç
          </Label>
          <Button id="contact-support" variant="outline" className="w-full justify-start min-h-[48px] text-base touch-manipulation">
            İletişim
          </Button>
        </div>
        <div className="flex items-center justify-between">
          <Label htmlFor="send-feedback" className="text-sm">
            Geri bildirim gönder
          </Label>
          <Button id="send-feedback" variant="outline" className="w-full justify-start min-h-[48px] text-base touch-manipulation">
            Gönder
          </Button>
        </div>
        <Button 
          variant="outline" 
          className="w-full justify-start min-h-[48px] text-base touch-manipulation"
          onClick={() => setShowUserGuide(true)}
        >
          <HelpCircle className="w-5 h-5 mr-3" />
          Kullanım Kılavuzu
        </Button>
        <div className="text-xs text-muted-foreground mt-8 border-t pt-4">
          <div><strong>Sürüm:</strong> 1.0.0</div>
          <div>Muhabbet kuşu üretim takip uygulaması<br/><strong>Geliştirici: Bekir EFEOĞLU</strong></div>
        </div>
      </CardContent>
    </Card>
  );
};

export default SupportSettings;
