import { memo, useMemo, useCallback } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { ChartContainer, ChartTooltip, ChartTooltipContent } from '@/components/ui/chart';
import { BarChart, Bar, XAxis, YAxis, LineChart, Line, PieChart, Pie, Cell } from 'recharts';
import { useAuth } from '@/hooks/useAuth';
import { useLanguage } from '@/contexts/LanguageContext';
import { format, addDays, startOfMonth, endOfMonth, eachDayOfInterval } from 'date-fns';
import { tr } from 'date-fns/locale';
import { Bird, Breeding, Chick } from '@/types';
import ComponentErrorBoundary from '@/components/errors/ComponentErrorBoundary';
import { Skeleton } from '@/components/ui/skeleton';

interface ModernDashboardProps {
  birds: Bird[];
  breeding: Breeding[];
  chicks: Chick[];
  onTabChange: (tab: string) => void;
  isLoading?: boolean;
}

interface StatCardProps {
  title: string;
  value: number;
  icon: string;
  color: string;
  onClick?: () => void;
  'aria-label'?: string;
}

interface BreedingListItemProps {
  breeding: Breeding;
}

interface ActivityListItemProps {
  activity: {
    icon: string;
    text: string;
    time: string;
  };
}

interface EventListItemProps {
  event: {
    title: string;
    date: string;
  };
}

interface QuickActionProps {
  title: string;
  icon: string;
  onClick: () => void;
  'aria-label'?: string;
}

// Loading component for dashboard sections
const DashboardSectionLoading = () => (
  <div className="space-y-4" role="status" aria-label="Dashboard bölümü yükleniyor">
    <Skeleton className="h-8 w-48" />
    <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
      {Array.from({ length: 4 }).map((_, i) => (
        <Skeleton key={i} className="h-24 w-full" />
      ))}
    </div>
  </div>
);

export const StatCard = memo(({ title, value, icon, color, onClick, 'aria-label': ariaLabel }: StatCardProps) => (
  <Card
    className={`enhanced-card cursor-pointer transition-all duration-300 hover:scale-105 ${onClick ? 'hover:shadow-xl' : ''}`}
    onClick={onClick}
    role={onClick ? 'button' : undefined}
    tabIndex={onClick ? 0 : undefined}
    onKeyDown={onClick ? (e) => {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        onClick();
      }
    } : undefined}
    aria-label={ariaLabel}
  >
    <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
      <CardTitle className="mobile-body font-semibold enhanced-text-secondary">
        {title}
      </CardTitle>
      <span className={`text-xl sm:text-2xl ${color}`} role="img" aria-hidden="true">{icon}</span>
    </CardHeader>
    <CardContent className="pt-2">
      <div className="text-xl sm:text-2xl font-bold enhanced-text-primary">{value}</div>
    </CardContent>
  </Card>
));

StatCard.displayName = 'StatCard';

