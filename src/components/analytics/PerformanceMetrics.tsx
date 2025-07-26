import React, { memo, useMemo } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Progress } from '@/components/ui/progress';
import { Badge } from '@/components/ui/badge';
import { Clock, Egg, Baby, Target, TrendingUp, Calendar, Thermometer } from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';
import ComponentErrorBoundary from '@/components/errors/ComponentErrorBoundary';

interface PerformanceMetricsProps {
  metrics: {
    averageIncubationTime: number;
    averageClutchSize: number;
    hatchRate: number;
    survivalRate: number;
    breedingEfficiency: number;
    seasonalPerformance: Array<{
      season: string;
      successRate: number;
      totalAttempts: number;
    }>;
  } | null;
  keyStats: {
    totalBirds: number;
    maleBirds: number;
    femaleBirds: number;
    totalChicks: number;
    chicksThisPeriod: number;
    activeIncubations: number;
    eggsInIncubation: number;
  };
  timeRange?: string;
}

const PerformanceMetrics: React.FC<PerformanceMetricsProps> = ({ metrics, keyStats, timeRange: _timeRange }) => {
  const { t } = useLanguage();
  
  // Memoized performance grades for better performance
  const performanceGrades = useMemo(() => {
    const getPerformanceGrade = (rate: number) => {
      if (rate >= 90) return { grade: 'A+', color: 'text-green-600', bg: 'bg-green-50 dark:bg-green-950/20' };
      if (rate >= 80) return { grade: 'A', color: 'text-green-600', bg: 'bg-green-50 dark:bg-green-950/20' };
      if (rate >= 70) return { grade: 'B', color: 'text-blue-600', bg: 'bg-blue-50 dark:bg-blue-950/20' };
      if (rate >= 60) return { grade: 'C', color: 'text-yellow-600', bg: 'bg-yellow-50 dark:bg-yellow-950/20' };
      if (rate >= 50) return { grade: 'D', color: 'text-orange-600', bg: 'bg-orange-50 dark:bg-orange-950/20' };
      return { grade: 'F', color: 'text-red-600', bg: 'bg-red-50 dark:bg-red-950/20' };
    };

    if (!metrics) return null;

    return {
      hatchGrade: getPerformanceGrade(metrics.hatchRate),
      survivalGrade: getPerformanceGrade(metrics.survivalRate),
      efficiencyGrade: getPerformanceGrade(metrics.breedingEfficiency)
    };
  }, [metrics]);

  if (!metrics || !performanceGrades) {
    return (
      <ComponentErrorBoundary>
        <div className="flex items-center justify-center h-64 text-muted-foreground">
          {t('analytics.noData')}
        </div>
      </ComponentErrorBoundary>
    );
  }

  const { hatchGrade, survivalGrade, efficiencyGrade } = performanceGrades;

  return (
    <ComponentErrorBoundary>
      <div className="space-y-6" role="region" aria-label={t('analytics.performance')}>
      {/* Key Performance Indicators */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Incubation Time */}
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <Clock className="w-4 h-4" />
              Ortalama Kuluçka
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{metrics.averageIncubationTime}</div>
            <div className="text-sm text-muted-foreground">gün</div>
            <div className="mt-2 text-xs text-muted-foreground">
              Standart: 18-21 gün
            </div>
          </CardContent>
        </Card>

        {/* Clutch Size */}
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <Egg className="w-4 h-4" />
              Ortalama Yumurta
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{metrics.averageClutchSize}</div>
            <div className="text-sm text-muted-foreground">yumurta/çift</div>
            <div className="mt-2 text-xs text-muted-foreground">
              Standart: 4-8 yumurta
            </div>
          </CardContent>
        </Card>

        {/* Hatch Rate */}
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <Baby className="w-4 h-4" />
              Çıkım Oranı
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{metrics.hatchRate}%</div>
            <div className="flex items-center gap-2 mt-2">
              <Badge className={`text-xs ${hatchGrade.bg} ${hatchGrade.color}`}>
                {hatchGrade.grade}
              </Badge>
            </div>
            <Progress value={metrics.hatchRate} className="mt-2" />
          </CardContent>
        </Card>

        {/* Survival Rate */}
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <Target className="w-4 h-4" />
              Hayatta Kalma
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{metrics.survivalRate}%</div>
            <div className="flex items-center gap-2 mt-2">
              <Badge className={`text-xs ${survivalGrade.bg} ${survivalGrade.color}`}>
                {survivalGrade.grade}
              </Badge>
            </div>
            <Progress value={metrics.survivalRate} className="mt-2" />
          </CardContent>
        </Card>
      </div>

      {/* Efficiency Metrics */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Breeding Efficiency */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <TrendingUp className="w-5 h-5" />
              Üreme Verimliliği
            </CardTitle>
            <CardDescription>
              Genel üreme başarı oranınız ve performans değerlendirmesi
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="text-center">
              <div className="text-3xl font-bold mb-2">{metrics.breedingEfficiency}%</div>
              <div className="flex items-center justify-center gap-2">
                <Badge className={`${efficiencyGrade.bg} ${efficiencyGrade.color}`}>
                  {efficiencyGrade.grade}
                </Badge>
                <span className="text-sm text-muted-foreground">Performans Notu</span>
              </div>
            </div>
            
            <Progress value={metrics.breedingEfficiency} className="h-3" />
            
            <div className="grid grid-cols-2 gap-4 text-sm">
              <div className="text-center p-2 rounded-lg bg-muted/50">
                <div className="font-bold">{keyStats.totalBirds}</div>
                <div className="text-xs text-muted-foreground">Toplam Kuş</div>
              </div>
              <div className="text-center p-2 rounded-lg bg-muted/50">
                <div className="font-bold">{keyStats.totalChicks}</div>
                <div className="text-xs text-muted-foreground">Toplam Yavru</div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Seasonal Performance */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Calendar className="w-5 h-5" />
              Mevsimsel Performans
            </CardTitle>
            <CardDescription>
              Farklı mevsimlerdeki üreme başarı oranları
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {metrics.seasonalPerformance.map((season, index) => (
                <div key={index} className="flex items-center justify-between p-2 rounded-lg bg-muted/50">
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-full bg-primary/20 flex items-center justify-center text-xs font-medium">
                      {index + 1}
                    </div>
                    <div>
                      <div className="text-sm font-medium">{season.season}</div>
                      <div className="text-xs text-muted-foreground">
                        {season.totalAttempts} deneme
                      </div>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="text-sm font-bold">{season.successRate}%</div>
                    <Progress value={season.successRate} className="w-16 h-1 mt-1" />
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Current Status */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Thermometer className="w-5 h-5" />
            Mevcut Durum
          </CardTitle>
          <CardDescription>
            Aktif kuluçka ve yumurta durumları
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="text-center p-4 rounded-lg bg-blue-50 dark:bg-blue-950/20">
              <div className="text-2xl font-bold text-blue-600">{keyStats.activeIncubations}</div>
              <div className="text-sm text-muted-foreground">Aktif Kuluçka</div>
            </div>
            <div className="text-center p-4 rounded-lg bg-yellow-50 dark:bg-yellow-950/20">
              <div className="text-2xl font-bold text-yellow-600">{keyStats.eggsInIncubation}</div>
              <div className="text-sm text-muted-foreground">Kuluçkadaki Yumurta</div>
            </div>
            <div className="text-center p-4 rounded-lg bg-green-50 dark:bg-green-950/20">
              <div className="text-2xl font-bold text-green-600">{keyStats.chicksThisPeriod}</div>
              <div className="text-sm text-muted-foreground">Bu Dönem Yavru</div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Performance Insights */}
      <Card>
        <CardHeader>
          <CardTitle>Performans İçgörüleri</CardTitle>
          <CardDescription>
            Verilerinize dayalı öneriler ve iyileştirme alanları
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {metrics.hatchRate < 70 && (
              <div className="flex items-start gap-3 p-3 rounded-lg bg-amber-50 dark:bg-amber-950/20">
                <Egg className="w-5 h-5 text-amber-600 mt-0.5" />
                <div>
                  <div className="font-medium text-amber-800 dark:text-amber-200">Çıkım Oranınızı İyileştirin</div>
                  <div className="text-sm text-amber-700 dark:text-amber-300">
                    %{metrics.hatchRate} çıkım oranınız standartın altında. Kuluçka koşullarını ve sıcaklık kontrolünü gözden geçirin.
                  </div>
                </div>
              </div>
            )}

            {metrics.survivalRate < 80 && (
              <div className="flex items-start gap-3 p-3 rounded-lg bg-red-50 dark:bg-red-950/20">
                <Baby className="w-5 h-5 text-red-600 mt-0.5" />
                <div>
                  <div className="font-medium text-red-800 dark:text-red-200">Yavru Bakımını İyileştirin</div>
                  <div className="text-sm text-red-700 dark:text-red-300">
                    %{metrics.survivalRate} hayatta kalma oranınız düşük. Yavru bakımı ve beslenme koşullarını kontrol edin.
                  </div>
                </div>
              </div>
            )}

            {metrics.averageIncubationTime > 21 && (
              <div className="flex items-start gap-3 p-3 rounded-lg bg-blue-50 dark:bg-blue-950/20">
                <Clock className="w-5 h-5 text-blue-600 mt-0.5" />
                <div>
                  <div className="font-medium text-blue-800 dark:text-blue-200">Kuluçka Süresi Uzun</div>
                  <div className="text-sm text-blue-700 dark:text-blue-300">
                    {t('common.aboveStandard').replace('{time}', metrics.averageIncubationTime.toString())}
                  </div>
                </div>
              </div>
            )}

            {metrics.breedingEfficiency > 80 && (
              <div className="flex items-start gap-3 p-3 rounded-lg bg-green-50 dark:bg-green-950/20">
                <TrendingUp className="w-5 h-5 text-green-600 mt-0.5" />
                <div>
                  <div className="font-medium text-green-800 dark:text-green-200">Mükemmel Performans!</div>
                  <div className="text-sm text-green-700 dark:text-green-300">
                    %{metrics.breedingEfficiency} üreme verimliliğiniz çok iyi. Bu performansı sürdürmeye devam edin.
                  </div>
                </div>
              </div>
            )}

            {/* Best Season */}
            {(() => {
              const bestSeason = metrics.seasonalPerformance.reduce((best, current) => 
                current.successRate > best.successRate ? current : best
              );
              
              if (bestSeason.successRate > 70) {
                return (
                  <div className="flex items-start gap-3 p-3 rounded-lg bg-purple-50 dark:bg-purple-950/20">
                    <Calendar className="w-5 h-5 text-purple-600 mt-0.5" />
                    <div>
                      <div className="font-medium text-purple-800 dark:text-purple-200">En İyi Mevsim: {bestSeason.season}</div>
                      <div className="text-sm text-purple-700 dark:text-purple-300">
                        %{bestSeason.successRate} başarı oranı ile {bestSeason.season} en verimli mevsiminiz. Bu dönemde daha fazla üreme denemesi yapabilirsiniz.
                      </div>
                    </div>
                  </div>
                );
              }
              return null;
            })()}
          </div>
        </CardContent>
      </Card>
    </div>
    </ComponentErrorBoundary>
  );
};

// Performance optimization: Only re-render if props actually changed
export default memo(PerformanceMetrics, (prevProps, nextProps) => {
  return (
    prevProps.timeRange === nextProps.timeRange &&
    prevProps.metrics === nextProps.metrics &&
    prevProps.keyStats.totalBirds === nextProps.keyStats.totalBirds &&
    prevProps.keyStats.totalChicks === nextProps.keyStats.totalChicks &&
    prevProps.keyStats.activeIncubations === nextProps.keyStats.activeIncubations &&
    prevProps.keyStats.eggsInIncubation === nextProps.keyStats.eggsInIncubation
  );
}); 