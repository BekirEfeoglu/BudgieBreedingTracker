import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { Calendar, TrendingUp, TrendingDown, Minus, Sun, Cloud, Leaf, Snowflake } from 'lucide-react';

interface SeasonalData {
  season: string;
  totalBreedings: number;
  successfulBreedings: number;
  totalEggs: number;
  hatchedEggs: number;
  totalChicks: number;
  survivedChicks: number;
  successRate: number;
  trend: 'up' | 'down' | 'stable';
}

interface SeasonalAnalysisProps {
  data: SeasonalData[];
}

const SeasonalAnalysis: React.FC<SeasonalAnalysisProps> = ({ data }) => {
  const getSeasonIcon = (season: string) => {
    switch (season.toLowerCase()) {
      case 'ilkbahar':
        return <Leaf className="w-5 h-5 text-green-600" />;
      case 'yaz':
        return <Sun className="w-5 h-5 text-yellow-600" />;
      case 'sonbahar':
        return <Cloud className="w-5 h-5 text-orange-600" />;
      case 'kış':
        return <Snowflake className="w-5 h-5 text-blue-600" />;
      default:
        return <Calendar className="w-5 h-5 text-gray-600" />;
    }
  };

  const getTrendIcon = (trend: 'up' | 'down' | 'stable') => {
    switch (trend) {
      case 'up':
        return <TrendingUp className="w-4 h-4 text-green-600" />;
      case 'down':
        return <TrendingDown className="w-4 h-4 text-red-600" />;
      default:
        return <Minus className="w-4 h-4 text-gray-400" />;
    }
  };

  const getSeasonColor = (season: string) => {
    switch (season.toLowerCase()) {
      case 'ilkbahar':
        return 'bg-green-50 border-green-200';
      case 'yaz':
        return 'bg-yellow-50 border-yellow-200';
      case 'sonbahar':
        return 'bg-orange-50 border-orange-200';
      case 'kış':
        return 'bg-blue-50 border-blue-200';
      default:
        return 'bg-gray-50 border-gray-200';
    }
  };

  const getBestSeason = () => {
    if (data.length === 0) return null;
    return data.reduce((best, current) => 
      current.successRate > best.successRate ? current : best
    );
  };

  const getWorstSeason = () => {
    if (data.length === 0) return null;
    return data.reduce((worst, current) => 
      current.successRate < worst.successRate ? current : worst
    );
  };

  const bestSeason = getBestSeason();
  const worstSeason = getWorstSeason();

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Calendar className="w-5 h-5" />
          Sezonluk Analiz
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-6">
          {/* Sezon Kartları */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            {data.map((season, index) => (
              <div
                key={index}
                className={`p-4 rounded-lg border ${getSeasonColor(season.season)}`}
              >
                <div className="flex items-center justify-between mb-3">
                  <div className="flex items-center gap-2">
                    {getSeasonIcon(season.season)}
                    <span className="font-semibold">{season.season}</span>
                  </div>
                  {getTrendIcon(season.trend)}
                </div>
                
                <div className="space-y-2">
                  <div className="text-center">
                    <div className="text-2xl font-bold">{season.successRate}%</div>
                    <div className="text-sm text-gray-600">Başarı Oranı</div>
                  </div>
                  
                  <Progress value={season.successRate} className="h-2" />
                  
                  <div className="text-xs text-gray-600 space-y-1">
                    <div>Üreme: {season.successfulBreedings}/{season.totalBreedings}</div>
                    <div>Yumurta: {season.hatchedEggs}/{season.totalEggs}</div>
                    <div>Yavru: {season.survivedChicks}/{season.totalChicks}</div>
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* En İyi ve En Kötü Sezon */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {bestSeason && (
              <Card className="border-green-200 bg-green-50">
                <CardContent className="p-4">
                  <div className="flex items-center gap-2 mb-2">
                    <TrendingUp className="w-5 h-5 text-green-600" />
                    <span className="font-semibold text-green-800">En İyi Sezon</span>
                  </div>
                  <div className="text-2xl font-bold text-green-600 mb-1">
                    {bestSeason.season}
                  </div>
                  <div className="text-sm text-green-700">
                    %{bestSeason.successRate} başarı oranı ile en yüksek performans
                  </div>
                  <div className="text-xs text-green-600 mt-2">
                    {bestSeason.successfulBreedings} başarılı üreme, {bestSeason.hatchedEggs} çıkan yumurta
                  </div>
                </CardContent>
              </Card>
            )}

            {worstSeason && (
              <Card className="border-red-200 bg-red-50">
                <CardContent className="p-4">
                  <div className="flex items-center gap-2 mb-2">
                    <TrendingDown className="w-5 h-5 text-red-600" />
                    <span className="font-semibold text-red-800">En Kötü Sezon</span>
                  </div>
                  <div className="text-2xl font-bold text-red-600 mb-1">
                    {worstSeason.season}
                  </div>
                  <div className="text-sm text-red-700">
                    %{worstSeason.successRate} başarı oranı ile en düşük performans
                  </div>
                  <div className="text-xs text-red-600 mt-2">
                    {worstSeason.successfulBreedings} başarılı üreme, {worstSeason.hatchedEggs} çıkan yumurta
                  </div>
                </CardContent>
              </Card>
            )}
          </div>

          {/* Sezonluk Öneriler */}
          <Card className="bg-blue-50 border-blue-200">
            <CardContent className="p-4">
              <div className="flex items-center gap-2 mb-3">
                <Calendar className="w-5 h-5 text-blue-600" />
                <span className="font-semibold text-blue-800">Sezonluk Öneriler</span>
              </div>
              <div className="text-sm text-blue-700 space-y-2">
                {bestSeason && (
                  <div>
                    <strong>{bestSeason.season}</strong> sezonunda en yüksek performans gösteriyorsunuz. 
                    Bu sezondaki koşulları diğer sezonlarda da sağlamaya çalışın.
                  </div>
                )}
                {worstSeason && (
                  <div>
                    <strong>{worstSeason.season}</strong> sezonunda performansınız düşük. 
                    Bu sezonda ekstra özen gösterin ve koşulları iyileştirin.
                  </div>
                )}
                <div>
                  Genel olarak ilkbahar ve yaz ayları üreme için en uygun dönemlerdir. 
                  Kış aylarında ısıtma ve aydınlatma koşullarını optimize edin.
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </CardContent>
    </Card>
  );
};

export default SeasonalAnalysis; 