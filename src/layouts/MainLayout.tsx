import React, { useState } from 'react';
import NotificationBell from '@/components/NotificationBell';
import { NotificationPanel } from '@/components/NotificationPanel';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { useAuth } from '@/hooks/useAuth';
import { useNavigate } from 'react-router-dom';

interface MainLayoutProps {
  children: React.ReactNode;
}

export const MainLayout = ({ children }: MainLayoutProps) => {
  const [isNotificationPanelOpen, setIsNotificationPanelOpen] = React.useState(false);
  const { profile } = useAuth();
  const navigate = useNavigate();
  const initials = (profile?.first_name?.[0] || '') + (profile?.last_name?.[0] || '');
  
  return (
    <div className="min-h-screen bg-background overflow-x-hidden min-w-0 relative">
      {/* Header */}
      <div className="sticky top-0 z-50 w-full bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 border-b border-border/40">
        <div className="h-12 sm:h-14 flex items-center justify-end px-3 sm:px-4 gap-2 min-w-0">
          {/* Sağ taraf - Bildirimler ve Profil */}
          <button
            type="button"
            className="relative flex items-center justify-center w-10 h-10 sm:w-11 sm:h-11 rounded-full hover:bg-accent transition-colors min-w-0 flex-shrink-0"
            onClick={() => setIsNotificationPanelOpen((open) => !open)}
            aria-label="Bildirimler"
          >
            <NotificationBell />
          </button>
          
          {isNotificationPanelOpen && (
            <>
              {/* Backdrop for mobile */}
              <div 
                className="fixed inset-0 z-40 md:bg-transparent bg-black/20"
                onClick={() => setIsNotificationPanelOpen(false)}
                aria-hidden="true"
              />
              {/* Panel */}
              <div className="absolute top-full right-0 mt-2 z-50 md:w-96 w-[calc(100vw-2rem)] max-w-sm min-w-0">
                <div className="bg-background rounded-lg shadow-xl border border-border/50 overflow-hidden min-w-0">
                  <NotificationPanel 
                    isOpen={isNotificationPanelOpen} 
                    onClose={() => setIsNotificationPanelOpen(false)} 
                  />
                </div>
              </div>
            </>
          )}
          
          {/* Profil avatarı */}
          <button
            type="button"
            className="ml-1 focus:outline-none min-w-0 flex-shrink-0"
            onClick={() => navigate('/profile')}
            aria-label="Profil"
          >
            <Avatar className="h-9 w-9 sm:h-10 sm:w-10 bg-primary/10 text-primary font-bold shadow-md border border-border/40 flex-shrink-0">
              {profile?.avatar_url ? (
                <img 
                  src={profile.avatar_url} 
                  alt="Profil" 
                  className="rounded-full object-cover w-full h-full flex-shrink-0" 
                />
              ) : (
                <AvatarFallback className="text-sm sm:text-base flex-shrink-0">
                  {initials || 'BE'}
                </AvatarFallback>
              )}
            </Avatar>
          </button>
        </div>
      </div>
      
      {/* Main Content */}
      <div className="pb-20 sm:pb-24 md:pb-6 mobile-container min-w-0">
        {children}
      </div>
    </div>
  );
};
