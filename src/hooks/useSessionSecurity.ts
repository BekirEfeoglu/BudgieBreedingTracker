import { useEffect, useCallback } from 'react';
import { useAuth } from './useAuth';
import { supabase } from '@/integrations/supabase/client';

export const useSessionSecurity = () => {
  const { user } = useAuth();
  
  const updateActivity = useCallback(() => {
    localStorage.setItem('lastActivity', Date.now().toString());
  }, []);
  
  const checkSessionTimeout = useCallback(() => {
    const lastActivity = localStorage.getItem('lastActivity');
    if (lastActivity) {
      const timeDiff = Date.now() - parseInt(lastActivity);
      const timeoutDuration = 30 * 60 * 1000; // 30 dakika
      
      if (timeDiff > timeoutDuration) {
        console.log('🕐 Session timeout - logging out user');
        supabase.auth.signOut();
        return true;
      }
    }
    return false;
  }, []);
  
  const resetSession = useCallback(() => {
    updateActivity();
  }, [updateActivity]);
  
  // Session timeout kontrolü
  useEffect(() => {
    if (user) {
      // İlk yüklemede aktivite kaydet
      updateActivity();
      
      // Her dakika session kontrolü
      const sessionCheck = setInterval(() => {
        checkSessionTimeout();
      }, 60000); // 60 saniye
      
      // Kullanıcı aktivitelerini dinle
      const handleUserActivity = () => {
        updateActivity();
      };
      
      // Event listener'ları ekle
      window.addEventListener('mousedown', handleUserActivity);
      window.addEventListener('keydown', handleUserActivity);
      window.addEventListener('touchstart', handleUserActivity);
      window.addEventListener('scroll', handleUserActivity);
      
      return () => {
        clearInterval(sessionCheck);
        window.removeEventListener('mousedown', handleUserActivity);
        window.removeEventListener('keydown', handleUserActivity);
        window.removeEventListener('touchstart', handleUserActivity);
        window.removeEventListener('scroll', handleUserActivity);
      };
    }
  }, [user, updateActivity, checkSessionTimeout]);
  
  // Sayfa görünürlük değişikliği kontrolü
  useEffect(() => {
    const handleVisibilityChange = () => {
      if (!document.hidden && user) {
        // Sayfa tekrar görünür olduğunda session kontrolü
        if (checkSessionTimeout()) {
          return; // Session timeout olduysa çık
        }
        updateActivity();
      }
    };
    
    document.addEventListener('visibilitychange', handleVisibilityChange);
    
    return () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange);
    };
  }, [user, checkSessionTimeout, updateActivity]);
  
  // Session bilgilerini getir
  const getSessionInfo = useCallback(() => {
    const lastActivity = localStorage.getItem('lastActivity');
    if (lastActivity) {
      const timeDiff = Date.now() - parseInt(lastActivity);
      const remainingTime = Math.max(0, (30 * 60 * 1000) - timeDiff);
      const remainingMinutes = Math.floor(remainingTime / (60 * 1000));
      
      return {
        lastActivity: new Date(parseInt(lastActivity)),
        remainingTime,
        remainingMinutes,
        isExpired: remainingTime <= 0
      };
    }
    
    return null;
  }, []);
  
  return {
    updateActivity,
    resetSession,
    checkSessionTimeout,
    getSessionInfo
  };
}; 