import React from 'react';
import { useLanguage } from '@/contexts/LanguageContext';
import { StatisticsCard, StatisticItem } from './StatisticsCard';
import { Bird as BirdIcon, Users, Heart } from 'lucide-react';
import { Bird } from '@/types';

interface BirdStatisticsProps {
  birds: Bird[];
  activePairs: number;
}

const BirdStatistics: React.FC<BirdStatisticsProps> = ({ birds, activePairs }) => {
  const { t } = useLanguage();

  const totalBirds = birds.length;
  const maleBirds = birds.filter(bird => bird.gender === 'male').length;
  const femaleBirds = birds.filter(bird => bird.gender === 'female').length;
  const unknownGender = birds.filter(bird => bird.gender === 'unknown').length;
  
  // Calculate growth trend (simplified example)
  const genderRatio = totalBirds > 0 ? ((maleBirds / totalBirds) * 100).toFixed(1) : 0;
  const pairPotential = Math.min(maleBirds, femaleBirds);

  return (
    <StatisticsCard
      title={t('home.birdStats', 'Kuş İstatistikleri')}
      icon="🐦"
      iconLabel="Kuş ikonu"
      gradient="bg-gradient-to-br from-blue-500 via-blue-600 to-indigo-700"
    >
      {/* Grid removed from StatisticsCard, content flows naturally */}
        <StatisticItem
          value={totalBirds}
          label={t('home.totalBirds', 'Toplam Kuş')}
          icon={BirdIcon}
          iconColor="text-blue-600"
          bgColor="bg-gradient-to-br from-blue-50 to-blue-100 dark:from-blue-950/20 dark:to-blue-900/40"
          textColor="text-blue-700 dark:text-blue-300"
          borderColor="border-blue-200 dark:border-blue-800"
          subtitle="Koleksiyonunuzdaki tüm kuşlar"
          trend={totalBirds > 10 ? 'up' : totalBirds > 5 ? 'neutral' : undefined}
          trendValue={totalBirds > 10 ? '+%15' : undefined}
        />
        
        <StatisticItem
          value={activePairs}
          label={t('home.activePairs', 'Aktif Çiftleşme')}
          icon={Heart}
          iconColor="text-pink-600"
          bgColor="bg-gradient-to-br from-pink-50 to-rose-100 dark:from-pink-950/20 dark:to-rose-900/40"
          textColor="text-pink-700 dark:text-pink-300"
          borderColor="border-pink-200 dark:border-pink-800"
          subtitle="Şu anda üreme döneminde"
          trend={activePairs > 0 ? 'up' : 'neutral'}
          trendValue={activePairs > 0 ? 'Aktif' : undefined}
        />

        <StatisticItem
          value={
            <div className="space-y-2">
              <div className="flex justify-between items-center">
                <span className="text-blue-600 font-semibold flex items-center gap-1">
                  ♂ {maleBirds}
                </span>
                <span className="text-pink-600 font-semibold flex items-center gap-1">
                  ♀ {femaleBirds}
                </span>
              </div>
              {unknownGender > 0 && (
                <div className="text-xs text-gray-500">+{unknownGender} belirsiz</div>
              )}
            </div>
          }
          label={t('home.genderSplit', 'Cinsiyet Dağılımı')}
          icon={Users}
          iconColor="text-purple-600"
          bgColor="bg-gradient-to-br from-purple-50 to-violet-100 dark:from-purple-950/20 dark:to-violet-900/40"
          textColor="text-purple-700 dark:text-purple-300"
          borderColor="border-purple-200 dark:border-purple-800"
          className="sm:col-span-1 lg:col-span-1"
          subtitle={`%${genderRatio} erkek, potansiyel ${pairPotential} çift`}
        />
    </StatisticsCard>
  );
};

export default BirdStatistics;