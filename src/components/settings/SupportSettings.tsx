import React from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { MessageSquare } from 'lucide-react';
import FeedbackModal from './FeedbackModal';
import { useState } from 'react';
import { useLanguage } from '@/contexts/LanguageContext';

interface SupportSettingsProps {
  className?: string;
}

export const SupportSettings: React.FC<SupportSettingsProps> = ({ className }) => {
  const [showFeedbackModal, setShowFeedbackModal] = useState(false);
  const { t } = useLanguage();

  return (
    <>
      <Card className="budgie-card shadow-sm">
        <CardHeader className="pb-4">
          <CardTitle className="flex items-center gap-2 text-lg">
            <MessageSquare className="w-5 h-5" />
            {t('settings.support', 'Destek')}
          </CardTitle>
          <CardDescription>
            Uygulama ile ilgili geri bildirim gönderin
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center justify-between">
            <Label htmlFor="send-feedback" className="text-sm">
              Geri bildirim gönder
            </Label>
            <Button 
              id="send-feedback" 
              variant="outline" 
              className="w-full justify-start min-h-[48px] text-base touch-manipulation"
              onClick={() => setShowFeedbackModal(true)}
            >
              <MessageSquare className="w-5 h-5 mr-3" />
              Geri Bildirim Gönder
            </Button>
          </div>
          
          <div className="text-xs text-muted-foreground mt-8 border-t pt-4">
            <div><strong>Sürüm:</strong> 1.0.0</div>
            <div>Muhabbet kuşu üretim takip uygulaması<br/><strong>Geliştirici: Bekir EFEOĞLU</strong></div>
          </div>
        </CardContent>
      </Card>

      <FeedbackModal 
        isOpen={showFeedbackModal} 
        onClose={() => setShowFeedbackModal(false)} 
      />
    </>
  );
};

export default SupportSettings;
