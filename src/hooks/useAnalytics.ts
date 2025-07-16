import { useMemo } from 'react';
import { format, subDays, subMonths, subYears, startOfDay, endOfDay, isWithinInterval } from 'date-fns';
import { tr } from 'date-fns/locale';

interface AnalyticsData {
  birds: any[];
  chicks: any[];
  breeding: any[];
  eggs: any[];
  incubations: any[];
  timeRange: '7d' | '30d' | '90d' | '1y' | 'all';
}

interface BreedingSuccessRate {
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
}

interface TrendData {
  labels: string[];
  datasets: Array<{
    label: string;
    data: number[];
    borderColor: string;
    backgroundColor: string;
  }>;
}

interface PerformanceMetrics {
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
}

interface KeyStats {
  totalBirds: number;
  maleBirds: number;
  femaleBirds: number;
  totalChicks: number;
  chicksThisPeriod: number;
  activeIncubations: number;
  eggsInIncubation: number;
}

interface RecentActivity {
  title: string;
  description: string;
  timeAgo: string;
  type: 'breeding' | 'hatch' | 'incubation' | 'egg';
}

interface TopPerformer {
  pairName: string;
  totalAttempts: number;
  successfulAttempts: number;
  successRate: number;
}

export const useAnalytics = ({ birds, chicks, breeding, eggs, incubations, timeRange }: AnalyticsData) => {
  // Güvenli veri kontrolü
  const safeBirds = Array.isArray(birds) ? birds : [];
  const safeChicks = Array.isArray(chicks) ? chicks : [];
  const safeBreeding = Array.isArray(breeding) ? breeding : [];
  const safeEggs = Array.isArray(eggs) ? eggs : [];
  const safeIncubations = Array.isArray(incubations) ? incubations : [];

  // Get date range based on timeRange
  const getDateRange = () => {
    try {
      const now = new Date();
      const end = endOfDay(now);
      
      switch (timeRange) {
        case '7d':
          return { start: startOfDay(subDays(now, 7)), end };
        case '30d':
          return { start: startOfDay(subDays(now, 30)), end };
        case '90d':
          return { start: startOfDay(subDays(now, 90)), end };
        case '1y':
          return { start: startOfDay(subYears(now, 1)), end };
        case 'all':
          return { start: new Date(0), end };
        default:
          return { start: startOfDay(subDays(now, 30)), end };
      }
    } catch (error) {
      console.error('Error in getDateRange:', error);
      const now = new Date();
      return { start: startOfDay(subDays(now, 30)), end: endOfDay(now) };
    }
  };

  const { start, end } = getDateRange();

  // Filter data by date range with error handling
  const filterByDateRange = (data: any[], dateField: string) => {
    try {
      return data.filter(item => {
        if (!item || !item[dateField]) return false;
        const itemDate = new Date(item[dateField]);
        if (isNaN(itemDate.getTime())) return false;
        return isWithinInterval(itemDate, { start, end });
      });
    } catch (error) {
      console.error('Error in filterByDateRange:', error);
      return [];
    }
  };

  // Calculate breeding success rate
  const breedingSuccessRate = useMemo((): BreedingSuccessRate => {
    const currentPeriodBreeding = filterByDateRange(safeBreeding, 'startDate');
    const previousPeriodStart = subDays(start, 30);
    const previousPeriodEnd = subDays(start, 1);
    
    const previousPeriodBreeding = safeBreeding.filter(item => {
      const itemDate = new Date(item.startDate);
      return isWithinInterval(itemDate, { start: previousPeriodStart, end: previousPeriodEnd });
    });

    const currentSuccessful = currentPeriodBreeding.filter(b => b.status === 'successful').length;
    const currentFailed = currentPeriodBreeding.filter(b => b.status === 'failed').length;
    const previousSuccessful = previousPeriodBreeding.filter(b => b.status === 'successful').length;
    const previousFailed = previousPeriodBreeding.filter(b => b.status === 'failed').length;

    // Calculate monthly data for the last 12 months
    const monthlyData = [];
    for (let i = 11; i >= 0; i--) {
      const monthStart = startOfDay(subMonths(new Date(), i));
      const monthEnd = endOfDay(new Date(monthStart.getFullYear(), monthStart.getMonth() + 1, 0));
      
      const monthBreeding = safeBreeding.filter(item => {
        const itemDate = new Date(item.startDate);
        return isWithinInterval(itemDate, { start: monthStart, end: monthEnd });
      });

      const total = monthBreeding.length;
      const successful = monthBreeding.filter(b => b.status === 'successful').length;
      const failed = monthBreeding.filter(b => b.status === 'failed').length;
      const rate = total > 0 ? Math.round((successful / total) * 100) : 0;

      monthlyData.push({
        month: format(monthStart, 'MMM yyyy', { locale: tr }),
        total,
        successful,
        failed,
        rate
      });
    }

    return {
      totalBreedingAttempts: safeBreeding.length,
      successfulBreedings: safeBreeding.filter(b => b.status === 'successful').length,
      currentPeriod: {
        total: currentPeriodBreeding.length,
        successful: currentSuccessful,
        failed: currentFailed
      },
      previousPeriod: {
        total: previousPeriodBreeding.length,
        successful: previousSuccessful,
        failed: previousFailed
      },
      monthlyData
    };
  }, [safeBreeding, start, end]);

  // Calculate trend data
  const trendData = useMemo((): TrendData => {
    const labels = breedingSuccessRate.monthlyData.map(item => item.month);
    
    return {
      labels,
      datasets: [
        {
          label: 'Başarı Oranı (%)',
          data: breedingSuccessRate.monthlyData.map(item => item.rate),
          borderColor: 'rgb(34, 197, 94)',
          backgroundColor: 'rgba(34, 197, 94, 0.1)'
        },
        {
          label: 'Toplam Deneme',
          data: breedingSuccessRate.monthlyData.map(item => item.total),
          borderColor: 'rgb(59, 130, 246)',
          backgroundColor: 'rgba(59, 130, 246, 0.1)'
        }
      ]
    };
  }, [breedingSuccessRate]);

  // Calculate performance metrics
  const performanceMetrics = useMemo((): PerformanceMetrics => {
    const successfulBreedings = safeBreeding.filter(b => b.status === 'successful');
    const totalEggs = safeEggs.length;
    const hatchedEggs = safeEggs.filter(e => e.status === 'hatched').length;
    const totalChicks = safeChicks.length;
    const survivingChicks = safeChicks.filter(c => c.status === 'alive').length;

    // Calculate average incubation time
    const incubationTimes = safeIncubations
      .filter(i => i.endDate)
      .map(i => {
        const start = new Date(i.startDate);
        const end = new Date(i.endDate);
        return Math.ceil((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24));
      });

    const averageIncubationTime = incubationTimes.length > 0 
      ? Math.round(incubationTimes.reduce((sum, time) => sum + time, 0) / incubationTimes.length)
      : 0;

    // Calculate average clutch size
    const clutchSizes = successfulBreedings.map(b => {
      const breedingEggs = safeEggs.filter(e => e.breedingId === b.id);
      return breedingEggs.length;
    });

    const averageClutchSize = clutchSizes.length > 0
      ? Math.round((clutchSizes.reduce((sum, size) => sum + size, 0) / clutchSizes.length) * 10) / 10
      : 0;

    // Calculate seasonal performance
    const seasonalPerformance: Array<{
      season: string;
      successRate: number;
      totalAttempts: number;
    }> = [];
    const seasons = [
      { name: 'İlkbahar', months: [3, 4, 5] },
      { name: 'Yaz', months: [6, 7, 8] },
      { name: 'Sonbahar', months: [9, 10, 11] },
      { name: 'Kış', months: [12, 1, 2] }
    ];

    seasons.forEach(season => {
      const seasonBreeding = safeBreeding.filter(b => {
        const month = new Date(b.startDate).getMonth() + 1;
        return season.months.includes(month);
      });

      const total = seasonBreeding.length;
      const successful = seasonBreeding.filter(b => b.status === 'successful').length;
      const successRate = total > 0 ? Math.round((successful / total) * 100) : 0;

      seasonalPerformance.push({
        season: season.name,
        successRate,
        totalAttempts: total
      });
    });

    return {
      averageIncubationTime,
      averageClutchSize,
      hatchRate: totalEggs > 0 ? Math.round((hatchedEggs / totalEggs) * 100) : 0,
      survivalRate: totalChicks > 0 ? Math.round((survivingChicks / totalChicks) * 100) : 0,
      breedingEfficiency: safeBreeding.length > 0 ? Math.round((successfulBreedings.length / safeBreeding.length) * 100) : 0,
      seasonalPerformance
    };
  }, [safeBreeding, safeEggs, safeChicks, safeIncubations]);

  // Calculate key stats
  const keyStats = useMemo((): KeyStats => {
    const maleBirds = safeBirds.filter(b => b.gender === 'male').length;
    const femaleBirds = safeBirds.filter(b => b.gender === 'female').length;
    const chicksThisPeriod = filterByDateRange(safeChicks, 'hatchDate').length;
    const activeIncubations = safeIncubations.filter(i => i.status === 'active').length;
    const eggsInIncubation = safeEggs.filter(e => e.status === 'incubating').length;

    return {
      totalBirds: safeBirds.length,
      maleBirds,
      femaleBirds,
      totalChicks: safeChicks.length,
      chicksThisPeriod,
      activeIncubations,
      eggsInIncubation
    };
  }, [safeBirds, safeChicks, safeIncubations, safeEggs, start, end]);

  // Generate recent activity
  const recentActivity = useMemo((): RecentActivity[] => {
    const activities: RecentActivity[] = [];

    // Add recent breeding activities
    const recentBreeding = filterByDateRange(safeBreeding, 'startDate')
      .slice(0, 3)
      .map(b => ({
        title: `Üreme Başladı`,
        description: `${b.maleBird?.name || 'Erkek'} ve ${b.femaleBird?.name || 'Dişi'} çifti`,
        timeAgo: formatDistanceToNow(new Date(b.startDate), { locale: tr, addSuffix: true }),
        type: 'breeding' as const
      }));

    // Add recent hatches
    const recentHatches = filterByDateRange(safeChicks, 'hatchDate')
      .slice(0, 3)
      .map(c => ({
        title: `Yavru Çıktı`,
        description: `${c.name || 'Yavru'} yumurtadan çıktı`,
        timeAgo: formatDistanceToNow(new Date(c.hatchDate), { locale: tr, addSuffix: true }),
        type: 'hatch' as const
      }));

    // Add recent egg activities
    const recentEggs = filterByDateRange(safeEggs, 'laidDate')
      .slice(0, 3)
      .map(e => ({
        title: `Yumurta Yumurtlandı`,
        description: `${e.breeding?.femaleBird?.name || 'Dişi'} yumurta yumurtladı`,
        timeAgo: formatDistanceToNow(new Date(e.laidDate), { locale: tr, addSuffix: true }),
        type: 'egg' as const
      }));

    activities.push(...recentBreeding, ...recentHatches, ...recentEggs);
    
    // Sort by date and take top 5
    return activities
      .sort((a, b) => new Date(b.timeAgo).getTime() - new Date(a.timeAgo).getTime())
      .slice(0, 5);
  }, [safeBreeding, safeChicks, safeEggs, start, end]);

  // Calculate top performers
  const topPerformers = useMemo((): TopPerformer[] => {
    const pairStats = new Map<string, { total: number; successful: number }>();

    safeBreeding.forEach(b => {
      const pairKey = `${b.maleBird?.name || 'Erkek'}-${b.femaleBird?.name || 'Dişi'}`;
      const current = pairStats.get(pairKey) || { total: 0, successful: 0 };
      
      current.total += 1;
      if (b.status === 'successful') {
        current.successful += 1;
      }
      
      pairStats.set(pairKey, current);
    });

    return Array.from(pairStats.entries())
      .map(([pairName, stats]) => ({
        pairName,
        totalAttempts: stats.total,
        successfulAttempts: stats.successful,
        successRate: Math.round((stats.successful / stats.total) * 100)
      }))
      .filter(p => p.totalAttempts >= 2) // Only pairs with at least 2 attempts
      .sort((a, b) => b.successRate - a.successRate)
      .slice(0, 10);
  }, [safeBreeding]);

  return {
    breedingSuccessRate,
    trendData,
    performanceMetrics,
    keyStats,
    recentActivity,
    topPerformers
  };
};

// Helper function for date formatting
function formatDistanceToNow(date: Date, options: { locale: any; addSuffix: boolean }) {
  const now = new Date();
  const diffInMs = now.getTime() - date.getTime();
  const diffInDays = Math.floor(diffInMs / (1000 * 60 * 60 * 24));
  const diffInHours = Math.floor(diffInMs / (1000 * 60 * 60));
  const diffInMinutes = Math.floor(diffInMs / (1000 * 60));

  if (diffInDays > 0) {
    return `${diffInDays} gün önce`;
  } else if (diffInHours > 0) {
    return `${diffInHours} saat önce`;
  } else if (diffInMinutes > 0) {
    return `${diffInMinutes} dakika önce`;
  } else {
    return 'Az önce';
  }
} 