import React from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { Progress } from '@/components/ui/progress';
import { Badge } from '@/components/ui/badge';
import { PieChart, BarChart3, TrendingUp, Users, Baby, Egg } from 'lucide-react';

interface BreedingStatsProps {
  breedingSuccessRate: {
    totalBreedingAttempts: number;
    successfulBreedings: number;
    currentPeriod: {
      total: number;
      successful: number;
      failed: number;
    };
    previousPeriod: {
      total: number;
      successful: number;
      failed: number;
    };
    monthlyData: Array<{
      month: string;
      total: number;
      successful: number;
      failed: number;
      rate: number;
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
}

const BreedingStats: React.FC<BreedingStatsProps> = ({ breedingSuccessRate, keyStats }) => {
  if (!breedingSuccessRate) {
    return (
      <div className="flex items-center justify-center h-64 text-muted-foreground">
        İstatistik verisi bulunamadı
      </div>
    );
  }

  const overallRate = breedingSuccessRate.totalBreedingAttempts > 0 
    ? Math.round((breedingSuccessRate.successfulBreedings / breedingSuccessRate.totalBreedingAttempts) * 100) 
    : 0;

  const currentRate = breedingSuccessRate.currentPeriod.total > 0 
    ? Math.round((breedingSuccessRate.currentPeriod.successful / breedingSuccessRate.currentPeriod.total) * 100) 
    : 0;

  const previousRate = breedingSuccessRate.previousPeriod.total > 0 
    ? Math.round((breedingSuccessRate.previousPeriod.successful / breedingSuccessRate.previousPeriod.total) * 100) 
    : 0;

  const rateChange = currentRate - previousRate;

  // Calculate gender distribution
  const totalBreedingPairs = Math.min(keyStats.maleBirds, keyStats.femaleBirds);
  const activePairs = breedingSuccessRate.currentPeriod.total > 0 ? breedingSuccessRate.currentPeriod.total : 0;

  // Calculate productivity metrics
  const chicksPerBreeding = breedingSuccessRate.successfulBreedings > 0 
    ? Math.round((keyStats.totalChicks / breedingSuccessRate.successfulBreedings) * 10) / 10 
    : 0;

  const breedingFrequency = breedingSuccessRate.totalBreedingAttempts > 0 
    ? Math.round((breedingSuccessRate.totalBreedingAttempts / Math.max(keyStats.totalBirds, 1)) * 10) / 10 
    : 0;

  return (
    <div className="space-y-6">
      {/* Overall Statistics */}
      <div className="space-y-4">
        <div className="text-center">
          <div className="text-3xl font-bold mb-2">{overallRate}%</div>
          <div className="text-sm text-muted-foreground">Genel Başarı Oranı</div>
          <Progress value={overallRate} className="mt-3" />
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div className="text-center p-3 rounded-lg bg-muted/50">
            <div className="text-lg font-bold">{breedingSuccessRate.totalBreedingAttempts}</div>
            <div className="text-xs text-muted-foreground">Toplam Deneme</div>
          </div>
          <div className="text-center p-3 rounded-lg bg-muted/50">
            <div className="text-lg font-bold">{breedingSuccessRate.successfulBreedings}</div>
            <div className="text-xs text-muted-foreground">Başarılı</div>
          </div>
        </div>
      </div>

      {/* Period Comparison */}
      <Card>
        <CardContent className="p-4">
          <h4 className="font-medium text-sm mb-3">Dönem Karşılaştırması</h4>
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-sm">Mevcut Dönem</span>
              <div className="flex items-center gap-2">
                <span className="font-bold">{currentRate}%</span>
                <Badge variant="outline" className="text-xs">
                  {breedingSuccessRate.currentPeriod.successful}/{breedingSuccessRate.currentPeriod.total}
                </Badge>
              </div>
            </div>
            <Progress value={currentRate} className="h-2" />
            
            <div className="flex items-center justify-between">
              <span className="text-sm">Önceki Dönem</span>
              <div className="flex items-center gap-2">
                <span className="font-bold">{previousRate}%</span>
                <Badge variant="outline" className="text-xs">
                  {breedingSuccessRate.previousPeriod.successful}/{breedingSuccessRate.previousPeriod.total}
                </Badge>
              </div>
            </div>
            <Progress value={previousRate} className="h-2" />

            <div className="flex items-center justify-center gap-2 pt-2 border-t">
              <TrendingUp className={`w-4 h-4 ${rateChange > 0 ? 'text-green-600' : rateChange < 0 ? 'text-red-600' : 'text-gray-600'}`} />
              <span className={`text-sm font-medium ${rateChange > 0 ? 'text-green-600' : rateChange < 0 ? 'text-red-600' : 'text-gray-600'}`}>
                {rateChange > 0 ? '+' : ''}{rateChange}% değişim
              </span>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Population Statistics */}
      <Card>
        <CardContent className="p-4">
          <h4 className="font-medium text-sm mb-3 flex items-center gap-2">
            <Users className="w-4 h-4" />
            Popülasyon İstatistikleri
          </h4>
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-sm">Toplam Kuş</span>
              <span className="font-bold">{keyStats.totalBirds}</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm">Erkek Kuş</span>
              <span className="font-bold text-blue-600">{keyStats.maleBirds}</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm">Dişi Kuş</span>
              <span className="font-bold text-pink-600">{keyStats.femaleBirds}</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm">Potansiyel Çift</span>
              <span className="font-bold">{totalBreedingPairs}</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm">Aktif Çift</span>
              <span className="font-bold">{activePairs}</span>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Productivity Metrics */}
      <Card>
        <CardContent className="p-4">
          <h4 className="font-medium text-sm mb-3 flex items-center gap-2">
            <BarChart3 className="w-4 h-4" />
            Verimlilik Metrikleri
          </h4>
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-sm">Yavru/Üreme</span>
              <span className="font-bold">{chicksPerBreeding}</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm">Üreme Sıklığı</span>
              <span className="font-bold">{breedingFrequency}</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm">Toplam Yavru</span>
              <span className="font-bold text-green-600">{keyStats.totalChicks}</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm">Bu Dönem Yavru</span>
              <span className="font-bold text-blue-600">{keyStats.chicksThisPeriod}</span>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Current Status */}
      <Card>
        <CardContent className="p-4">
          <h4 className="font-medium text-sm mb-3 flex items-center gap-2">
            <PieChart className="w-4 h-4" />
            Mevcut Durum
          </h4>
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-sm flex items-center gap-2">
                <Egg className="w-4 h-4" />
                Aktif Kuluçka
              </span>
              <span className="font-bold text-yellow-600">{keyStats.activeIncubations}</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm flex items-center gap-2">
                <Egg className="w-4 h-4" />
                Kuluçkadaki Yumurta
              </span>
              <span className="font-bold text-orange-600">{keyStats.eggsInIncubation}</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm flex items-center gap-2">
                <Baby className="w-4 h-4" />
                Bu Dönem Yavru
              </span>
              <span className="font-bold text-green-600">{keyStats.chicksThisPeriod}</span>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Performance Insights */}
      <Card>
        <CardContent className="p-4">
          <h4 className="font-medium text-sm mb-3">Performans İçgörüleri</h4>
          <div className="space-y-2 text-sm">
            {overallRate >= 80 && (
              <div className="text-green-600">
                Mükemmel! %{overallRate} başarı oranınız çok iyi.
              </div>
            )}
            {overallRate >= 60 && overallRate < 80 && (
              <div className="text-blue-600">
                İyi! %{overallRate} başarı oranınız standart seviyede.
              </div>
            )}
            {overallRate < 60 && (
              <div className="text-amber-600">
                %{overallRate} başarı oranınızı iyileştirmek için üreme koşullarını gözden geçirin.
              </div>
            )}
            
            {rateChange > 0 && (
              <div className="text-green-600">
                Başarı oranınız %{Math.abs(rateChange)} artış gösteriyor. Harika!
              </div>
            )}
            {rateChange < 0 && (
              <div className="text-red-600">
                Başarı oranınız %{Math.abs(rateChange)} düşüş gösteriyor. Dikkat edin.
              </div>
            )}
            
            {chicksPerBreeding < 3 && (
              <div className="text-amber-600">
                Yavru sayısı düşük. Beslenme ve bakım koşullarını iyileştirin.
              </div>
            )}
            
            {activePairs < totalBreedingPairs * 0.5 && (
              <div className="text-blue-600">
                Daha fazla çift üremeye teşvik edilebilir.
              </div>
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default BreedingStats; 