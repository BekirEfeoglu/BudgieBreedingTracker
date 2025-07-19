import { useAuth } from '@/hooks/useAuth';
import { supabase } from '@/integrations/supabase/client';
import { useCallback } from 'react';

export const useAuthMiddleware = () => {
  const { session, user } = useAuth();

  // API çağrısından önce auth durumunu kontrol et
  const ensureAuthenticated = useCallback(async () => {
    if (!user || !session) {
      console.log('❌ Auth middleware: Kullanıcı oturum açmamış');
      throw new Error('Oturum açmanız gerekiyor');
    }

    // Token'ın geçerli olup olmadığını kontrol et
    if (session.expires_at) {
      const now = Math.floor(Date.now() / 1000);
      const isExpired = session.expires_at < now;
      
      if (isExpired) {
        console.log('🔄 Auth middleware: Token süresi dolmuş, yenileniyor...');
        
        try {
          const { data, error } = await supabase.auth.refreshSession();
          
          if (error) {
            console.log('❌ Auth middleware: Token yenileme başarısız:', error.message);
            throw new Error('Oturum süresi dolmuş. Lütfen yeniden giriş yapın.');
          }
          
          if (!data.session) {
            console.log('❌ Auth middleware: Token yenilendi ama session yok');
            throw new Error('Oturum geçersiz. Lütfen yeniden giriş yapın.');
          }
          
          console.log('✅ Auth middleware: Token başarıyla yenilendi');
          return data.session;
        } catch (error) {
          console.error('💥 Auth middleware: Token yenileme hatası:', error);
          throw new Error('Oturum hatası. Lütfen yeniden giriş yapın.');
        }
      }
    }

    return session;
  }, [user, session]);

  // Güvenli API çağrısı wrapper'ı
  const secureApiCall = useCallback(async <T>(
    apiCall: () => Promise<T>
  ): Promise<T> => {
    try {
      // Önce auth durumunu kontrol et
      await ensureAuthenticated();
      
      // API çağrısını yap
      return await apiCall();
    } catch (error) {
      console.error('❌ Secure API call failed:', error);
      throw error;
    }
  }, [ensureAuthenticated]);

  // Auth durumunu kontrol et
  const checkAuthStatus = useCallback(() => {
    if (!user || !session) {
      return { isAuthenticated: false, reason: 'No user or session' };
    }

    if (session.expires_at) {
      const now = Math.floor(Date.now() / 1000);
      const isExpired = session.expires_at < now;
      
      if (isExpired) {
        return { isAuthenticated: false, reason: 'Token expired' };
      }
    }

    return { isAuthenticated: true, reason: 'Valid session' };
  }, [user, session]);

  return {
    ensureAuthenticated,
    secureApiCall,
    checkAuthStatus,
    isAuthenticated: !!user && !!session
  };
}; 