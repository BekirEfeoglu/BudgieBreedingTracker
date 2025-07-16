import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { TrendingUp, TrendingDown, Minus, Calendar, BarChart3 } from 'lucide-react';

interface TrendData {
  period: string;
  value: number;
  change: number;
  trend: 'up' | 'down' | 'stable';
}

interface TrendAnalysisChartProps {
  data: TrendData[];
  title: string;
  subtitle?: string;
  metric: string;
}

const TrendAnalysisChart: React.FC<TrendAnalysisChartProps> = ({
  data,
  title,
  subtitle,
  metric
}) => {
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

  const getTrendColor = (trend: 'up' | 'down' | 'stable') => {
    switch (trend) {
      case 'up':
        return 'text-green-600';
      case 'down':
        return 'text-red-600';
      default:
        return 'text-gray-600';
    }
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <BarChart3 className="w-5 h-5" />
          {title}
        </CardTitle>
        {subtitle && <p className="text-sm text-gray-600">{subtitle}</p>}
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {data.map((item, index) => (
            <div key={index} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg" title={`Dönem: ${item.period}, Değişim: ${item.change}%`}>
              <div className="flex items-center gap-3">
                <Calendar className="w-4 h-4 text-gray-500" />
                <div>
                  <div className="font-medium">{item.period}</div>
                  <div className="text-sm text-gray-600">{item.value} kayıt</div>
                </div>
              </div>
              <div className="flex items-center gap-2">
                <div className={`text-sm font-bold ${getTrendColor(item.trend)}`}>{item.change > 0 ? '+' : ''}{item.change}% <span className="text-xs">{item.change > 0 ? 'Artış' : item.change < 0 ? 'Azalış' : 'Stabil'}</span></div>
                {getTrendIcon(item.trend)}
              </div>
            </div>
          ))}
        </div>
        
                 {/* Trend Summary */}
         <div className="mt-6 p-4 bg-blue-50 rounded-lg">
           <div className="flex items-center gap-2 mb-2">
             <BarChart3 className="w-4 h-4 text-blue-600" />
             <span className="font-medium text-blue-900">Trend Özeti</span>
           </div>
           <div className="text-sm text-blue-800">
             {data.length > 1 && data[data.length - 1] && (
               <div>
                 Son dönemde {data[data.length - 1]?.trend === 'up' ? 'artış' : data[data.length - 1]?.trend === 'down' ? 'azalış' : 'stabil'} trendi gözlemleniyor.
                 {data[data.length - 1]?.trend === 'up' && ' Bu olumlu bir gelişme!'}
                 {data[data.length - 1]?.trend === 'down' && ' Bu durumu iyileştirmek için önlemler alınabilir.'}
               </div>
             )}
           </div>
         </div>
      </CardContent>
    </Card>
  );
};

export default TrendAnalysisChart; 