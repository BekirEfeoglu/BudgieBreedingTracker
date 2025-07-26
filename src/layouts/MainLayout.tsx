import React from 'react';
import AppHeader from '@/components/AppHeader';

interface MainLayoutProps {
  children: React.ReactNode;
  onTabChange?: (tab: string) => void;
  isSidebarOpen?: boolean;
  onToggleSidebar?: () => void;
}

export const MainLayout = ({ 
  children, 
  onTabChange, 
  isSidebarOpen = false, 
  onToggleSidebar 
}: MainLayoutProps) => {
  return (
    <div className="min-h-screen bg-background overflow-x-hidden min-w-0 relative">
      {/* Header */}
      <AppHeader 
        onTabChange={onTabChange || (() => {})}
        onToggleSidebar={onToggleSidebar || (() => {})}
        isSidebarOpen={isSidebarOpen}
      />
      
      {/* Main Content */}
      <div className="pb-20 sm:pb-24 md:pb-6 mobile-container min-w-0">
        {children}
      </div>
    </div>
  );
};
