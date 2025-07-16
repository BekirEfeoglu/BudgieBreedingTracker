import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Progress } from '@/components/ui/progress';
import { ChevronLeft, ChevronRight, X, Play, CheckCircle } from 'lucide-react';
import { cn } from '@/lib/utils';

interface OnboardingStep {
  id: string;
  title: string;
  description: string;
  icon: string;
  content: React.ReactNode;
  animation?: string;
  image?: string;
}

interface OnboardingScreenProps {
  isOpen: boolean;
  onClose: () => void;
  onComplete: () => void;
}

const OnboardingScreen: React.FC<OnboardingScreenProps> = ({
  isOpen,
  onClose,
  onComplete
}) => {
  const [currentStep, setCurrentStep] = useState(0);

  const steps: OnboardingStep[] = [
    {
      id: 'welcome',
              title: 'BudgieBreedingTracker\'e Hoş Geldiniz! 🎉',
      description: 'Muhabbet kuşu üretim takibiniz için profesyonel platform',
      icon: '🦜',
      animation: 'animate-fade-in',
      content: (
        <div className="text-center space-y-4 px-2">
          <div className="relative mx-auto w-20 h-20 sm:w-24 sm:h-24 md:w-32 md:h-32">
            <div className="w-20 h-20 sm:w-24 sm:h-24 md:w-32 md:h-32 bg-gradient-to-br from-blue-500 to-blue-600 transform rotate-45 rounded-2xl shadow-lg animate-pulse"></div>
            <div className="absolute inset-0 flex items-center justify-center">
              <span className="text-3xl sm:text-4xl md:text-6xl transform -rotate-45" role="img">🦜</span>
            </div>
          </div>
          <div className="space-y-2">
            <h2 className="text-lg sm:text-xl md:text-2xl font-bold bg-gradient-to-r from-blue-600 via-green-600 to-teal-600 bg-clip-text text-transparent">
              Profesyonel Üretim Takibi
            </h2>
            <p className="text-sm sm:text-base text-muted-foreground max-w-md mx-auto leading-relaxed">
              Kuşlarınızı kaydedin, kuluçka süreçlerini takip edin, yavrularınızı izleyin. 
              Her şey bir arada, kolay kullanım ile.
            </p>
          </div>
        </div>
      )
    },
    {
      id: 'birds',
      title: 'Kuşlarınızı Kaydedin 🐦',
      description: 'İlk adım: Kuş koleksiyonunuzu oluşturun',
      icon: '🐦',
      animation: 'animate-slide-up',
      content: (
        <div className="space-y-4 px-2">
          <div className="grid grid-cols-2 gap-3">
            <div className="bg-blue-50 dark:bg-blue-950/20 p-3 rounded-lg border-2 border-blue-200 dark:border-blue-800 hover:scale-105 transition-transform">
              <div className="text-center space-y-2">
                <div className="text-2xl">♂️</div>
                <div className="text-sm font-medium text-blue-600">Erkek Kuşlar</div>
                <div className="text-xs text-muted-foreground">Baba adayları</div>
              </div>
            </div>
            <div className="bg-pink-50 dark:bg-pink-950/20 p-3 rounded-lg border-2 border-pink-200 dark:border-pink-800 hover:scale-105 transition-transform">
              <div className="text-center space-y-2">
                <div className="text-2xl">♀️</div>
                <div className="text-sm font-medium text-pink-600">Dişi Kuşlar</div>
                <div className="text-xs text-muted-foreground">Anne adayları</div>
              </div>
            </div>
          </div>
          <div className="bg-gradient-to-r from-green-50 to-blue-50 dark:from-green-950/20 dark:to-blue-950/20 p-4 rounded-lg border border-green-200 dark:border-green-800">
            <h3 className="text-sm font-semibold mb-2 flex items-center gap-2">
              <span role="img">📝</span>
              Her kuş için kaydedilecek bilgiler:
            </h3>
            <ul className="text-xs space-y-1 text-muted-foreground">
              <li>• İsim ve cinsiyet</li>
              <li>• Doğum tarihi ve renk</li>
              <li>• Halka numarası (opsiyonel)</li>
              <li>• Anne-baba bilgileri</li>
              <li>• Sağlık notları</li>
            </ul>
          </div>
        </div>
      )
    },
    {
      id: 'breeding',
      title: 'Kuluçka Süreçleri 🥚',
      description: 'Üretim takibinizi başlatın',
      icon: '🥚',
      animation: 'animate-scale-in',
      content: (
        <div className="space-y-4 px-2">
          <div className="grid grid-cols-3 gap-2">
            <div className="text-center space-y-2 p-3 bg-orange-50 dark:bg-orange-950/20 rounded-lg border border-orange-200 dark:border-orange-800">
              <div className="text-xl animate-bounce">🥚</div>
              <div className="text-xs font-medium">Yumurtlama</div>
            </div>
            <div className="text-center space-y-2 p-3 bg-yellow-50 dark:bg-yellow-950/20 rounded-lg border border-yellow-200 dark:border-yellow-800">
              <div className="text-xl animate-pulse">⏰</div>
              <div className="text-xs font-medium">Kuluçka</div>
            </div>
            <div className="text-center space-y-2 p-3 bg-green-50 dark:bg-green-950/20 rounded-lg border border-green-200 dark:border-green-800">
              <div className="text-xl animate-bounce">🐣</div>
              <div className="text-xs font-medium">Çıkış</div>
            </div>
          </div>
          <div className="bg-gradient-to-r from-orange-50 to-green-50 dark:from-orange-950/20 dark:to-green-950/20 p-4 rounded-lg border border-orange-200 dark:border-orange-800">
            <h3 className="text-sm font-semibold mb-2 flex items-center gap-2">
              <span role="img">🎯</span>
              Otomatik takip özellikleri:
            </h3>
            <ul className="text-xs space-y-1 text-muted-foreground">
              <li>• Her yumurta için ayrı takip</li>
              <li>• Tahmini çıkış tarihleri</li>
              <li>• Bildirimler ve hatırlatıcılar</li>
              <li>• Başarı oranı istatistikleri</li>
            </ul>
          </div>
        </div>
      )
    },
    {
      id: 'features',
      title: 'Güçlü Özellikler ⚡',
      description: 'Tüm ihtiyacınız bir arada',
      icon: '⚡',
      animation: 'animate-fade-in',
      content: (
        <div className="space-y-3 px-2">
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-3">
              <div className="bg-purple-50 dark:bg-purple-950/20 p-3 rounded-lg border border-purple-200 dark:border-purple-800">
                <div className="flex items-center gap-2 mb-2">
                  <span role="img" className="text-base">📊</span>
                  <span className="text-sm font-medium">İstatistikler</span>
                </div>
                <p className="text-xs text-muted-foreground">Detaylı raporlar ve analiz</p>
              </div>
              <div className="bg-blue-50 dark:bg-blue-950/20 p-3 rounded-lg border border-blue-200 dark:border-blue-800">
                <div className="flex items-center gap-2 mb-2">
                  <span role="img" className="text-base">🌳</span>
                  <span className="text-sm font-medium">Soy Ağacı</span>
                </div>
                <p className="text-xs text-muted-foreground">Genetik takip</p>
              </div>
            </div>
            <div className="space-y-3">
              <div className="bg-green-50 dark:bg-green-950/20 p-3 rounded-lg border border-green-200 dark:border-green-800">
                <div className="flex items-center gap-2 mb-2">
                  <span role="img" className="text-base">📱</span>
                  <span className="text-sm font-medium">Mobil Uyumlu</span>
                </div>
                <p className="text-xs text-muted-foreground">Her yerden erişim</p>
              </div>
              <div className="bg-red-50 dark:bg-red-950/20 p-3 rounded-lg border border-red-200 dark:border-red-800">
                <div className="flex items-center gap-2 mb-2">
                  <span role="img" className="text-base">☁️</span>
                  <span className="text-sm font-medium">Bulut Yedek</span>
                </div>
                <p className="text-xs text-muted-foreground">Güvenli saklama</p>
              </div>
            </div>
          </div>
        </div>
      )
    },
    {
      id: 'complete',
      title: 'Hazırsınız! 🚀',
      description: 'Hemen başlamaya hazır mısınız?',
      icon: '🚀',
      animation: 'animate-fade-in',
      content: (
        <div className="text-center space-y-4 px-2">
          <div className="text-4xl sm:text-6xl animate-bounce">🎉</div>
          <div className="space-y-2">
            <h2 className="text-lg sm:text-xl font-bold text-green-600">Tebrikler!</h2>
            <p className="text-sm text-muted-foreground max-w-md mx-auto leading-relaxed">
              Artık muhabbet kuşu üretim takibinizi başlatmaya hazırsınız. 
              İlk kuşunuzu ekleyerek başlayabilirsiniz.
            </p>
          </div>
          <div className="bg-gradient-to-r from-green-50 to-blue-50 dark:from-green-950/20 dark:to-blue-950/20 p-4 rounded-lg border border-green-200 dark:border-green-800">
            <h3 className="text-sm font-semibold mb-2">İlk adımlar:</h3>
            <div className="text-xs space-y-1 text-muted-foreground">
              <div className="flex items-center gap-2">
                <CheckCircle className="w-3 h-3 text-green-500 flex-shrink-0" />
                <span>Ana sayfadan "Kuş Ekle" butonuna tıklayın</span>
              </div>
              <div className="flex items-center gap-2">
                <CheckCircle className="w-3 h-3 text-green-500 flex-shrink-0" />
                <span>En az bir erkek ve bir dişi kuş ekleyin</span>
              </div>
              <div className="flex items-center gap-2">
                <CheckCircle className="w-3 h-3 text-green-500 flex-shrink-0" />
                <span>İlk kuluçkanızı başlatın</span>
              </div>
            </div>
          </div>
        </div>
      )
    }
  ];

  const progress = ((currentStep + 1) / steps.length) * 100;

  const handleNext = () => {
    if (currentStep < steps.length - 1) {
      setCurrentStep(currentStep + 1);
    } else {
      handleComplete();
    }
  };

  const handlePrev = () => {
    if (currentStep > 0) {
      setCurrentStep(currentStep - 1);
    }
  };

  const handleComplete = () => {
    localStorage.setItem('onboarding_completed', 'true');
    onComplete();
    onClose();
  };

  const handleSkip = () => {
    localStorage.setItem('onboarding_completed', 'true');
    localStorage.setItem('onboarding_skipped', 'true');
    onClose();
  };

  if (!isOpen) return null;

  const currentStepData = steps[currentStep];
  if (!currentStepData) return null;

  return (
    <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-sm flex items-center justify-center p-3">
      <Card className="w-full max-w-lg max-h-[95vh] overflow-hidden shadow-2xl">
        <CardContent className="p-0">
          {/* Header */}
          <div className="flex items-center justify-between p-4 border-b border-border/50">
            <div className="flex items-center gap-3 flex-1 min-w-0">
              <div className="text-xl flex-shrink-0" role="img" aria-label={currentStepData.title}>
                {currentStepData.icon}
              </div>
              <div className="min-w-0 flex-1">
                <h1 className="text-base font-semibold truncate">{currentStepData.title}</h1>
                <p className="text-xs text-muted-foreground line-clamp-1">{currentStepData.description}</p>
              </div>
            </div>
            <Button
              variant="ghost"
              size="sm"
              onClick={handleSkip}
              className="text-muted-foreground hover:text-foreground flex-shrink-0 ml-2"
            >
              <X className="w-4 h-4" />
            </Button>
          </div>

          {/* Progress */}
          <div className="px-4 py-3 bg-muted/30">
            <div className="flex items-center justify-between text-xs text-muted-foreground mb-2">
              <span>Adım {currentStep + 1} / {steps.length}</span>
              <span>{Math.round(progress)}%</span>
            </div>
            <Progress value={progress} className="h-2" />
          </div>

          {/* Content */}
          <div className="flex-1 p-4 min-h-[320px] flex items-center overflow-y-auto">
            <div className={cn("w-full", currentStepData.animation)}>
              {currentStepData.content}
            </div>
          </div>

          {/* Footer */}
          <div className="p-4 border-t border-border/50 bg-muted/20">
            {/* Mobile: Stack buttons vertically */}
            <div className="flex flex-col gap-3 sm:hidden">
              <Button
                onClick={handleNext}
                className="w-full flex items-center justify-center gap-2 bg-primary hover:bg-primary/90 text-primary-foreground h-12"
              >
                {currentStep === steps.length - 1 ? (
                  <>
                    Başla
                    <Play className="w-4 h-4" />
                  </>
                ) : (
                  <>
                    Sonraki
                    <ChevronRight className="w-4 h-4" />
                  </>
                )}
              </Button>
              
              <div className="flex gap-3">
                <Button
                  variant="ghost"
                  onClick={handlePrev}
                  disabled={currentStep === 0}
                  className="flex-1 flex items-center justify-center gap-2 h-10"
                >
                  <ChevronLeft className="w-4 h-4" />
                  Önceki
                </Button>
                <Button
                  variant="outline"
                  onClick={handleSkip}
                  className="flex-1 h-10"
                >
                  Geç
                </Button>
              </div>
            </div>

            {/* Desktop: Horizontal layout */}
            <div className="hidden sm:flex items-center justify-between">
              <Button
                variant="ghost"
                onClick={handlePrev}
                disabled={currentStep === 0}
                className="flex items-center gap-2"
              >
                <ChevronLeft className="w-4 h-4" />
                Önceki
              </Button>

              <div className="flex items-center gap-2">
                <Button
                  variant="outline"
                  onClick={handleSkip}
                >
                  Geç
                </Button>
                <Button
                  onClick={handleNext}
                  className="flex items-center gap-2 bg-primary hover:bg-primary/90"
                >
                  {currentStep === steps.length - 1 ? (
                    <>
                      Başla
                      <Play className="w-4 h-4" />
                    </>
                  ) : (
                    <>
                      Sonraki
                      <ChevronRight className="w-4 h-4" />
                    </>
                  )}
                </Button>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default OnboardingScreen;
