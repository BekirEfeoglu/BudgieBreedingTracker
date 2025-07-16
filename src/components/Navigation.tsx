import React from 'react';
import { Button } from '@/components/ui/button';
import { Home, Users, Baby, Calendar, BarChart3, Settings, User } from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';
import { useIsMobile } from '@/hooks/use-mobile';
import { usePushNotifications } from '@/hooks/usePushNotifications';
import { Badge } from '@/components/ui/badge';
import { cn } from '@/lib/utils';

interface NavigationProps {
  activeTab: string;
  onTabChange: (tab: string) => void;
}

const Navigation = ({ activeTab, onTabChange }: NavigationProps) => {
  const { t } = useLanguage();
  const isMobile = useIsMobile();
  const { getNotificationCount } = usePushNotifications();
  const notificationCount = getNotificationCount();
  
  // Tüm sekmeler - tek sıra halinde (kısaltılmış etiketler)
  const allTabs = [
    { id: 'home', label: t('nav.home', 'Ana'), icon: '🏠', color: 'text-blue-600' },
    { id: 'birds', label: t('nav.birds', 'Kuş'), icon: '🦜', color: 'text-green-600' },
    { id: 'breeding', label: t('nav.incubation', 'Kuluç'), icon: '🥚', color: 'text-orange-500' },
    { id: 'chicks', label: t('nav.chicks', 'Yavru'), icon: '🐣', color: 'text-yellow-500' },
    { id: 'genealogy', label: t('nav.genealogy', 'Soy'), icon: '🌳', color: 'text-emerald-600' },
    { id: 'calendar', label: t('nav.calendar', 'Takvim'), icon: '📅', color: 'text-purple-600' },
    { id: 'settings', label: t('nav.settings', 'Ayarlar'), icon: '⚙️', color: 'text-gray-600' },
  ];

  return (
    <div className="bottom-nav-container safe-area-inset-bottom min-w-0">
      <div className="bottom-nav-flex-single-row min-w-0">
        {allTabs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => onTabChange(tab.id)}
            className={cn(
              "nav-item-single-row touch-manipulation mobile-tap-target mobile-no-select flex flex-col items-center justify-center min-w-0",
              activeTab === tab.id
                ? "nav-item-active"
                : "nav-item-inactive"
            )}
            aria-label={tab.label}
            role="tab"
            aria-selected={activeTab === tab.id}
          >
            <div 
              className={cn(
                "nav-icon-single-row transition-all duration-200 flex-shrink-0 min-w-0",
                activeTab === tab.id ? "nav-icon-active" : ""
              )}
              role="img"
              aria-hidden="true"
            >
              {tab.icon}
            </div>
            
            <span 
              className={cn(
                "nav-label-single-row font-medium leading-tight text-center truncate max-w-full min-w-0",
                activeTab === tab.id 
                  ? "nav-label-active" 
                  : "text-muted-foreground"
              )}
            >
              {tab.label}
            </span>

            {/* Bildirim sayacı - sadece Ana Sayfa sekmesinde göster */}
            {tab.id === 'home' && notificationCount > 0 && (
              <Badge 
                variant="destructive" 
                className="absolute -top-1 -right-1 h-4 w-4 p-0 text-xs flex items-center justify-center flex-shrink-0"
              >
                {notificationCount > 99 ? '99+' : notificationCount}
              </Badge>
            )}

            {activeTab === tab.id && (
              <div className="nav-indicator flex-shrink-0" />
            )}
          </button>
        ))}
      </div>
    </div>
  );
};

export default Navigation;