const ModernDashboard = memo(({ 
  birds, 
  breeding, 
  chicks, 
  onTabChange, 
  isLoading = false 
}: ModernDashboardProps) => {
  const { profile } = useAuth();
  const { t } = useLanguage();

  // Memoized statistics calculations
  const statistics = useMemo(() => {
    const totalBirds = birds.length;
    const activeBreeding = breeding.filter(b =>
      b.eggs && b.eggs.length > 0 && b.eggs.some((egg: any) => egg.status === 'unknown' || egg.status === 'fertile')
    ).length;
    const totalEggs = breeding.reduce((sum, b) => sum + (b.eggs ? b.eggs.length : 0), 0);
    const totalChicks = chicks.length;

    return {
      totalBirds,
      activeBreeding,
      totalEggs,
      totalChicks
    };
  }, [birds, breeding, chicks]);

  // Memoized chart data
  const chartData = useMemo(() => {
    const { totalChicks, totalEggs } = statistics;

    // Son 30 günün verilerini hazırla (örnek veri)
    const last30DaysData = [
      { name: t('home.last_7_days'), yavrular: Math.floor(totalChicks * 0.3), yumurtalar: Math.floor(totalEggs * 0.2) },
      { name: t('home.last_14_days'), yavrular: Math.floor(totalChicks * 0.5), yumurtalar: Math.floor(totalEggs * 0.4) },
      { name: t('home.last_21_days'), yavrular: Math.floor(totalChicks * 0.7), yumurtalar: Math.floor(totalEggs * 0.6) },
      { name: t('home.last_30_days'), yavrular: totalChicks, yumurtalar: totalEggs },
    ];

         // Kuş türü dağılımı (örnek veri - şimdilik sabit değerler)
     const birdTypeData = [
       { name: t('home.budgies'), value: Math.floor(birds.length * 0.6), color: '#3b82f6' },
       { name: t('home.canaries'), value: Math.floor(birds.length * 0.3), color: '#ec4899' },
       { name: t('home.finches'), value: Math.floor(birds.length * 0.1), color: '#6b7280' },
     ].filter(item => item.value > 0);

    // Aylık istatistikler için veri (örnek veri)
    const currentDate = new Date();
    const start = startOfMonth(addDays(currentDate, -365));
    const end = endOfMonth(currentDate);
    const monthlyDates = eachDayOfInterval({ start, end });

    const monthlyStatistics = monthlyDates.map(date => ({
      date: format(date, 'MMM', { locale: tr }),
      yavrular: Math.floor(Math.random() * 10),
      yumurtalar: Math.floor(Math.random() * 20),
    }));

    return {
      last30DaysData,
      birdTypeData,
      monthlyStatistics
    };
  }, [birds, statistics, t]);

  const chartConfig = useMemo(() => ({
    yavrular: {
      label: t('home.chicks'),
      color: "#22c55e",
    },
    yumurtalar: {
      label: t('home.eggs'),
      color: "#f59e0b",
    },
  }), [t]);

  // Memoized handlers
  const handleTabChange = useCallback((tab: string) => {
    onTabChange(tab);
  }, [onTabChange]);

  const BreedingListItem = memo(({ breeding }: BreedingListItemProps) => {
    const fertileEggs = breeding.eggs ? breeding.eggs.filter((egg: any) => egg.status === 'fertile' || egg.status === 'unknown').length : 0;
    return (
      <li className="py-3 border-b border-border last:border-none">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <span className="text-xl" role="img" aria-label="Yumurta">🥚</span>
            <div className="min-w-0 flex-1">
              <p className="mobile-body font-semibold enhanced-text-primary truncate">{t('home.breeding_pair')} #{breeding.id}</p>
              <p className="mobile-text-sm enhanced-text-secondary">{fertileEggs} {t('home.fertile_eggs')}</p>
            </div>
          </div>
          <span className="text-sm text-green-600 font-medium px-2 py-1 bg-green-50 rounded-full dark:bg-green-900/30 dark:text-green-400">{t('home.active')}</span>
        </div>
      </li>
    );
  });

  BreedingListItem.displayName = 'BreedingListItem';

  const ActivityListItem = memo(({ activity }: ActivityListItemProps) => (
    <li className="py-3 border-b border-border last:border-none">
      <div className="flex items-center gap-3">
        <span className="text-xl" role="img" aria-hidden="true">{activity.icon}</span>
        <div className="flex-1 min-w-0">
          <p className="mobile-body font-semibold enhanced-text-primary truncate">{activity.text}</p>
          <p className="mobile-text-sm enhanced-text-secondary">{activity.time}</p>
        </div>
      </div>
    </li>
  ));

  ActivityListItem.displayName = 'ActivityListItem';

  const EventListItem = memo(({ event }: EventListItemProps) => (
    <li className="py-3 border-b border-border last:border-none">
      <div className="flex items-center gap-3">
        <span className="text-xl" role="img" aria-hidden="true">📅</span>
        <div className="flex-1 min-w-0">
          <p className="mobile-body font-semibold enhanced-text-primary truncate">{event.title}</p>
          <p className="mobile-text-sm enhanced-text-secondary">{event.date}</p>
        </div>
      </div>
    </li>
  ));

  EventListItem.displayName = 'EventListItem';

  const QuickAction = memo(({ title, icon, onClick, 'aria-label': ariaLabel }: QuickActionProps) => (
    <button
      onClick={onClick}
      className="enhanced-card p-3 sm:p-4 hover:shadow-lg transition-all duration-300 flex flex-col items-center gap-2 text-center min-h-[90px] w-full"
      aria-label={ariaLabel}
    >
      <span className="text-2xl sm:text-3xl" role="img" aria-hidden="true">{icon}</span>
      <span className="mobile-text-sm font-semibold enhanced-text-primary text-center leading-tight">{title}</span>
    </button>
  ));

  QuickAction.displayName = 'QuickAction';

  if (isLoading) {
    return <DashboardSectionLoading />;
  }

  return (
    <ComponentErrorBoundary>
      <div className="space-y-6 pb-20 md:pb-4 px-2 md:px-0" role="region" aria-label={t('home.dashboardTitle')}>
        {/* Welcome Header - Mobile/Desktop responsive */}
        <div className="text-center pt-4 md:pt-0 px-2">
          <h1 className="mobile-title md:text-3xl mb-3 enhanced-text-primary">
            {t('home.welcomeMessage')}, {profile?.first_name || t('home.welcomeMessage')}! 👋
          </h1>
          <p className="mobile-subtitle enhanced-text-secondary">
            {t('home.welcomeSubtitle')}
          </p>
        </div>

        {/* Key Metrics Cards */}
        <div className="mobile-grid-2 sm:grid-cols-4 gap-4 px-2 md:px-0">
          <StatCard
            title={t('home.totalBirds')}
            value={statistics.totalBirds}
            icon="🦜"
            color="text-green-600"
            onClick={() => handleTabChange('birds')}
            aria-label={`${t('home.totalBirds')}: ${statistics.totalBirds}`}
          />
          <StatCard
            title={t('home.activeBreeding')}
            value={statistics.activeBreeding}
            icon="🥚"
            color="text-orange-500"
            onClick={() => handleTabChange('breeding')}
            aria-label={`${t('home.activeBreeding')}: ${statistics.activeBreeding}`}
          />
          <StatCard
            title={t('home.totalEggs')}
            value={statistics.totalEggs}
            icon="🥚"
            color="text-yellow-500"
            onClick={() => handleTabChange('breeding')}
            aria-label={`${t('home.totalEggs')}: ${statistics.totalEggs}`}
          />
          <StatCard
            title={t('home.totalChicks')}
            value={statistics.totalChicks}
            icon="🐣"
            color="text-blue-500"
            onClick={() => handleTabChange('chicks')}
            aria-label={`${t('home.totalChicks')}: ${statistics.totalChicks}`}
          />
        </div>

        {/* Active Breeding Section */}
        <Card className="enhanced-card mx-2 md:mx-0">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 mobile-title enhanced-text-primary">
              🔥 {t('home.activeBreeding')}
            </CardTitle>
          </CardHeader>
          <CardContent className="p-0">
            <ul className="px-6 pb-6" role="list" aria-label={t('home.activeBreeding')}>
              {breeding.slice(0, 3).map((breedingItem: Breeding) => (
                <BreedingListItem key={breedingItem.id} breeding={breedingItem} />
              ))}
            </ul>
            {breeding.length === 0 && (
              <div className="text-center p-6 enhanced-text-secondary" role="status">
                <span className="text-3xl sm:text-4xl mb-2 block" role="img" aria-hidden="true">🥚</span>
                <p className="mobile-body">{t('home.noActiveBreeding')}</p>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Recent Activities Section */}
        <Card className="enhanced-card mx-2 md:mx-0">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-lg mobile-text-lg enhanced-text-primary">
              ⚡ {t('home.recent_activities')}
            </CardTitle>
          </CardHeader>
          <CardContent className="p-0">
            <ul className="px-6 pb-6">
              {[
                { id: 1, icon: '🥚', text: t('home.activity_egg'), time: '2 saat önce' },
                { id: 2, icon: '🐣', text: t('home.activity_chick'), time: '1 gün önce' },
                { id: 3, icon: '🩺', text: t('home.activity_health'), time: '3 gün önce' },
              ].map(activity => (
                <ActivityListItem key={activity.id} activity={activity} />
              ))}
            </ul>
          </CardContent>
        </Card>

        {/* Upcoming Events Section */}
        <Card className="enhanced-card mx-2 md:mx-0">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-lg mobile-text-lg enhanced-text-primary">
              📅 {t('home.upcoming_events')}
            </CardTitle>
          </CardHeader>
          <CardContent className="p-0">
            <ul className="px-6 pb-6">
              {[
                { id: 1, title: t('home.event_vaccination'), date: '15 Kasım 2024' },
                { id: 2, title: t('home.event_exhibition'), date: '20 Kasım 2024' },
                { id: 3, title: t('home.event_meeting'), date: '25 Kasım 2024' },
              ].map(event => (
                <EventListItem key={event.id} event={event} />
              ))}
            </ul>
          </CardContent>
        </Card>

        {/* Monthly Statistics Charts */}
        <div className="mobile-grid md:grid-cols-2 gap-6 mx-2 md:mx-0">
          {/* Bar Chart */}
          <Card className="enhanced-card">
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-lg mobile-text-lg enhanced-text-primary">
                📊 {t('home.monthly_stats')}
              </CardTitle>
            </CardHeader>
            <CardContent>
              <ChartContainer config={chartConfig} className="h-[200px] md:h-[250px]">
                <BarChart data={chartData.last30DaysData} margin={{ top: 20, right: 30, left: 20, bottom: 5 }}>
                  <XAxis
                    dataKey="name"
                    fontSize={12}
                    tickLine={false}
                    axisLine={false}
                    tick={{ fill: 'hsl(var(--muted-foreground))' }}
                  />
                  <YAxis
                    fontSize={12}
                    tickLine={false}
                    axisLine={false}
                    tick={{ fill: 'hsl(var(--muted-foreground))' }}
                  />
                  <ChartTooltip content={<ChartTooltipContent />} />
                  <Bar
                    dataKey="yavrular"
                    fill="var(--color-yavrular)"
                    radius={[4, 4, 0, 0]}
                  />
                  <Bar
                    dataKey="yumurtalar"
                    fill="var(--color-yumurtalar)"
                    radius={[4, 4, 0, 0]}
                  />
                </BarChart>
              </ChartContainer>
            </CardContent>
          </Card>

          {/* Line Chart */}
          <Card className="enhanced-card">
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-lg mobile-text-lg enhanced-text-primary">
                📈 {t('home.annual_overview')}
              </CardTitle>
            </CardHeader>
            <CardContent>
              <ChartContainer config={chartConfig} className="h-[200px] md:h-[250px]">
                <LineChart data={chartData.monthlyStatistics} margin={{ top: 20, right: 30, left: 20, bottom: 5 }}>
                  <XAxis
                    dataKey="date"
                    fontSize={12}
                    tickLine={false}
                    axisLine={false}
                    tick={{ fill: 'hsl(var(--muted-foreground))' }}
                  />
                  <YAxis
                    fontSize={12}
                    tickLine={false}
                    axisLine={false}
                    tick={{ fill: 'hsl(var(--muted-foreground))' }}
                  />
                  <ChartTooltip content={<ChartTooltipContent />} />
                  <Line
                    type="monotone"
                    dataKey="yavrular"
                    stroke="var(--color-yavrular)"
                    strokeWidth={3}
                    dot={{ fill: 'var(--color-yavrular)', strokeWidth: 2, r: 4 }}
                  />
                  <Line
                    type="monotone"
                    dataKey="yumurtalar"
                    stroke="var(--color-yumurtalar)"
                    strokeWidth={3}
                    dot={{ fill: 'var(--color-yumurtalar)', strokeWidth: 2, r: 4 }}
                  />
                </LineChart>
              </ChartContainer>
            </CardContent>
          </Card>
        </div>

        {/* Bird Type Distribution */}
        <Card className="enhanced-card mx-2 md:mx-0">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-lg mobile-text-lg enhanced-text-primary">
              🎯 {t('home.bird_distribution')}
            </CardTitle>
          </CardHeader>
          <CardContent>
            {chartData.birdTypeData.length > 0 ? (
              <div className="h-[250px] md:h-[300px]">
                <PieChart>
                  <Pie
                    data={chartData.birdTypeData}
                    cx="50%"
                    cy="50%"
                    innerRadius={50}
                    outerRadius={100}
                    paddingAngle={5}
                    dataKey="value"
                  >
                    {chartData.birdTypeData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <ChartTooltip
                    content={({ active, payload }) => {
                      if (active && payload && payload.length && payload[0]?.payload) {
                        const data = payload[0].payload;
                        return (
                          <div className="enhanced-card p-3 shadow-lg">
                            <p className="font-semibold enhanced-text-primary">{data.name}</p>
                            <p className="text-sm enhanced-text-secondary">
                              {data.value} kuş
                            </p>
                          </div>
                        );
                      }
                      return null;
                    }}
                  />
                </PieChart>
                <div className="flex flex-wrap justify-center gap-4 mt-4">
                  {chartData.birdTypeData.map((entry, index) => (
                    <div key={index} className="flex items-center gap-2">
                      <div
                        className="w-4 h-4 rounded-full"
                        style={{ backgroundColor: entry.color }}
                      />
                      <span className="text-sm enhanced-text-primary font-medium">{entry.name} ({entry.value})</span>
                    </div>
                  ))}
                </div>
              </div>
            ) : (
              <div className="h-[250px] flex items-center justify-center enhanced-text-secondary">
                <div className="text-center">
                  <div className="text-6xl mb-4">📊</div>
                  <p className="mobile-text-lg">Henüz kuş verisi yok</p>
                </div>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Quick Actions */}
        <Card className="enhanced-card mx-2 md:mx-0">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-lg mobile-text-lg enhanced-text-primary">
              ⚡ {t('home.quick_actions')}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="mobile-grid-2 sm:grid-cols-4 gap-4">
              <QuickAction
                title={t('home.addBird')}
                icon="🦜"
                onClick={() => handleTabChange('birds')}
                aria-label={t('home.addBird')}
              />
              <QuickAction
                title={t('home.addBreeding')}
                icon="🥚"
                onClick={() => handleTabChange('breeding')}
                aria-label={t('home.addBreeding')}
              />
              <QuickAction
                title={t('home.viewChicks')}
                icon="🐣"
                onClick={() => handleTabChange('chicks')}
                aria-label={t('home.viewChicks')}
              />
              <QuickAction
                title={t('home.viewCalendar')}
                icon="📅"
                onClick={() => handleTabChange('calendar')}
                aria-label={t('home.viewCalendar')}
              />
            </div>
          </CardContent>
        </Card>
      </div>
    </ComponentErrorBoundary>
  );
});

export default ModernDashboard;
