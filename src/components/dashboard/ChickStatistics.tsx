import React from 'react';
import { useLanguage } from '@/contexts/LanguageContext';
import { StatisticsCard, StatisticItem } from './StatisticsCard';
import { Baby, TrendingUp, Calendar, Users } from 'lucide-react';
import { Chick, Egg } from '@/types';
import { differenceInDays } from 'date-fns';

interface ChickStatisticsProps {
  chicks: Chick[];
  eggs: Egg[];
}

const ChickStatistics: React.FC<ChickStatisticsProps> = ({ chicks, eggs }) => {
  const { t } = useLanguage();

  const totalChicks = chicks.length;
  const totalEggs = eggs.length;
  const hatchedEggs = eggs.filter(egg => egg.status === 'hatched').length;
  const survivalRate = totalEggs > 0 ? Math.round((hatchedEggs / totalEggs) * 100) : 0;
  
  // Gender statistics
  const maleChicks = chicks.filter(chick => chick.gender === 'male').length;
  const femaleChicks = chicks.filter(chick => chick.gender === 'female').length;
  const unknownGenderChicks = chicks.filter(chick => chick.gender === 'unknown').length;
  
  // Calculate age groups
  const youngChicks = chicks.filter(chick => {
    const age = differenceInDays(new Date(), new Date(chick.hatchDate));
    return age <= 30; // 30 days or younger
  }).length;
  
  const juvenileChicks = chicks.filter(chick => {
    const age = differenceInDays(new Date(), new Date(chick.hatchDate));
    return age > 30 && age <= 90; // 30-90 days
  }).length;
  
  const adultChicks = chicks.filter(chick => {
    const age = differenceInDays(new Date(), new Date(chick.hatchDate));
    return age > 90; // older than 90 days
  }).length;

  // Recent hatches (last 7 days)
  const recentHatches = chicks.filter(chick => {
    const age = differenceInDays(new Date(), new Date(chick.hatchDate));
    return age <= 7;
  }).length;

  return (
    <StatisticsCard
      title={t('home.chickStats', 'Yavru İstatistikleri')}
      icon="🐣"
      iconLabel="Yavru kuş ikonu"
      gradient="bg-gradient-to-br from-green-500 via-emerald-600 to-teal-600"
    >
      {/* Grid removed from StatisticsCard, content flows naturally */}
        <StatisticItem
          value={totalChicks}
          label={t('home.totalChicks', 'Toplam Yavru')}
          icon={Baby}
          iconColor="text-green-600"
          bgColor="bg-gradient-to-br from-green-50 to-emerald-100 dark:from-green-950/20 dark:to-emerald-900/40"
          textColor="text-green-700 dark:text-green-300"
          borderColor="border-green-200 dark:border-green-800"
          subtitle={`Son 7 günde ${recentHatches} yeni çıkış`}
          trend={recentHatches > 0 ? 'up' : 'neutral'}
          trendValue={recentHatches > 0 ? `+${recentHatches}` : ''}
        />
        
        <StatisticItem
          value={
            <div className="space-y-1">
              <div className="flex justify-between text-sm">
                <span className="text-blue-600">Erkek: {maleChicks}</span>
                <span className="text-pink-600">Dişi: {femaleChicks}</span>
              </div>
              {unknownGenderChicks > 0 && (
                <div className="text-xs text-gray-600">Bilinmeyen: {unknownGenderChicks}</div>
              )}
            </div>
          }
          label="Cinsiyet Dağılımı"
          icon={Users}
          iconColor="text-indigo-600"
          bgColor="bg-gradient-to-br from-indigo-50 to-purple-100 dark:from-indigo-950/20 dark:to-purple-900/40"
          textColor="text-indigo-700 dark:text-indigo-300"
          borderColor="border-indigo-200 dark:border-indigo-800"
          subtitle="Dişi/Erkek oranı"
          className="sm:col-span-1 lg:col-span-1"
        />
        
        <StatisticItem
          value={`${survivalRate}%`}
          label={t('home.survivalRate', 'Başarı Oranı')}
          icon={TrendingUp}
          iconColor="text-blue-600"
          bgColor="bg-gradient-to-br from-blue-50 to-cyan-100 dark:from-blue-950/20 dark:to-cyan-900/40"
          textColor="text-blue-700 dark:text-blue-300"
          borderColor="border-blue-200 dark:border-blue-800"
          subtitle={`${hatchedEggs}/${totalEggs} yumurta çıktı`}
          trend={survivalRate >= 70 ? 'up' : survivalRate >= 50 ? 'neutral' : 'down'}
          trendValue={survivalRate >= 70 ? 'Mükemmel' : survivalRate >= 50 ? 'İyi' : 'Gelişebilir'}
        />
        
        <StatisticItem
          value={
            <div className="space-y-1">
              <div className="flex justify-between text-sm">
                <span className="text-green-600">Genç: {youngChicks}</span>
                <span className="text-blue-600">Orta: {juvenileChicks}</span>
              </div>
              <div className="text-xs text-purple-600">Yetişkin: {adultChicks}</div>
            </div>
          }
          label="Yaş Dağılımı"
          icon={Calendar}
          iconColor="text-purple-600"
          bgColor="bg-gradient-to-br from-purple-50 to-violet-100 dark:from-purple-950/20 dark:to-violet-900/40"
          textColor="text-purple-700 dark:text-purple-300"
          borderColor="border-purple-200 dark:border-purple-800"
          subtitle="Gelişim evreleri"
          className="sm:col-span-1 lg:col-span-1"
        />
    </StatisticsCard>
  );
};

export default ChickStatistics;