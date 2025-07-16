import React from 'react';
import { useLanguage } from '@/contexts/LanguageContext';
import { StatisticsCard, StatisticItem } from './StatisticsCard';
import { Egg as EggIcon, Timer, CheckCircle, Target } from 'lucide-react';
import { Egg } from '@/types';

interface BreedingStatisticsProps {
  totalIncubations: number;
  eggs: Egg[];
}

const BreedingStatistics: React.FC<BreedingStatisticsProps> = ({ totalIncubations, eggs }) => {
  const { t } = useLanguage();

  const totalEggs = eggs.length;
  const hatchedEggs = eggs.filter(egg => egg.status === 'hatched').length;
  const fertileEggs = eggs.filter(egg => egg.status === 'fertile').length;
  const infertileEggs = eggs.filter(egg => egg.status === 'infertile').length;
  const laidEggs = eggs.filter(egg => egg.status === 'laid').length;
  
  const hatchRate = totalEggs > 0 ? ((hatchedEggs / totalEggs) * 100).toFixed(1) : 0;
  const fertilityRate = totalEggs > 0 ? (((fertileEggs + hatchedEggs) / totalEggs) * 100).toFixed(1) : 0;

  return (
    <StatisticsCard
      title={t('home.breedingStats', 'Kuluçka/Yumurta İstatistikleri')}
      icon="🥚"
      iconLabel="Yumurta ikonu"
      gradient="bg-gradient-to-br from-orange-500 via-amber-600 to-yellow-600"
    >
      {/* Grid removed from StatisticsCard, content flows naturally */}
        <StatisticItem
          value={totalIncubations}
          label={t('home.totalIncubations', 'Aktif Kuluçka')}
          icon={Timer}
          iconColor="text-orange-600"
          bgColor="bg-gradient-to-br from-orange-50 to-amber-100 dark:from-orange-950/20 dark:to-amber-900/40"
          textColor="text-orange-700 dark:text-orange-300"
          borderColor="border-orange-200 dark:border-orange-800"
          subtitle="Şu anda kuluçkada olan"
          trend={totalIncubations > 0 ? 'up' : 'neutral'}
          trendValue={totalIncubations > 0 ? 'Aktif' : undefined}
        />
        
        <StatisticItem
          value={totalEggs}
          label={t('home.totalEggs', 'Toplam Yumurta')}
          icon={EggIcon}
          iconColor="text-yellow-600"
          bgColor="bg-gradient-to-br from-yellow-50 to-amber-100 dark:from-yellow-950/20 dark:to-amber-900/40"
          textColor="text-yellow-700 dark:text-yellow-300"
          borderColor="border-yellow-200 dark:border-yellow-800"
          subtitle="Tüm dönemlerden toplam"
          trend={totalEggs > 5 ? 'up' : totalEggs > 0 ? 'neutral' : undefined}
          trendValue={totalEggs > 5 ? `%${fertilityRate} verimli` : undefined}
        />
        
        <StatisticItem
          value={hatchedEggs}
          label={t('home.hatchedEggs', 'Başarılı Çıkış')}
          icon={CheckCircle}
          iconColor="text-green-600"
          bgColor="bg-gradient-to-br from-green-50 to-emerald-100 dark:from-green-950/20 dark:to-emerald-900/40"
          textColor="text-green-700 dark:text-green-300"
          borderColor="border-green-200 dark:border-green-800"
          subtitle={`%${hatchRate} başarı oranı`}
          trend={hatchedEggs > 0 ? 'up' : 'neutral'}
          trendValue={hatchedEggs > 0 ? `%${hatchRate}` : undefined}
        />
        
        <StatisticItem
          value={
            <div className="space-y-1">
              <div className="flex justify-between text-sm">
                <span className="text-red-600">Boş: {infertileEggs}</span>
              </div>
              {laidEggs > 0 && (
                <div className="text-xs text-gray-500">Beklemede: {laidEggs}</div>
              )}
            </div>
          }
          label="Durum Analizi"
          icon={Target}
          iconColor="text-purple-600"
          bgColor="bg-gradient-to-br from-purple-50 to-violet-100 dark:from-purple-950/20 dark:to-violet-900/40"
          textColor="text-purple-700 dark:text-purple-300"
          borderColor="border-purple-200 dark:border-purple-800"
          subtitle={`Verimlilik: %${fertilityRate}`}
        />
    </StatisticsCard>
  );
};

export default BreedingStatistics;