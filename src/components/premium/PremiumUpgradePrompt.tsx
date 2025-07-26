import React from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Crown, Star, X } from 'lucide-react';
import { useSubscription } from '@/hooks/subscription/useSubscription';

interface PremiumUpgradePromptProps {
  feature: string;
  currentUsage?: number;
  limit?: number;
  message?: string;
  onClose?: () => void;
  showTrial?: boolean;
  className?: string;
}

const PremiumUpgradePrompt: React.FC<PremiumUpgradePromptProps> = ({
  feature,
  currentUsage,
  limit,
  message,
  onClose,
  showTrial = true,
  className = ''
}) => {
  const { trialInfo, isTrial, error: subscriptionError } = useSubscription();

  const defaultMessage = limit 
    ? `${feature} limitiniz doldu (${currentUsage}/${limit}). Sınırsız kullanım için Premium'a geçin.`
    : `${feature} özelliğini kullanmak için Premium aboneliğe geçmeniz gerekiyor.`;

  const handleUpgrade = () => {
    // Premium sayfasına yönlendir
    window.location.href = '/premium';
  };

  const handleStartTrial = async () => {
    // Trial başlatma işlemi
    console.log('Trial başlatılıyor...');
    // Burada trial başlatma API çağrısı yapılacak
  };

  const handleStartTrial = () => {
    // Trial başlatma işlemi
    console.log('Trial başlatılıyor...');
    // Burada trial başlatma API çağrısı yapılacak
  };

  // Hata durumunda basit bir mesaj göster
  if (subscriptionError) {
    return (
      <Card className={`bg-yellow-50 border-yellow-200 ${className}`}>
        <CardContent className="pt-6">
          <div className="text-center">
            <p className="text-sm text-yellow-800">
              Premium özellikler şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin.
            </p>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className={`bg-gradient-to-br from-primary/5 to-primary/10 border-primary/20 ${className}`}>
      <CardHeader className="pb-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 bg-gradient-to-r from-yellow-400 to-orange-500 rounded-full flex items-center justify-center">
              <Crown className="w-4 h-4 text-white" />
            </div>
            <div>
              <CardTitle className="text-lg">Premium Özellik Gerekli</CardTitle>
              <CardDescription>
                {message || defaultMessage}
              </CardDescription>
            </div>
          </div>
          {onClose && (
            <Button
              variant="ghost"
              size="sm"
              onClick={onClose}
              className="h-8 w-8 p-0"
            >
              <X className="w-4 h-4" />
            </Button>
          )}
        </div>
      </CardHeader>
      
      <CardContent>
        <div className="space-y-4">
          {/* Premium Features Preview */}
          <div className="grid grid-cols-2 gap-3 text-sm">
            <div className="flex items-center gap-2">
              <Crown className="w-4 h-4 text-primary" />
              <span>Sınırsız {feature}</span>
            </div>
            <div className="flex items-center gap-2">
              <Star className="w-4 h-4 text-primary" />
              <span>Gelişmiş Analitikler</span>
            </div>
            <div className="flex items-center gap-2">
              <Star className="w-4 h-4 text-primary" />
              <span>Bulut Senkronizasyonu</span>
            </div>
            <div className="flex items-center gap-2">
              <Star className="w-4 h-4 text-primary" />
              <span>Reklamsız Deneyim</span>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex flex-col sm:flex-row gap-3">
            {showTrial && trialInfo.is_trial_available && !isTrial && (
              <Button
                onClick={handleStartTrial}
                variant="outline"
                className="flex-1"
              >
                <Star className="w-4 h-4 mr-2" />
                3 Gün Ücretsiz Dene
              </Button>
            )}
            <Button
              onClick={handleUpgrade}
              className="flex-1"
            >
              <Crown className="w-4 h-4 mr-2" />
              Premium'a Geç
            </Button>
          </div>

          {/* Trial Info */}
          {isTrial && (
            <div className="text-center p-3 bg-blue-50 rounded-lg">
              <p className="text-sm text-blue-700">
                <Star className="w-4 h-4 inline mr-1" />
                Trial süreniz: {trialInfo.days_remaining} gün kaldı
              </p>
            </div>
          )}

          {/* Pricing Info */}
          <div className="text-center text-sm text-muted-foreground">
            <p>₺29.99/ay veya ₺299.99/yıl</p>
            <p className="text-xs">İstediğiniz zaman iptal edebilirsiniz</p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
};

export default PremiumUpgradePrompt; 