import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { useSubscription } from '@/hooks/subscription/useSubscription';
import { usePremiumGuard } from '@/hooks/subscription/usePremiumGuard';
import { Crown, Star, Check, X } from 'lucide-react';

const PremiumSystemTest: React.FC = () => {
  const { 
    isPremium, 
    isTrial, 
    trialInfo, 
    premiumFeatures, 
    subscriptionLimits,
    updateSubscriptionStatus,
    error: subscriptionError
  } = useSubscription();
  
  const { requirePremium, requireFeatureLimit } = usePremiumGuard();
  const [testResults, setTestResults] = useState<string[]>([]);

  const addTestResult = (result: string) => {
    setTestResults(prev => [...prev, `${new Date().toLocaleTimeString()}: ${result}`]);
  };

  const clearTestResults = () => {
    setTestResults([]);
  };

  const testPremiumStatus = () => {
    addTestResult(`Premium durumu: ${isPremium ? 'Aktif' : 'Pasif'}`);
    addTestResult(`Trial durumu: ${isTrial ? 'Aktif' : 'Pasif'}`);
    if (isTrial) {
      addTestResult(`Trial kalan gün: ${trialInfo.days_remaining}`);
    }
  };

  const testFeatureLimits = () => {
    addTestResult('--- Limit Testleri ---');
    
    // Kuş limiti testi
    const birdLimit = requireFeatureLimit('birds', 2, { feature: 'kuş kaydı' });
    addTestResult(`Kuş limiti (2/3): ${birdLimit ? '✅ Geçerli' : '❌ Limit aşıldı'}`);
    
    const birdLimitExceeded = requireFeatureLimit('birds', 4, { feature: 'kuş kaydı' });
    addTestResult(`Kuş limiti (4/3): ${birdLimitExceeded ? '✅ Geçerli' : '❌ Limit aşıldı'}`);
    
    // Kuluçka limiti testi
    const incubationLimit = requireFeatureLimit('incubations', 0, { feature: 'kuluçka' });
    addTestResult(`Kuluçka limiti (0/1): ${incubationLimit ? '✅ Geçerli' : '❌ Limit aşıldı'}`);
    
    const incubationLimitExceeded = requireFeatureLimit('incubations', 2, { feature: 'kuluçka' });
    addTestResult(`Kuluçka limiti (2/1): ${incubationLimitExceeded ? '✅ Geçerli' : '❌ Limit aşıldı'}`);
  };

  const testPremiumFeatures = () => {
    addTestResult('--- Premium Özellik Testleri ---');
    
    Object.entries(premiumFeatures).forEach(([feature, enabled]) => {
      addTestResult(`${feature}: ${enabled ? '✅ Aktif' : '❌ Pasif'}`);
    });
  };

  const testSubscriptionLimits = () => {
    addTestResult('--- Abonelik Limitleri ---');
    
    Object.entries(subscriptionLimits).forEach(([feature, limit]) => {
      addTestResult(`${feature}: ${limit === -1 ? 'Sınırsız' : limit}`);
    });
  };

  const simulatePremiumUpgrade = async () => {
    try {
      addTestResult('Premium yükseltme simülasyonu başlatılıyor...');
      await updateSubscriptionStatus('premium');
      addTestResult('✅ Premium yükseltme başarılı!');
    } catch (error) {
      addTestResult(`❌ Premium yükseltme hatası: ${error}`);
    }
  };

  const simulateTrialStart = async () => {
    try {
      addTestResult('Trial başlatma simülasyonu başlatılıyor...');
      const trialEndDate = new Date();
      trialEndDate.setDate(trialEndDate.getDate() + 3);
      await updateSubscriptionStatus('trial', undefined, trialEndDate.toISOString());
      addTestResult('✅ Trial başlatma başarılı!');
    } catch (error) {
      addTestResult(`❌ Trial başlatma hatası: ${error}`);
    }
  };

  const simulateFreeDowngrade = async () => {
    try {
      addTestResult('Ücretsiz plana düşürme simülasyonu başlatılıyor...');
      await updateSubscriptionStatus('free');
      addTestResult('✅ Ücretsiz plana düşürme başarılı!');
    } catch (error) {
      addTestResult(`❌ Düşürme hatası: ${error}`);
    }
  };

  const testPremiumGuard = () => {
    addTestResult('--- Premium Guard Testleri ---');
    
    // Premium özellik testi
    const genealogyAccess = requirePremium({ feature: 'soyağacı görüntüleme' });
    addTestResult(`Soyağacı erişimi: ${genealogyAccess ? '✅ İzin verildi' : '❌ Premium gerekli'}`);
    
    const exportAccess = requirePremium({ feature: 'veri dışa aktarma' });
    addTestResult(`Dışa aktarma erişimi: ${exportAccess ? '✅ İzin verildi' : '❌ Premium gerekli'}`);
  };

  const runAllTests = () => {
    clearTestResults();
    addTestResult('🧪 Premium sistem testleri başlatılıyor...');
    
    testPremiumStatus();
    testFeatureLimits();
    testPremiumFeatures();
    testSubscriptionLimits();
    testPremiumGuard();
    
    addTestResult('✅ Tüm testler tamamlandı!');
  };

  // Hata durumunda basit bir mesaj göster
  if (subscriptionError) {
    return (
      <div className="container mx-auto px-4 py-8 max-w-4xl">
        <div className="text-center">
          <h1 className="text-2xl font-bold mb-4">Premium Sistem Test Paneli</h1>
          <p className="text-muted-foreground mb-8">
            Premium özellikler şu anda kullanılamıyor.
          </p>
          <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 max-w-md mx-auto">
            <p className="text-sm text-yellow-800">
              Sistem hazırlanıyor... Test paneli yakında kullanılabilir olacak.
            </p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8 max-w-4xl">
      <div className="text-center mb-8">
        <h1 className="text-3xl font-bold mb-4">Premium Sistem Test Paneli</h1>
        <p className="text-muted-foreground">
          Premium abonelik sisteminin tüm bileşenlerini test edin
        </p>
      </div>

      {/* Current Status */}
      <Card className="mb-6">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Crown className="w-5 h-5" />
            Mevcut Durum
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div className="text-center">
              <div className="text-2xl font-bold">
                {isPremium ? '👑' : isTrial ? '⭐' : '🆓'}
              </div>
              <div className="text-sm font-medium">
                {isPremium ? 'Premium' : isTrial ? 'Trial' : 'Ücretsiz'}
              </div>
            </div>
            
            {isTrial && (
              <div className="text-center">
                <div className="text-2xl font-bold text-blue-600">
                  {trialInfo.days_remaining}
                </div>
                <div className="text-sm text-muted-foreground">Kalan Gün</div>
              </div>
            )}
            
            <div className="text-center">
              <div className="text-2xl font-bold text-green-600">
                {Object.values(premiumFeatures).filter(Boolean).length}
              </div>
              <div className="text-sm text-muted-foreground">Aktif Özellik</div>
            </div>
            
            <div className="text-center">
              <div className="text-2xl font-bold text-orange-600">
                {Object.values(subscriptionLimits).filter(limit => limit === -1).length}
              </div>
              <div className="text-sm text-muted-foreground">Sınırsız Özellik</div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Test Controls */}
      <div className="grid md:grid-cols-2 gap-6 mb-6">
        <Card>
          <CardHeader>
            <CardTitle>Test Kontrolleri</CardTitle>
            <CardDescription>
              Sistem bileşenlerini test edin
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            <Button onClick={runAllTests} className="w-full">
              🧪 Tüm Testleri Çalıştır
            </Button>
            
            <Button onClick={testPremiumStatus} variant="outline" className="w-full">
              📊 Durum Testi
            </Button>
            
            <Button onClick={testFeatureLimits} variant="outline" className="w-full">
              🔒 Limit Testi
            </Button>
            
            <Button onClick={testPremiumGuard} variant="outline" className="w-full">
              🛡️ Guard Testi
            </Button>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Simülasyon Kontrolleri</CardTitle>
            <CardDescription>
              Abonelik durumlarını simüle edin
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            <Button 
              onClick={simulateTrialStart} 
              variant="outline" 
              className="w-full"
              disabled={isTrial}
            >
              ⭐ Trial Başlat
            </Button>
            
            <Button 
              onClick={simulatePremiumUpgrade} 
              variant="outline" 
              className="w-full"
              disabled={isPremium}
            >
              👑 Premium Yükselt
            </Button>
            
            <Button 
              onClick={simulateFreeDowngrade} 
              variant="outline" 
              className="w-full"
              disabled={!isPremium && !isTrial}
            >
              🆓 Ücretsiz Plan
            </Button>
          </CardContent>
        </Card>
      </div>

      {/* Test Results */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Test Sonuçları</CardTitle>
            <Button onClick={clearTestResults} variant="outline" size="sm">
              Temizle
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          <div className="bg-gray-50 rounded-lg p-4 max-h-96 overflow-y-auto">
            {testResults.length === 0 ? (
              <p className="text-muted-foreground text-center">
                Test sonuçları burada görünecek...
              </p>
            ) : (
              <div className="space-y-1">
                {testResults.map((result, index) => (
                  <div key={index} className="text-sm font-mono">
                    {result}
                  </div>
                ))}
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Feature Status */}
      <Card className="mt-6">
        <CardHeader>
          <CardTitle>Özellik Durumları</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
            {Object.entries(premiumFeatures).map(([feature, enabled]) => (
              <div key={feature} className="flex items-center gap-2">
                {enabled ? (
                  <Check className="w-4 h-4 text-green-500" />
                ) : (
                  <X className="w-4 h-4 text-red-500" />
                )}
                <span className="text-sm capitalize">
                  {feature.replace(/_/g, ' ')}
                </span>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default PremiumSystemTest; 