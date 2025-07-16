import React from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { ArrowLeft } from 'lucide-react';

interface UserGuideProps {
  onBack?: () => void;
}

const UserGuide: React.FC<UserGuideProps> = ({ onBack }) => {
  return (
    <Card className="budgie-card shadow-sm">
      <CardHeader className="pb-4 flex flex-row items-center gap-2">
        {onBack && (
          <Button variant="ghost" size="icon" onClick={onBack} className="mr-2">
            <ArrowLeft className="w-5 h-5" />
          </Button>
        )}
        <CardTitle>Kullanım Kılavuzu</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <CardDescription>
          Uygulamanın temel işlevlerini ve ipuçlarını burada bulabilirsiniz.
        </CardDescription>
        <ul className="list-disc pl-6 space-y-2 text-sm">
          <li>Kuş eklemek için ana ekrandaki "Kuş Ekle" butonunu kullanın.</li>
          <li>Üreme kaydı oluşturmak için ilgili kuşun detayına gidin.</li>
          <li>Yumurta ve yavru takibini üreme kartı üzerinden yapabilirsiniz.</li>
          <li>Verilerinizi dışa aktarabilir veya yedekleyebilirsiniz.</li>
          <li>Bildirim ve tema ayarlarını profil menüsünden değiştirebilirsiniz.</li>
        </ul>
      </CardContent>
    </Card>
  );
};

export default UserGuide;