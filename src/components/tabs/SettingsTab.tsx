import React, { Suspense, memo } from 'react';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { useLanguage } from '@/contexts/LanguageContext';
import { Card } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import ComponentErrorBoundary from '@/components/errors/ComponentErrorBoundary';

// Lazy load components for better performance
const LanguageSettings = React.lazy(() => import('@/components/settings/LanguageSettings'));
const NotificationSettings = React.lazy(() => import('@/components/settings/NotificationSettings'));
const TemperatureSensorIntegration = React.lazy(() => import('@/components/sensors/TemperatureSensorIntegration'));
const BackupSettings = React.lazy(() => import('@/components/settings/BackupSettings'));
const DataRestoreSettings = React.lazy(() => import('@/components/settings/DataRestoreSettings'));
const AutoBackupSettings = React.lazy(() => import('@/components/settings/AutoBackupSettings').then(module => ({ default: module.AutoBackupSettings })));
const AppearanceSettings = React.lazy(() => import('@/components/settings/AppearanceSettings'));
const DangerZoneSettings = React.lazy(() => import('@/components/settings/DangerZoneSettings'));
const SupportSettings = React.lazy(() => import('@/components/settings/SupportSettings'));

// Loading component
const SettingsLoading = () => (
  <Card className="p-4 sm:p-6 min-w-0">
    <div className="space-y-4 min-w-0">
      <Skeleton className="h-6 w-48 min-w-0" />
      <Skeleton className="h-4 w-full min-w-0" />
      <Skeleton className="h-4 w-3/4 min-w-0" />
      <div className="space-y-2 min-w-0">
        <Skeleton className="h-10 w-full min-w-0" />
        <Skeleton className="h-10 w-full min-w-0" />
      </div>
    </div>
  </Card>
);

// Error fallback component
const _SettingsError = ({ error: _error, resetError }: { error: Error; resetError: () => void }) => (
  <Card className="p-4 sm:p-6 border-red-200 bg-red-50 min-w-0">
    <div className="text-center space-y-4 min-w-0">
      <h3 className="text-lg font-semibold text-red-800 truncate max-w-full min-w-0">Ayarlar Yüklenemedi</h3>
      <p className="text-red-600 truncate max-w-full min-w-0">Bu bölümde bir hata oluştu.</p>
      <button 
        onClick={resetError}
        className="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700 transition-colors min-h-[44px] min-w-0"
      >
        Tekrar Dene
      </button>
    </div>
  </Card>
);

const SettingsTab = memo(() => {
  const { t } = useLanguage();

  const tabConfig = [
    {
      value: "general",
      label: t('settings.tabs.general', 'Genel'),
      component: LanguageSettings,
      icon: "🌐"
    },
    {
      value: "notifications",
      label: t('settings.tabs.notifications', 'Bildirimler'),
      component: NotificationSettings,
      icon: "🔔"
    },
    {
      value: "sensors",
      label: t('settings.tabs.sensors', 'Sensörler'),
      component: TemperatureSensorIntegration,
      icon: "🌡️"
    },
    {
      value: "backup",
      label: t('settings.tabs.backup', 'Yedekleme'),
      component: () => (
        <>
          <BackupSettings />
          <DataRestoreSettings />
          <DangerZoneSettings />
        </>
      ),
      icon: "💾"
    },
    {
      value: "auto-backup",
      label: t('settings.tabs.autoBackup', 'Otomatik Yedek'),
      component: AutoBackupSettings,
      icon: "⚡"
    },
    {
      value: "appearance",
      label: t('settings.tabs.appearance', 'Görünüm'),
      component: AppearanceSettings,
      icon: "🎨"
    },
    {
      value: "support",
      label: t('settings.tabs.support', 'Destek'),
      component: SupportSettings,
      icon: "❓"
    }
  ];

  return (
    <div className="space-y-4 sm:space-y-6 pb-20 md:pb-4 px-2 md:px-0 min-w-0" role="main" aria-label="Ayarlar">
      {/* Header */}
      <div className="mobile-header min-w-0">
        <div className="min-w-0 flex-1">
          <h2 className="mobile-header-title truncate max-w-full min-w-0">
            {t('settings.title', 'Ayarlar')}
          </h2>
          <p className="text-sm text-muted-foreground mt-1 truncate max-w-full min-w-0">
            {t('settings.subtitle', 'Uygulamanızı özelleştirin')}
          </p>
        </div>
      </div>

      <Tabs defaultValue="general" className="space-y-4 min-w-0">
        {/* Responsive tab list */}
        <TabsList className="grid w-full grid-cols-2 sm:grid-cols-4 lg:grid-cols-8 h-auto p-1 gap-1 bg-muted/50 min-w-0 overflow-x-auto">
          {tabConfig.map((tab) => (
            <TabsTrigger 
              key={tab.value}
              value={tab.value} 
              className="text-xs py-2 px-1 data-[state=active]:bg-primary data-[state=active]:text-primary-foreground transition-all duration-200 hover:bg-muted flex flex-col items-center gap-1 min-h-[60px] truncate max-w-full min-w-0 flex-shrink-0"
              aria-label={`${tab.label} ayarları`}
            >
              <span className="text-base flex-shrink-0" role="img" aria-hidden="true">
                {tab.icon}
              </span>
              <span className="truncate max-w-full min-w-0">
                {tab.label}
              </span>
            </TabsTrigger>
          ))}
        </TabsList>

        {/* Tab content with error boundaries and suspense */}
        {tabConfig.map((tab) => (
          <TabsContent key={tab.value} value={tab.value} className="space-y-4 mt-4 min-w-0">
            <ComponentErrorBoundary
              onError={(error: Error) => {
                console.error(`Settings tab error (${tab.value}):`, error);
              }}
            >
              <Suspense fallback={<SettingsLoading />}>
                <div className="min-w-0 w-full">
                  <tab.component />
                </div>
              </Suspense>
            </ComponentErrorBoundary>
          </TabsContent>
        ))}
      </Tabs>
    </div>
  );
});

SettingsTab.displayName = 'SettingsTab';

export default SettingsTab;
