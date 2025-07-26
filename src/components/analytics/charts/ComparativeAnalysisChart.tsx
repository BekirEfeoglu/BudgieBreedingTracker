import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Legend } from 'recharts';
import { useLanguage } from '@/contexts/LanguageContext';

interface ComparativeAnalysisChartProps {
  breeding: Array<{ startDate: string; status: string; maleBird?: { name: string }; femaleBird?: { name: string } }>;
  timeRange: string;
}

const ComparativeAnalysisChart: React.FC<ComparativeAnalysisChartProps> = ({ breeding, timeRange }) => {
  const { t } = useLanguage();

  // Yıl/yıl karşılaştırması
  const yearlyComparison = React.useMemo(() => {
    const currentYear = new Date().getFullYear();
    const lastYear = currentYear - 1;
    
    const currentYearData = breeding.filter(b => {
      const year = new Date(b.startDate).getFullYear();
      return year === currentYear;
    });
    
    const lastYearData = breeding.filter(b => {
      const year = new Date(b.startDate).getFullYear();
      return year === lastYear;
    });

    const currentYearSuccess = currentYearData.filter(b => b.status === 'successful').length;
    const currentYearTotal = currentYearData.length;
    const lastYearSuccess = lastYearData.filter(b => b.status === 'successful').length;
    const lastYearTotal = lastYearData.length;

    return [
      {
        period: `${lastYear}`,
        success: lastYearTotal > 0 ? Math.round((lastYearSuccess / lastYearTotal) * 100) : 0,
        total: lastYearTotal
      },
      {
        period: `${currentYear}`,
        success: currentYearTotal > 0 ? Math.round((currentYearSuccess / currentYearTotal) * 100) : 0,
        total: currentYearTotal
      }
    ];
  }, [breeding]);

  // Ay/ay karşılaştırması (son 6 ay)
  const monthlyComparison = React.useMemo(() => {
    const months = [];
    const currentDate = new Date();
    
    for (let i = 5; i >= 0; i--) {
      const monthDate = new Date(currentDate.getFullYear(), currentDate.getMonth() - i, 1);
      const monthName = monthDate.toLocaleDateString('tr-TR', { month: 'short' });
      
      const monthData = breeding.filter(b => {
        const breedingDate = new Date(b.startDate);
        return breedingDate.getMonth() === monthDate.getMonth() && 
               breedingDate.getFullYear() === monthDate.getFullYear();
      });

      const success = monthData.filter(b => b.status === 'successful').length;
      const total = monthData.length;
      
      months.push({
        month: monthName,
        success: total > 0 ? Math.round((success / total) * 100) : 0,
        total
      });
    }
    
    return months;
  }, [breeding]);

  // En başarılı çiftler karşılaştırması
  const topPairsComparison = React.useMemo(() => {
    const pairStats = new Map<string, { total: number; successful: number }>();

    breeding.forEach(b => {
      const pairKey = `${b.maleBird?.name || 'Erkek'} - ${b.femaleBird?.name || 'Dişi'}`;
      const current = pairStats.get(pairKey) || { total: 0, successful: 0 };
      
      current.total += 1;
      if (b.status === 'successful') {
        current.successful += 1;
      }
      
      pairStats.set(pairKey, current);
    });

    return Array.from(pairStats.entries())
      .map(([pairName, stats]) => ({
        pair: pairName,
        success: Math.round((stats.successful / stats.total) * 100),
        total: stats.total
      }))
      .filter(p => p.total >= 2) // En az 2 deneme yapmış çiftler
      .sort((a, b) => b.success - a.success)
      .slice(0, 5); // En başarılı 5 çift
  }, [breeding]);

  return (
    <Card className="enhanced-card">
      <CardHeader>
        <CardTitle>{t('analytics.comparativeAnalysis')}</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-6">
          {/* Yıl/Yıl Karşılaştırması */}
          <div>
            <h4 className="font-semibold mb-2">{t('analytics.yearlyComparison')}</h4>
            <ResponsiveContainer width="100%" height={200}>
              <BarChart data={yearlyComparison}>
                <XAxis dataKey="period" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Bar dataKey="success" fill="#3b82f6" name="Başarı Oranı (%)" />
                <Bar dataKey="total" fill="#10b981" name="Toplam Deneme" />
              </BarChart>
            </ResponsiveContainer>
          </div>

          {/* Ay/Ay Karşılaştırması */}
          <div>
            <h4 className="font-semibold mb-2">{t('analytics.monthlyComparison')}</h4>
            <ResponsiveContainer width="100%" height={200}>
              <BarChart data={monthlyComparison}>
                <XAxis dataKey="month" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Bar dataKey="success" fill="#f59e0b" name="Başarı Oranı (%)" />
                <Bar dataKey="total" fill="#ef4444" name="Toplam Deneme" />
              </BarChart>
            </ResponsiveContainer>
          </div>

          {/* En Başarılı Çiftler */}
          <div>
            <h4 className="font-semibold mb-2">{t('analytics.topPairsComparison')}</h4>
            <ResponsiveContainer width="100%" height={200}>
              <BarChart data={topPairsComparison} layout="horizontal">
                <XAxis type="number" />
                <YAxis dataKey="pair" type="category" width={100} />
                <Tooltip />
                <Legend />
                <Bar dataKey="success" fill="#8b5cf6" name="Başarı Oranı (%)" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </CardContent>
    </Card>
  );
};

export default ComparativeAnalysisChart; 