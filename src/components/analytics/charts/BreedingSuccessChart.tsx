import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { TrendingUp, TrendingDown, Minus } from 'lucide-react';

interface ChartData {
  label: string;
  value: number;
  color: string;
  trend?: 'up' | 'down' | 'stable';
  percentage?: number;
}

interface BreedingSuccessChartProps {
  data: ChartData[];
  title: string;
  subtitle?: string;
}

const BreedingSuccessChart: React.FC<BreedingSuccessChartProps> = ({
  data,
  title,
  subtitle
}) => {
  const maxValue = Math.max(...data.map(d => d.value));

  const getTrendIcon = (trend?: 'up' | 'down' | 'stable') => {
    switch (trend) {
      case 'up':
        return <TrendingUp className="w-4 h-4 text-green-600" />;
      case 'down':
        return <TrendingDown className="w-4 h-4 text-red-600" />;
      default:
        return <Minus className="w-4 h-4 text-gray-400" />;
    }
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-lg">{title}</CardTitle>
        {subtitle && <p className="text-sm text-gray-600">{subtitle}</p>}
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {data.map((item, index) => (
            <div key={index} className="space-y-2">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <div 
                    className="w-3 h-3 rounded-full" 
                    style={{ backgroundColor: item.color }}
                  />
                  <span className="text-sm font-medium">{item.label}</span>
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-sm font-bold">{item.value}</span>
                  {item.percentage && (
                    <span className="text-xs text-gray-600">({item.percentage}%)</span>
                  )}
                  {getTrendIcon(item.trend)}
                </div>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-2">
                <div
                  className="h-2 rounded-full transition-all duration-300"
                  style={{
                    width: `${maxValue > 0 ? (item.value / maxValue) * 100 : 0}%`,
                    backgroundColor: item.color
                  }}
                />
              </div>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
};

export default BreedingSuccessChart; 