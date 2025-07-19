import { useState, useEffect } from 'react';
import { User, Session } from '@supabase/supabase-js';
import { supabase } from '@/integrations/supabase/client';
import { retryAuth } from '@/utils/simpleRetry';
import { toast } from '@/components/ui/use-toast';
import { rateLimitCheck, validateEmail, validatePassword, encryptLocalStorage, decryptLocalStorage } from '@/utils/inputSanitization';

interface AuthError {
  message: string;
  code?: string;
}

interface SecureAuthResult {
  user: User | null;
  session: Session | null;
  loading: boolean;
  signIn: (email: string, password: string) => Promise<{ error: AuthError | null }>;
  signUp: (email: string, password: string, firstName?: string, lastName?: string) => Promise<{ error: AuthError | null }>;
  signOut: () => Promise<void>;
  resetPassword: (email: string) => Promise<{ error: AuthError | null }>;
  updatePassword: (newPassword: string, currentPassword?: string) => Promise<{ error: AuthError | null }>;
  isAuthenticated: boolean;
}

export const useSecureAuth = (): SecureAuthResult => {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);

  // Supabase bağlantısını test et
  const testConnection = async () => {
    try {
      const { data, error } = await supabase.from('profiles').select('count').limit(1);
      if (error) {
        console.error('Supabase bağlantı hatası:', error);
        return false;
      }
      console.log('✅ Supabase bağlantısı başarılı');
      return true;
    } catch (error) {
      console.error('❌ Supabase bağlantı testi başarısız:', error);
      return false;
    }
  };

  const logSecurityEvent = async (eventType: string, metadata: any = {}) => {
    try {
      // Sadece kullanıcı oturum açmışsa güvenlik olaylarını kaydet
      if (!user?.id) {
        console.log('Security event skipped - no authenticated user:', eventType);
        return;
      }

      const userAgent = navigator.userAgent;
      const { error } = await supabase.from('security_events').insert({
        user_id: user.id,
        event_type: eventType,
        user_agent: userAgent,
        metadata: JSON.stringify(metadata),
        created_at: new Date().toISOString()
      });

      if (error) {
        console.warn('Security event logging failed:', error.message);
      }
    } catch (error: any) {
      console.warn('Failed to log security event:', error?.message || 'Unknown error');
    }
  };

  useEffect(() => {
    // Set up auth state listener
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (event, session) => {
        setSession(session);
        setUser(session?.user ?? null);
        setLoading(false);

        // Log auth events
        if (event === 'SIGNED_IN') {
          setTimeout(() => {
            logSecurityEvent('sign_in_success', { method: 'email' });
          }, 0);
        } else if (event === 'SIGNED_OUT') {
          setTimeout(() => {
            logSecurityEvent('sign_out', {});
          }, 0);
        }
      }
    );

    // Check for existing session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      setUser(session?.user ?? null);
      setLoading(false);
    });

    return () => subscription.unsubscribe();
  }, []);

  const signIn = async (email: string, password: string): Promise<{ error: AuthError | null }> => {
    // Rate limiting - DEVRE DIŞI
    console.log('⚠️ SecureAuth login rate limiting devre dışı');
    /*
    if (!rateLimitCheck('login', 5, 15 * 60 * 1000)) { // 5 attempts per 15 minutes
      await logSecurityEvent('rate_limit_exceeded', { action: 'sign_in', email });
      return { error: { message: 'Çok fazla giriş denemesi. Lütfen 15 dakika bekleyin.' } };
    }
    */

    // Input validation
    if (!validateEmail(email)) {
      return { error: { message: 'Geçerli bir e-posta adresi girin.' } };
    }

    if (!password || password.length < 6) {
      return { error: { message: 'Şifre en az 6 karakter olmalıdır.' } };
    }

    try {
      const { data, error } = await retryAuth(
        () => supabase.auth.signInWithPassword({
          email: email.toLowerCase().trim(),
          password,
        }),
        'Güvenli Giriş'
      );

      if (error) {
        const errorMessage = error.message || 'Unknown error';
        await logSecurityEvent('sign_in_failed', { email, error: errorMessage });
        return { error: { message: errorMessage, code: errorMessage } };
      }

      // Clear rate limit on successful login
      localStorage.removeItem('rateLimit_login');
      
      return { error: null };
    } catch (error: any) {
      const errorMessage = error?.message || 'Unknown error';
      await logSecurityEvent('sign_in_error', { email, error: errorMessage });
      return { error: { message: 'Giriş yapılırken bir hata oluştu.' } };
    }
  };

  const signUp = async (
    email: string, 
    password: string, 
    firstName?: string, 
    lastName?: string
  ): Promise<{ error: AuthError | null }> => {
    console.log('🔄 Kayıt işlemi başlatılıyor:', { 
      email: email.toLowerCase().trim(),
      passwordLength: password.length,
      firstName: firstName?.trim() || '',
      lastName: lastName?.trim() || ''
    });

    // Rate limiting - DEVRE DIŞI
    console.log('⚠️ SecureAuth signup rate limiting devre dışı');
    /*
    if (!rateLimitCheck('signup', 5, 60 * 60 * 1000)) { // 5 attempts per hour (3'ten 5'e çıkarıldı)
      console.warn('⚠️ Rate limit exceeded for signup');
      await logSecurityEvent('rate_limit_exceeded', { action: 'sign_up', email });
      return { error: { message: 'Çok fazla kayıt denemesi. Lütfen 1 saat bekleyin veya farklı bir e-posta adresi deneyin.' } };
    }
    */

    // Input validation
    if (!validateEmail(email)) {
      console.warn('⚠️ Invalid email format:', email);
      return { error: { message: 'Geçerli bir e-posta adresi girin. Örnek: kullanici@email.com' } };
    }

    const passwordValidation = validatePassword(password);
    if (!passwordValidation.isValid) {
      console.warn('⚠️ Password validation failed:', passwordValidation.errors);
      return { error: { message: passwordValidation.errors[0] || 'Şifre geçersiz' } };
    }

    try {
      console.log('🔄 Supabase auth.signUp çağrılıyor...');
      
      const { data, error } = await retryAuth(
        () => supabase.auth.signUp({
          email: email.toLowerCase().trim(),
          password,
          options: {
                          emailRedirectTo: 'https://www.budgiebreedingtracker.com/',
            data: {
              first_name: firstName?.trim() || '',
              last_name: lastName?.trim() || '',
            },
          },
        }),
        'Güvenli Kayıt'
      );

      if (error) {
        console.error('❌ Supabase kayıt hatası:', {
          message: error.message,
          status: error.status,
          name: error.name,
          stack: error.stack
        });
        
        await logSecurityEvent('sign_up_failed', { email, error: error.message });
        
        // Daha kullanıcı dostu hata mesajları
        let userFriendlyMessage = 'Kayıt işlemi başarısız oldu.';
        
        const errorMsg = error.message || '';
        const errorStatus = error.status || 0;
        
        console.log('🔍 Hata analizi:', { errorMsg, errorStatus });
        
        if (errorMsg.includes('already registered') || errorMsg.includes('already exists') || errorMsg.includes('User already registered')) {
          userFriendlyMessage = 'Bu e-posta adresi zaten kayıtlı. Giriş yapmayı deneyin veya "Şifremi unuttum" seçeneğini kullanın.';
        } else if (errorMsg.includes('invalid email') || errorMsg.includes('Invalid email')) {
          userFriendlyMessage = 'Geçersiz e-posta adresi formatı. Lütfen doğru formatta girin (örn: kullanici@email.com)';
        } else if (errorMsg.includes('weak password') || errorMsg.includes('Password should be at least')) {
          userFriendlyMessage = 'Şifre çok zayıf. En az 6 karakter ve 2 farklı karakter türü kullanın.';
        } else if (errorMsg.includes('network') || errorMsg.includes('fetch') || errorMsg.includes('Failed to fetch')) {
          userFriendlyMessage = 'İnternet bağlantısı sorunu. Lütfen bağlantınızı kontrol edin ve tekrar deneyin.';
        } else if (errorMsg.includes('timeout') || errorMsg.includes('time out')) {
          userFriendlyMessage = 'İşlem zaman aşımına uğradı. Lütfen tekrar deneyin.';
        } else if (errorMsg.includes('rate limit') || errorMsg.includes('too many requests')) {
          userFriendlyMessage = 'Çok fazla deneme. Lütfen 1 saat bekleyin.';
        } else if (errorStatus === 422) {
          userFriendlyMessage = 'Geçersiz veri formatı. Lütfen bilgilerinizi kontrol edin.';
        } else if (errorStatus === 429) {
          userFriendlyMessage = 'Çok fazla istek. Lütfen biraz bekleyin.';
        } else if (errorStatus >= 500) {
          userFriendlyMessage = 'Sunucu hatası. Lütfen daha sonra tekrar deneyin.';
        } else if (errorMsg.includes('Email not confirmed')) {
          userFriendlyMessage = 'E-posta adresiniz henüz doğrulanmamış. E-posta kutunuzu kontrol edin.';
        } else {
          userFriendlyMessage = `Kayıt hatası: ${errorMsg || 'Bilinmeyen hata'}`;
        }
        
        return { error: { message: userFriendlyMessage, code: error.message || 'unknown' } };
      }

      console.log('✅ Kayıt başarılı:', { 
        email, 
        userId: data.user?.id,
        emailConfirmed: data.user?.email_confirmed_at,
        session: !!data.session
      });
      
      await logSecurityEvent('sign_up_success', { email });
      return { error: null };
    } catch (error: any) {
      console.error('💥 Kayıt işleminde beklenmeyen hata:', {
        name: error.name,
        message: error.message,
        stack: error.stack,
        cause: error.cause
      });
      
      await logSecurityEvent('sign_up_error', { email, error: error.message || 'Unknown error' });
      
      let userFriendlyMessage = 'Hesap oluşturulurken beklenmeyen bir hata oluştu.';
      
      const errorMsg = error.message || '';
      const errorName = error.name || '';
      
      if (errorMsg.includes('network') || errorName === 'NetworkError' || errorMsg.includes('fetch')) {
        userFriendlyMessage = 'İnternet bağlantısı sorunu. Lütfen bağlantınızı kontrol edin ve tekrar deneyin.';
      } else if (errorMsg.includes('timeout') || errorName === 'TimeoutError') {
        userFriendlyMessage = 'İşlem zaman aşımına uğradı. Lütfen tekrar deneyin.';
      } else if (errorMsg.includes('CORS') || errorMsg.includes('cross-origin')) {
        userFriendlyMessage = 'Tarayıcı güvenlik hatası. Lütfen sayfayı yenileyin.';
      } else if (errorMsg) {
        userFriendlyMessage = `Teknik hata: ${errorMsg}`;
      }
      
      return { error: { message: userFriendlyMessage } };
    }
  };

  const signOut = async (): Promise<void> => {
    try {
      await logSecurityEvent('sign_out_initiated', {});
      
      // Clear sensitive data from localStorage
      const keysToRemove = [];
      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        if (key && (key.includes('rate') || key.includes('settings'))) {
          keysToRemove.push(key);
        }
      }
      keysToRemove.forEach(key => localStorage.removeItem(key));

      await supabase.auth.signOut();
    } catch (error) {
      console.error('Sign out error:', error);
    }
  };

  const resetPassword = async (email: string): Promise<{ error: AuthError | null }> => {
    // Rate limiting - DEVRE DIŞI
    console.log('⚠️ SecureAuth password reset rate limiting devre dışı');
    /*
    if (!rateLimitCheck('reset', 3, 60 * 60 * 1000)) { // 3 attempts per hour
      await logSecurityEvent('rate_limit_exceeded', { action: 'password_reset', email });
      return { error: { message: 'Çok fazla şifre sıfırlama denemesi. Lütfen 1 saat bekleyin.' } };
    }
    */

    if (!validateEmail(email)) {
      return { error: { message: 'Geçerli bir e-posta adresi girin.' } };
    }

    try {
      const { error } = await retryAuth(
        () => supabase.auth.resetPasswordForEmail(
          email.toLowerCase().trim(),
          {
            redirectTo: 'https://www.budgiebreedingtracker.com/',
          }
        ),
        'Güvenli Şifre Sıfırlama'
      );

      if (error) {
        await logSecurityEvent('password_reset_failed', { email, error: error.message });
        return { error: { message: error.message } };
      }

      await logSecurityEvent('password_reset_requested', { email });
      return { error: null };
    } catch (error: any) {
      await logSecurityEvent('password_reset_error', { email, error: error.message });
      return { error: { message: 'Şifre sıfırlama e-postası gönderilirken hata oluştu.' } };
    }
  };

  const updatePassword = async (
    newPassword: string, 
    currentPassword?: string
  ): Promise<{ error: AuthError | null }> => {
    if (!user) {
      return { error: { message: 'Oturum açmanız gerekiyor.' } };
    }

    const passwordValidation = validatePassword(newPassword);
    if (!passwordValidation.isValid) {
      return { error: { message: passwordValidation.errors[0] || 'Şifre geçersiz' } };
    }

    try {
      const { error } = await retryAuth(
        () => supabase.auth.updateUser({
          password: newPassword
        }),
        'Güvenli Şifre Güncelleme'
      );

      if (error) {
        const errorMessage = error.message || 'Unknown error';
        await logSecurityEvent('password_update_failed', { error: errorMessage });
        return { error: { message: errorMessage } };
      }

      await logSecurityEvent('password_updated', {});
      
      toast({
        title: 'Başarılı',
        description: 'Şifreniz güncellendi.',
      });

      return { error: null };
    } catch (error: any) {
      await logSecurityEvent('password_update_error', { error: error.message });
      return { error: { message: 'Şifre güncellenirken hata oluştu.' } };
    }
  };

  return {
    user,
    session,
    loading,
    signIn,
    signUp,
    signOut,
    resetPassword,
    updatePassword,
    isAuthenticated: !!user,
  };
};