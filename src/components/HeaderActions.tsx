import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Bell, User, Menu } from 'lucide-react';
import { useAuth } from '@/hooks/useAuth';
import { useNotifications } from '@/contexts/notifications';
import { useLanguage } from '@/contexts/LanguageContext';
import NotificationBell from '@/components/NotificationBell';
import { NotificationPanel } from '@/components/NotificationPanel';
import { useIsMobile } from '@/hooks/use-mobile';

interface HeaderActionsProps {
  activeTab: string;
  onTabChange: (tab: string) => void;
}

const HeaderActions = ({ activeTab, onTabChange }: HeaderActionsProps) => {
  const { profile } = useAuth();
  const { t } = useLanguage();
  const [isNotificationPanelOpen, setIsNotificationPanelOpen] = useState(false);

  // Başlangıç harfleri hesaplamayı memoize et - gereksiz yeniden render'ları önle
  const initials = React.useMemo(() => {
    const first = profile?.first_name || '';
    const last = profile?.last_name || '';
    return `${first.charAt(0)}${last.charAt(0)}`.toUpperCase();
  }, [profile?.first_name, profile?.last_name]);

  return (
    <div className="fixed top-4 right-4 z-[110] flex items-center gap-2">
      {/* Profil Butonu - Mobil optimized */}
      {!isNotificationPanelOpen && (
        <Button
          variant="ghost"
          size="icon"
          onClick={() => onTabChange('profile')}
          className={`relative touch-target mobile-tap-target bg-background/90 backdrop-blur-md border border-border/50 shadow-lg hover:bg-primary/10 hover:border-primary/20 transition-all duration-200 rounded-full ${
            activeTab === 'profile' ? 'bg-primary/20 border-primary/30' : ''
          }`}
          aria-label={t('nav.profile')}
        >
          <Avatar className="h-7 w-7 bg-background/95 backdrop-blur-sm border border-border/50">
            <AvatarImage 
              src={profile?.avatar_url || ''} 
              alt={t('nav.profile')}
              className="object-cover"
            />
            <AvatarFallback className="bg-primary/10 text-primary font-semibold text-xs">
              {initials || <User className="h-4 w-4" />}
            </AvatarFallback>
          </Avatar>
        </Button>
      )}
    </div>
  );
};

export default HeaderActions;
