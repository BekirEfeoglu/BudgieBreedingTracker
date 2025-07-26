import React, { useState } from 'react';
import { useSubscription } from '@/hooks/subscription/useSubscription';
import { useAuth } from '@/hooks/useAuth';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { 
  Check, 
  Crown, 
  Star, 
  Zap, 
  Cloud, 
  BarChart3, 
  Users, 
  Download, 
  Bell, 
  Shield,
  Sparkles,
  Heart,
  Target,
  TrendingUp,
  Lock,
  Unlock,
  ArrowRight,
  CheckCircle,
  XCircle
} from 'lucide-react';
import { cn } from '@/lib/utils';

const PremiumPage: React.FC = () => {
  const { user } = useAuth();
  const { toast } = useToast();
  const { 
    subscriptionPlans, 
    userProfile, 
    isPremium, 
    isTrial, 
    trialInfo,
    loading,
    error: subscriptionError,
    updateSubscriptionStatus
  } = useSubscription();
  
  const [selectedCycle, setSelectedCycle] = useState<'monthly' | 'yearly'>('monthly');
  const [processing, setProcessing] = useState(false);

  const premiumPlan = subscriptionPlans.find(plan => plan.name === 'premium');
  const freePlan = subscriptionPlans.find(plan => plan.name === 'free');

  const billingCycles = [
    {
      id: 'monthly' as const,
      name: 'Aylık',
      price: premiumPlan?.price_monthly || 29.99,
      savings: 0,
      period: 'ay',
    },
    {
      id: 'yearly' as const,
      name: 'Yıllık',
      price: premiumPlan?.price_yearly || 299.99,
      savings: 60,
      popular: true,
      period: 'yıl',
    },
  ];

  const features = [
    {
      icon: Crown,
      title: 'Sınırsız Kuş Kaydı',
      description: 'İstediğiniz kadar kuş kaydedin ve yönetin',
      free: false,
      highlight: true,
    },
    {
      icon: Zap,
      title: 'Sınırsız Kuluçka',
      description: 'Sınırsız kuluçka dönemi takibi ve analizi',
      free: false,
      highlight: true,
    },
    {
      icon: Cloud,
      title: 'Bulut Senkronizasyonu',
      description: 'Verileriniz güvenle bulutta saklanır ve senkronize edilir',
      free: false,
    },
    {
      icon: BarChart3,
      title: 'Gelişmiş İstatistikler',
      description: 'Detaylı analitik, grafikler ve performans raporları',
      free: false,
    },
    {
      icon: Users,
      title: 'Soyağacı Görüntüleme',
      description: 'Kuşlarınızın aile geçmişini görsel olarak takip edin',
      free: false,
    },
    {
      icon: Download,
      title: 'Veri Dışa Aktarma',
      description: 'Excel, CSV, JSON formatlarında verilerinizi dışa aktarın',
      free: false,
    },
    {
      icon: Bell,
      title: 'Özel Bildirimler',
      description: 'Kişiselleştirilmiş hatırlatıcılar ve akıllı uyarılar',
      free: false,
    },
    {
      icon: Shield,
      title: 'Reklamsız Deneyim',
      description: 'Kesintisiz, temiz ve hızlı arayüz deneyimi',
      free: false,
    },
  ];

  const freeFeatures = [
    { text: '3 kuş kaydı', available: true },
    { text: '1 kuluçka dönemi', available: true },
    { text: '6 yumurta takibi', available: true },
    { text: '3 yavru kaydı', available: true },
    { text: '5 bildirim', available: true },
    { text: 'Soyağacı görüntüleme', available: false },
    { text: 'Veri dışa aktarma', available: false },
    { text: 'Gelişmiş istatistikler', available: false },
  ];

  const premiumFeatures = [
    { text: 'Sınırsız kuş kaydı', available: true },
    { text: 'Sınırsız kuluçka dönemi', available: true },
    { text: 'Sınırsız yumurta takibi', available: true },
    { text: 'Sınırsız yavru kaydı', available: true },
    { text: 'Sınırsız bildirim', available: true },
    { text: 'Soyağacı görüntüleme', available: true },
    { text: 'Veri dışa aktarma', available: true },
    { text: 'Gelişmiş istatistikler', available: true },
    { text: 'Bulut senkronizasyonu', available: true },
    { text: 'Özel bildirimler', available: true },
    { text: 'Reklamsız deneyim', available: true },
    { text: 'Otomatik yedekleme', available: true },
  ];

  const handleUpgrade = async () => {
    if (!user) return;
    
    setProcessing(true);
    try {
      const premiumPlanId = premiumPlan?.id;
      if (!premiumPlanId) {
        console.error('Premium plan bulunamadı');
        toast({
          title: 'Hata',
          description: 'Premium plan bulunamadı. Lütfen sayfayı yenileyin.',
          variant: 'destructive'
        });
        return;
      }

      const success = await updateSubscriptionStatus('premium', premiumPlanId);
      
      if (success) {
        console.log('✅ Premium abonelik başarıyla aktifleştirildi');
        toast({
          title: 'Premium Aktif! 🎉',
          description: 'Premium aboneliğiniz başarıyla aktifleştirildi. Tüm özelliklere erişiminiz var.',
          variant: 'default'
        });
        setTimeout(() => window.location.reload(), 1500);
      } else {
        console.error('❌ Premium abonelik aktifleştirilemedi');
        toast({
          title: 'Hata',
          description: 'Premium abonelik aktifleştirilemedi. Lütfen tekrar deneyin.',
          variant: 'destructive'
        });
      }
    } catch (error) {
      console.error('Premium yükseltme hatası:', error);
    } finally {
      setProcessing(false);
    }
  };

  const handleStartTrial = async () => {
    if (!user) return;
    
    setProcessing(true);
    try {
      const premiumPlanId = premiumPlan?.id;
      if (!premiumPlanId) {
        console.error('Premium plan bulunamadı');
        toast({
          title: 'Hata',
          description: 'Premium plan bulunamadı. Lütfen sayfayı yenileyin.',
          variant: 'destructive'
        });
        return;
      }

      const trialEndDate = new Date();
      trialEndDate.setDate(trialEndDate.getDate() + 3);
      
      const success = await updateSubscriptionStatus('trial', premiumPlanId, trialEndDate.toISOString());
      
      if (success) {
        console.log('✅ Trial başarıyla başlatıldı');
        toast({
          title: 'Trial Başlatıldı! ⭐',
          description: '3 günlük ücretsiz trial süreniz başladı. Premium özellikleri deneyebilirsiniz.',
          variant: 'default'
        });
        setTimeout(() => window.location.reload(), 1500);
      } else {
        console.error('❌ Trial başlatılamadı');
        toast({
          title: 'Hata',
          description: 'Trial başlatılamadı. Lütfen tekrar deneyin.',
          variant: 'destructive'
        });
      }
    } catch (error) {
      console.error('Trial başlatma hatası:', error);
    } finally {
      setProcessing(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50">
        <div className="container mx-auto px-4 py-8">
          <div className="flex items-center justify-center min-h-[400px]">
            <div className="animate-spin rounded-full h-12 w-12 border-4 border-primary border-t-transparent"></div>
          </div>
        </div>
      </div>
    );
  }

  if (subscriptionError) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50">
        <div className="container mx-auto px-4 py-8">
          <div className="text-center">
            <h1 className="text-3xl font-bold mb-4">Premium Özellikler</h1>
            <p className="text-muted-foreground mb-8">
              Premium özellikler şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin.
            </p>
            <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-6 max-w-md mx-auto">
              <p className="text-sm text-yellow-800">
                Sistem hazırlanıyor... Tüm özellikler yakında kullanılabilir olacak.
              </p>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50">
      <div className="container mx-auto px-4 py-8 max-w-7xl">
        {/* Hero Section */}
        <div className="text-center mb-16">
          <div className="inline-flex items-center gap-2 bg-gradient-to-r from-yellow-400 to-orange-500 text-white px-4 py-2 rounded-full text-sm font-medium mb-6">
            <Sparkles className="w-4 h-4" />
            Premium Özellikler
          </div>
          
          <h1 className="text-5xl md:text-6xl font-bold mb-6 bg-gradient-to-r from-blue-600 via-purple-600 to-orange-600 bg-clip-text text-transparent">
            {isPremium ? 'Premium Üyeliğiniz Aktif' : 'Premium\'a Geçin'}
          </h1>
          
          <p className="text-xl text-muted-foreground max-w-3xl mx-auto leading-relaxed">
            {isPremium 
              ? 'Tüm premium özelliklere erişiminiz var. Muhabbet kuşu yetiştiriciliğinizi bir üst seviyeye taşıyın.'
              : 'Muhabbet kuşu yetiştiriciliğinizi profesyonel seviyeye taşıyın. Sınırsız özellikler ve gelişmiş analitikler.'
            }
          </p>
        </div>

        {/* Current Status */}
        {userProfile && (
          <div className="mb-12">
            <Card className="bg-gradient-to-r from-blue-500 to-purple-600 text-white border-0 shadow-xl">
              <CardContent className="pt-8 pb-8">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-4">
                    <div className="w-12 h-12 bg-white/20 rounded-full flex items-center justify-center">
                      {isPremium ? (
                        <Crown className="w-6 h-6" />
                      ) : isTrial ? (
                        <Star className="w-6 h-6" />
                      ) : (
                        <Heart className="w-6 h-6" />
                      )}
                    </div>
                    <div>
                      <h3 className="font-bold text-xl">
                        {isPremium ? 'Premium Üye' : 'Ücretsiz Üye'}
                      </h3>
                      <p className="text-blue-100">
                        {isPremium 
                          ? 'Tüm özelliklere erişiminiz var'
                          : isTrial 
                            ? `${trialInfo.days_remaining} gün trial süreniz kaldı`
                            : 'Temel özelliklerle sınırlı'
                        }
                      </p>
                    </div>
                  </div>
                  {isPremium && (
                    <Badge className="bg-white/20 text-white border-white/30">
                      <Crown className="w-4 h-4 mr-1" />
                      Premium Aktif
                    </Badge>
                  )}
                  {isTrial && (
                    <Badge className="bg-white/20 text-white border-white/30">
                      <Star className="w-4 h-4 mr-1" />
                      Trial Aktif
                    </Badge>
                  )}
                </div>
              </CardContent>
            </Card>
          </div>
        )}

        {/* Billing Cycles */}
        {!isPremium && (
          <div className="mb-12">
            <h2 className="text-3xl font-bold mb-8 text-center">Abonelik Planı Seçin</h2>
            <div className="flex justify-center gap-4 mb-8">
              {billingCycles.map((cycle) => (
                <Button
                  key={cycle.id}
                  variant={selectedCycle === cycle.id ? "default" : "outline"}
                  onClick={() => setSelectedCycle(cycle.id)}
                  className={cn(
                    "relative px-8 py-4 text-lg font-semibold transition-all duration-300 hover:scale-105",
                    cycle.popular && "border-2 border-primary shadow-lg",
                    selectedCycle === cycle.id && "shadow-xl scale-105"
                  )}
                >
                  {cycle.popular && (
                    <Badge className="absolute -top-3 -right-3 text-xs bg-gradient-to-r from-yellow-400 to-orange-500">
                      Popüler
                    </Badge>
                  )}
                  <div className="text-center">
                    <div className="font-bold">{cycle.name}</div>
                    <div className="text-sm opacity-80">
                      {cycle.savings > 0 && `${cycle.savings}% tasarruf`}
                    </div>
                  </div>
                </Button>
              ))}
            </div>
          </div>
        )}

        {/* Plans Comparison */}
        <div className="grid lg:grid-cols-2 gap-8 mb-16">
          {/* Free Plan */}
          <Card className="relative group hover:shadow-xl transition-all duration-300">
            <CardHeader className="text-center pb-4">
              <div className="w-16 h-16 bg-gradient-to-br from-gray-200 to-gray-300 rounded-full flex items-center justify-center mx-auto mb-4">
                <span className="text-2xl font-bold text-gray-600">F</span>
              </div>
              <CardTitle className="text-2xl font-bold">Ücretsiz</CardTitle>
              <CardDescription className="text-lg">
                Temel özellikler ile başlayın
              </CardDescription>
              <div className="text-4xl font-bold text-gray-600">₺0</div>
            </CardHeader>
            <CardContent>
              <ul className="space-y-4 mb-8">
                {freeFeatures.map((feature, index) => (
                  <li key={index} className="flex items-center gap-3">
                    {feature.available ? (
                      <CheckCircle className="w-5 h-5 text-green-500" />
                    ) : (
                      <XCircle className="w-5 h-5 text-gray-400" />
                    )}
                    <span className={cn(
                      "text-sm",
                      feature.available ? "text-gray-700" : "text-gray-400 line-through"
                    )}>
                      {feature.text}
                    </span>
                  </li>
                ))}
              </ul>
              {userProfile?.subscription_status === 'free' && (
                <Button variant="outline" className="w-full" disabled>
                  Mevcut Plan
                </Button>
              )}
            </CardContent>
          </Card>

          {/* Premium Plan */}
          <Card className="relative group hover:shadow-2xl transition-all duration-300 border-2 border-primary bg-gradient-to-br from-primary/5 via-primary/10 to-primary/5">
            <div className="absolute -top-4 left-1/2 transform -translate-x-1/2">
              <Badge className="bg-gradient-to-r from-yellow-400 to-orange-500 text-white px-6 py-2 text-sm font-bold shadow-lg">
                <Crown className="w-4 h-4 mr-1" />
                Önerilen
              </Badge>
            </div>
            
            <CardHeader className="text-center pb-4">
              <div className="w-16 h-16 bg-gradient-to-br from-yellow-400 to-orange-500 rounded-full flex items-center justify-center mx-auto mb-4 shadow-lg">
                <Crown className="w-8 h-8 text-white" />
              </div>
              <CardTitle className="text-2xl font-bold text-primary">Premium</CardTitle>
              <CardDescription className="text-lg">
                Sınırsız özellikler ve gelişmiş analitikler
              </CardDescription>
              <div className="text-4xl font-bold text-primary">
                ₺{selectedCycle === 'monthly' ? premiumPlan?.price_monthly : premiumPlan?.price_yearly}
                <span className="text-lg text-muted-foreground">
                  /{selectedCycle === 'monthly' ? 'ay' : 'yıl'}
                </span>
              </div>
              {selectedCycle === 'yearly' && (
                <div className="text-sm text-green-600 font-bold bg-green-100 px-3 py-1 rounded-full inline-block">
                  %20 tasarruf - Yıllık plan
                </div>
              )}
            </CardHeader>
            <CardContent>
              <ul className="space-y-4 mb-8">
                {premiumFeatures.map((feature, index) => (
                  <li key={index} className="flex items-center gap-3">
                    <CheckCircle className="w-5 h-5 text-green-500" />
                    <span className="text-sm text-gray-700">{feature.text}</span>
                  </li>
                ))}
              </ul>
              
              {isPremium ? (
                <Button variant="outline" className="w-full" disabled>
                  <Crown className="w-4 h-4 mr-2" />
                  Premium Üyesiniz
                </Button>
              ) : (
                <div className="space-y-3">
                  {trialInfo.is_trial_available && !isTrial && (
                    <Button 
                      onClick={handleStartTrial}
                      disabled={processing}
                      className="w-full bg-gradient-to-r from-green-500 to-green-600 hover:from-green-600 hover:to-green-700 text-white"
                      variant="outline"
                    >
                      {processing ? (
                        <div className="flex items-center gap-2">
                          <div className="animate-spin rounded-full h-4 w-4 border-2 border-white border-t-transparent"></div>
                          İşleniyor...
                        </div>
                      ) : (
                        <>
                          <Star className="w-4 h-4 mr-2" />
                          3 Gün Ücretsiz Dene
                        </>
                      )}
                    </Button>
                  )}
                  <Button 
                    onClick={handleUpgrade}
                    disabled={processing}
                    className="w-full bg-gradient-to-r from-primary to-primary/90 hover:from-primary/90 hover:to-primary text-white shadow-lg hover:shadow-xl transition-all duration-300"
                    size="lg"
                  >
                    {processing ? (
                      <div className="flex items-center gap-2">
                        <div className="animate-spin rounded-full h-4 w-4 border-2 border-white border-t-transparent"></div>
                        İşleniyor...
                      </div>
                    ) : (
                      <>
                        Premium'a Geç
                        <ArrowRight className="w-4 h-4 ml-2" />
                      </>
                    )}
                  </Button>
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Features Grid */}
        <div className="mb-16">
          <h2 className="text-3xl font-bold mb-8 text-center">Premium Özellikler</h2>
          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
            {features.map((feature, index) => (
              <Card key={index} className="text-center group hover:shadow-lg transition-all duration-300 hover:-translate-y-1">
                <CardContent className="pt-8 pb-6">
                  <div className={cn(
                    "w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4 transition-all duration-300",
                    feature.highlight 
                      ? "bg-gradient-to-br from-yellow-400 to-orange-500 shadow-lg group-hover:scale-110" 
                      : "bg-gradient-to-br from-primary/10 to-primary/20 group-hover:scale-110"
                  )}>
                    <feature.icon className={cn(
                      "w-8 h-8 transition-all duration-300",
                      feature.highlight ? "text-white" : "text-primary"
                    )} />
                  </div>
                  <h3 className="font-bold text-lg mb-2">{feature.title}</h3>
                  <p className="text-sm text-muted-foreground leading-relaxed">{feature.description}</p>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>

        {/* FAQ */}
        <div className="mb-16">
          <h2 className="text-3xl font-bold mb-8 text-center">Sık Sorulan Sorular</h2>
          <div className="grid md:grid-cols-2 gap-6">
            <Card className="hover:shadow-lg transition-all duration-300">
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <Lock className="w-5 h-5 text-primary" />
                  Premium aboneliği iptal edebilir miyim?
                </CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-muted-foreground leading-relaxed">
                  Evet, istediğiniz zaman aboneliğinizi iptal edebilirsiniz. İptal sonrası dönem sonuna kadar premium özellikleriniz aktif kalır.
                </p>
              </CardContent>
            </Card>
            
            <Card className="hover:shadow-lg transition-all duration-300">
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <Star className="w-5 h-5 text-yellow-500" />
                  3 günlük deneme ücretsiz mi?
                </CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-muted-foreground leading-relaxed">
                  Evet, 3 günlük deneme tamamen ücretsizdir. Kredi kartı bilgisi gerektirmez ve istediğiniz zaman iptal edebilirsiniz.
                </p>
              </CardContent>
            </Card>
            
            <Card className="hover:shadow-lg transition-all duration-300">
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <Shield className="w-5 h-5 text-green-500" />
                  Verilerim güvende mi?
                </CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-muted-foreground leading-relaxed">
                  Tüm verileriniz şifrelenmiş olarak saklanır ve sadece siz erişebilirsiniz. Premium üyeler için otomatik yedekleme de dahildir.
                </p>
              </CardContent>
            </Card>
            
            <Card className="hover:shadow-lg transition-all duration-300">
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <Target className="w-5 h-5 text-blue-500" />
                  Hangi ödeme yöntemleri kabul ediliyor?
                </CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-muted-foreground leading-relaxed">
                  Kredi kartı, banka kartı ve mobil ödeme yöntemlerini kabul ediyoruz. Tüm ödemeler güvenli SSL şifreleme ile korunur.
                </p>
              </CardContent>
            </Card>
          </div>
        </div>

        {/* CTA */}
        {!isPremium && (
          <div className="text-center">
            <Card className="bg-gradient-to-r from-primary/10 via-primary/5 to-purple-500/10 border-primary/20 shadow-xl">
              <CardContent className="pt-12 pb-12">
                <div className="w-20 h-20 bg-gradient-to-br from-primary to-purple-600 rounded-full flex items-center justify-center mx-auto mb-6">
                  <TrendingUp className="w-10 h-10 text-white" />
                </div>
                <h3 className="text-3xl font-bold mb-4">
                  Muhabbet Kuşu Yetiştiriciliğinizi Bir Üst Seviyeye Taşıyın
                </h3>
                <p className="text-muted-foreground mb-8 max-w-2xl mx-auto text-lg leading-relaxed">
                  Premium üyelik ile sınırsız kayıt, gelişmiş analitikler ve profesyonel araçlara erişin. 
                  Deneyiminizi bugün başlatın!
                </p>
                <div className="flex flex-col sm:flex-row gap-4 justify-center">
                  {trialInfo.is_trial_available && !isTrial && (
                    <Button 
                      onClick={handleStartTrial}
                      disabled={processing}
                      variant="outline"
                      size="lg"
                      className="bg-white hover:bg-gray-50"
                    >
                      {processing ? 'İşleniyor...' : '3 Gün Ücretsiz Dene'}
                    </Button>
                  )}
                  <Button 
                    onClick={handleUpgrade}
                    disabled={processing}
                    size="lg"
                    className="bg-gradient-to-r from-primary to-purple-600 hover:from-primary/90 hover:to-purple-700 text-white shadow-lg hover:shadow-xl transition-all duration-300"
                  >
                    {processing ? 'İşleniyor...' : 'Premium\'a Geç'}
                  </Button>
                </div>
              </CardContent>
            </Card>
          </div>
        )}
      </div>
    </div>
  );
};

export default PremiumPage; 