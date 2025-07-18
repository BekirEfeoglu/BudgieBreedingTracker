import React, { useState, useEffect, createContext, useContext, useRef } from 'react';
import { User, Session, AuthError } from '@supabase/supabase-js';
import { supabase } from '@/integrations/supabase/client';
import { retryAuth } from '@/utils/simpleRetry';
import { manualSignUp, manualSignIn, manualResetPassword } from '@/utils/manualAuth';
import { rateLimitCheck, validateEmail, validatePassword, sanitizeText } from '@/utils/inputSanitization';
import { useOptimizedLogging } from '@/hooks/useOptimizedLogging';

interface Profile {
  id: string;
  first_name: string | null;
  last_name: string | null;  
  avatar_url: string | null;
  updated_at: string;
}

interface AuthContextType {
  user: User | null;
  session: Session | null;
  profile: Profile | null;
  loading: boolean;
  signUp: (email: string, password: string, firstName?: string, lastName?: string) => Promise<{ error: AuthError | null }>;
  signIn: (email: string, password: string) => Promise<{ error: AuthError | null }>;
  signOut: () => Promise<void>;
  resetPassword: (email: string) => Promise<{ error: AuthError | null }>;
  updateProfile: (updates: Partial<Profile>) => Promise<{ error: AuthError | null }>;
}

const AuthContext = createContext<AuthContextType | null>(null);

export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export const AuthProvider = ({ children }: { children: React.ReactNode }): React.ReactElement => {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(true);
  
  // Prevent multiple profile fetches
  const profileFetchingRef = useRef(false);
  const initializationRef = useRef(false);
  const { debug, error: logError } = useOptimizedLogging();

  const fetchProfile = async (userId: string): Promise<void> => {
    if (profileFetchingRef.current) {
      debug('Profile fetch already in progress, skipping', { userId }, 'Auth');
      return;
    }

    profileFetchingRef.current = true;
    
    try {
      debug('Fetching profile for user', { userId }, 'Auth');
      
      const { data, error } = await supabase
        .from('profiles')
        .select('id, first_name, last_name, avatar_url, updated_at')
        .eq('id', userId)
        .single();

      if (error) {
        if (error.code === 'PGRST116') {
          // Profile doesn't exist, create it
          const { data: newProfile, error: createError } = await supabase
            .from('profiles')
            .insert({
              id: userId,
              first_name: null,
              last_name: null,
              avatar_url: null
            })
            .select()
            .single();

          if (createError) {
            logError('Failed to create profile', createError, 'Auth');
            return;
          }

          setProfile(newProfile as Profile);
        } else {
          logError('Error fetching profile', error, 'Auth');
          return;
        }
      } else {
        debug('Profile data loaded successfully', { profileExists: !!data }, 'Auth');
        setProfile(data as Profile);
      }
    } catch (error) {
      logError('Exception fetching profile', error, 'Auth');
    } finally {
      profileFetchingRef.current = false;
    }
  };

  // Ana auth initialization useEffect
  useEffect(() => {
    if (initializationRef.current) {
      debug('Auth already initialized, skipping', undefined, 'Auth');
      return;
    }
    
    initializationRef.current = true;
    debug('Initializing auth state listener', undefined, 'Auth');
    
    // Get initial session first with token refresh
    const initializeAuth = async () => {
      try {
        // Önce mevcut session'ı al
        const { data: { session }, error } = await supabase.auth.getSession();
        
        if (error) {
          logError('Error getting initial session', error, 'Auth');
        }
        
        // Session varsa token'ın geçerli olup olmadığını kontrol et
        if (session && session.expires_at) {
          const now = Math.floor(Date.now() / 1000);
          const isExpired = session.expires_at < now;
          
          console.log('🔐 Auth: Token durumu:', {
            hasSession: !!session,
            userId: session?.user?.id,
            userEmail: session?.user?.email,
            isExpired,
            expiresAt: new Date(session.expires_at * 1000).toLocaleString()
          });
          
          // Token süresi dolmuşsa yenilemeyi dene
          if (isExpired) {
            console.log('🔄 Token süresi dolmuş, yenileniyor...');
            const { data: refreshData, error: refreshError } = await supabase.auth.refreshSession();
            
            if (refreshError) {
              console.log('❌ Token yenileme başarısız:', refreshError.message);
              // Token yenilenemezse session'ı temizle
              setSession(null);
              setUser(null);
              setProfile(null);
            } else if (refreshData.session) {
              console.log('✅ Token başarıyla yenilendi');
              setSession(refreshData.session);
              setUser(refreshData.session.user);
              fetchProfile(refreshData.session.user.id);
            }
          } else {
            // Token geçerli, normal devam et
            setSession(session);
            setUser(session.user);
            fetchProfile(session.user.id);
          }
        } else {
          console.log('🔐 Auth: Session yok');
          setSession(null);
          setUser(null);
          setProfile(null);
        }
        
        setLoading(false);
      } catch (error) {
        console.error('💥 Auth initialization error:', error);
        logError('Auth initialization failed', error, 'Auth');
        setLoading(false);
      }
    };
    
    initializeAuth();

    // Auth state listener with enhanced token handling
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event: string, session: Session | null) => {
        debug('Auth state changed', { event, hasUser: !!session?.user, userId: session?.user?.id }, 'Auth');
        console.log('🔐 Auth: State change event:', {
          event,
          hasUser: !!session?.user,
          userId: session?.user?.id,
          userEmail: session?.user?.email
        });
        
        // Only process non-initial events to avoid duplication
        if (event === 'INITIAL_SESSION') {
          return;
        }
        
        // Token refresh event'ini özel olarak işle
        if (event === 'TOKEN_REFRESHED') {
          console.log('🔄 Token yenilendi, session güncelleniyor...');
          setSession(session);
          setUser(session?.user ?? null);
          return;
        }
        
        // Token expired event'ini işle
        if (event === 'TOKEN_REFRESHED' || event === 'SIGNED_IN') {
          // Token yenilendiğinde veya giriş yapıldığında profile'ı yeniden yükle
          if (session?.user) {
            fetchProfile(session.user.id);
          }
        }
        
        setSession(session);
        setUser(session?.user ?? null);
        
        if (session?.user && event !== 'TOKEN_REFRESHED') {
          // Only fetch profile for sign-in events, not token refreshes
          fetchProfile(session.user.id);
        } else if (!session?.user) {
          setProfile(null);
        }
      }
    );

    return () => {
      debug('Cleaning up auth subscription', undefined, 'Auth');
      subscription.unsubscribe();
      initializationRef.current = false;
    };
  }, [debug, logError]);

  // Periyodik token kontrolü (her 5 dakikada bir)
  useEffect(() => {
    if (!user || !session) return;
    
    const tokenCheckInterval = setInterval(async () => {
      try {
        if (session.expires_at) {
          const now = Math.floor(Date.now() / 1000);
          const timeUntilExpiry = session.expires_at - now;
          
          // Token'ın 10 dakika içinde süresi dolacaksa yenile
          if (timeUntilExpiry < 600) {
            console.log('🔄 Token süresi yaklaşıyor, yenileniyor...');
            const { data, error } = await supabase.auth.refreshSession();
            
            if (error) {
              console.log('❌ Periyodik token yenileme hatası:', error.message);
            } else if (data.session) {
              console.log('✅ Periyodik token yenileme başarılı');
            }
          }
        }
      } catch (error) {
        console.log('❌ Periyodik token kontrolü hatası:', error);
      }
    }, 5 * 60 * 1000); // 5 dakika
    
    return () => clearInterval(tokenCheckInterval);
  }, [user, session]);

  const signUp = async (email: string, password: string, firstName?: string, lastName?: string): Promise<{ error: AuthError | null }> => {
    debug('Starting sign up process', { email }, 'Auth');
    console.log('🔄 useAuth.signUp başlatılıyor:', { email, firstName, lastName, passwordLength: password.length });
    
    // Rate limiting - GEÇİCİ OLARAK DEVRE DIŞI
    console.log('⚠️ Rate limiting geçici olarak devre dışı');
    /*
    if (!rateLimitCheck('signup', 10, 60 * 60 * 1000)) { // 10 attempts per hour (5'ten 10'a çıkarıldı)
      console.log('⏱️ Rate limit aşıldı');
      return { error: { message: 'Çok fazla kayıt denemesi. Lütfen 1 saat bekleyin veya farklı bir e-posta adresi deneyin.' } as AuthError };
    }
    */

    // Input validation
    if (!validateEmail(email)) {
      console.log('❌ E-posta geçersiz');
      return { error: { message: 'Geçerli bir e-posta adresi girin. Örnek: kullanici@email.com' } as AuthError };
    }

    const passwordValidation = validatePassword(password);
    if (!passwordValidation.isValid) {
      console.log('❌ Şifre geçersiz:', passwordValidation.errors);
      return { error: { message: passwordValidation.errors[0] } as AuthError };
    }
    
    console.log('✅ Girdi doğrulaması geçti');
    
    try {
      // Her zaman production URL'ini kullan
      const redirectUrl = 'https://www.budgiebreedingtracker.com/';
      
      console.log('🌐 Redirect URL:', redirectUrl);
      console.log('🏭 Environment: Production (forced)');
      
      console.log('📡 Supabase auth.signUp çağrılıyor...');
      
      let data: any = null;
      let error: any = null;
      
      // Önce normal Supabase auth'u dene
      try {
        const result = await retryAuth(
          () => supabase.auth.signUp({
            email: email.toLowerCase().trim(),
            password,
            options: {
              emailRedirectTo: redirectUrl,
              data: {
                first_name: sanitizeText(firstName),
                last_name: sanitizeText(lastName),
              }
            }
          }),
          'Kayıt İşlemi'
        );
        
        data = result.data;
        error = result.error;
      } catch (retryError) {
        console.warn('⚠️ Normal auth başarısız, manuel auth deneniyor...', retryError);
        
        // Normal auth başarısızsa manuel auth'u dene
        try {
          const result = await manualSignUp(
            email.toLowerCase().trim(),
            password,
            {
              first_name: sanitizeText(firstName),
              last_name: sanitizeText(lastName),
            }
          );
          
          console.log('✅ Manuel auth başarılı!');
          data = result.data;
          error = result.error;
        } catch (manualError) {
          console.error('❌ Manuel auth da başarısız:', manualError);
          error = manualError;
        }
      }
      
      console.log('📡 Supabase yanıtı:', { 
        hasData: !!data, 
        hasError: !!error, 
        userExists: !!data?.user,
        sessionExists: !!data?.session,
        errorMessage: error?.message 
      });
      
      if (error) {
        console.error('❌ Supabase kayıt hatası:', {
          message: error.message,
          status: error.status,
          name: error.name
        });
        logError('Sign up failed', error, 'Auth');
        return { error };
      } else {
        console.log('✅ Supabase kayıt başarılı');
        debug('Sign up successful', { email }, 'Auth');
        
        // E-posta onayı olmadan da oturum açmaya çalış - GEÇİCİ OLARAK DEVRE DIŞI
        if (data.user && !data.session) {
          console.log('🔐 E-posta onayı olmadan oturum açmaya çalışılıyor...');
          debug('Attempting to sign in without email confirmation', { email }, 'Auth');
          
          // Geçici olarak otomatik giriş denemesini devre dışı bırak
          console.log('⚠️ Otomatik giriş denemesi geçici olarak devre dışı');
          return { 
            error: { 
              message: 'Hesabınız oluşturuldu! E-posta onayı gerekli. E-posta kutunuzu kontrol edin veya spam klasörüne bakın.',
              name: 'EMAIL_CONFIRMATION_REQUIRED',
              status: 200 // Başarılı kayıt için 200 kodu
            } as AuthError 
          };
          
          /*
          const { error: signInError } = await supabase.auth.signInWithPassword({
            email: email.toLowerCase().trim(),
            password,
          });
          
          if (signInError) {
            console.log('❌ Otomatik giriş başarısız:', signInError.message);
            debug('Auto sign-in failed, email confirmation required', { error: signInError.message }, 'Auth');
            return { 
              error: { 
                message: 'Hesabınız oluşturuldu! E-posta onayı gerekli. E-posta kutunuzu kontrol edin veya spam klasörüne bakın.' 
              } as AuthError 
            };
          } else {
            console.log('✅ Otomatik giriş başarılı');
            debug('Auto sign-in successful', { email }, 'Auth');
            return { error: null };
          }
          */
        }
      }
      
      return { error: null };
    } catch (error) {
      console.error('💥 useAuth.signUp beklenmeyen hata:', error);
      logError('Sign up exception', error, 'Auth');
      return { error: error as AuthError };
    }
  };

  const signIn = async (email: string, password: string): Promise<{ error: AuthError | null }> => {
    debug('Starting sign in process', { email }, 'Auth');
    
    // Rate limiting - DEVRE DIŞI
    console.log('⚠️ Login rate limiting devre dışı');
    /*
    if (!rateLimitCheck('login', 5, 15 * 60 * 1000)) {
      return { error: { message: 'Çok fazla giriş denemesi. Lütfen 15 dakika bekleyin.' } as AuthError };
    }
    */

    // Input validation
    if (!validateEmail(email)) {
      return { error: { message: 'Geçerli bir e-posta adresi girin.' } as AuthError };
    }

    if (!password || password.length < 6) {
      return { error: { message: 'Şifre en az 6 karakter olmalıdır.' } as AuthError };
    }
    
    try {
      const { error } = await retryAuth(
        () => supabase.auth.signInWithPassword({
          email: email.toLowerCase().trim(),
          password,
        }),
        'Giriş İşlemi'
      );
      
      if (error) {
        logError('Sign in failed', error, 'Auth');
        
        // Kullanıcı dostu hata mesajları
        let userFriendlyMessage = error.message;
        
        if (error.message.includes('Invalid login credentials')) {
          userFriendlyMessage = 'E-posta adresi veya şifre yanlış. Lütfen bilgilerinizi kontrol edin.';
        } else if (error.message.includes('Email not confirmed')) {
          userFriendlyMessage = 'E-posta adresiniz henüz doğrulanmamış. Lütfen e-posta kutunuzu kontrol edin ve doğrulama bağlantısına tıklayın.';
        } else if (error.message.includes('Too many requests')) {
          userFriendlyMessage = 'Çok fazla giriş denemesi yaptınız. Lütfen 15 dakika bekleyin.';
        } else if (error.message.includes('User not found')) {
          userFriendlyMessage = 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı. Kayıt olmayı deneyin.';
        } else if (error.message.includes('Invalid email')) {
          userFriendlyMessage = 'Geçersiz e-posta adresi formatı. Lütfen doğru formatta girin.';
        }
        
        return { error: { message: userFriendlyMessage } as AuthError };
      } else {
        debug('Sign in successful', { email }, 'Auth');
        // Clear rate limit on successful login
        localStorage.removeItem('rateLimit_login');
      }
      
      return { error: null };
    } catch (error) {
      logError('Sign in exception', error, 'Auth');
      return { error: { message: 'Giriş yapılırken beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.' } as AuthError };
    }
  };

  const signOut = async (): Promise<void> => {
    debug('Starting sign out process', undefined, 'Auth');
    try {
      await supabase.auth.signOut();
      // Clear local state immediately
      setUser(null);
      setSession(null);
      setProfile(null);
      debug('Sign out completed', undefined, 'Auth');
    } catch (error) {
      logError('Error during sign out', error, 'Auth');
    }
  };

  const resetPassword = async (email: string): Promise<{ error: AuthError | null }> => {
    // Rate limiting - DEVRE DIŞI
    console.log('⚠️ Password reset rate limiting devre dışı');
    /*
    if (!rateLimitCheck('reset', 3, 60 * 60 * 1000)) {
      return { error: { message: 'Çok fazla şifre sıfırlama denemesi. Lütfen 1 saat bekleyin.' } as AuthError };
    }
    */

    if (!validateEmail(email)) {
      return { error: { message: 'Geçerli bir e-posta adresi girin.' } as AuthError };
    }

    try {
      // Her zaman production URL'ini kullan
      const redirectUrl = 'https://www.budgiebreedingtracker.com/';
      
      const { error } = await retryAuth(
        () => supabase.auth.resetPasswordForEmail(email.toLowerCase().trim(), {
          redirectTo: redirectUrl,
        }),
        'Şifre Sıfırlama'
      );
      return { error };
    } catch (error) {
      logError('Reset password failed', error, 'Auth');
      return { error: error as AuthError };
    }
  };

  const updateProfile = async (updates: Partial<Profile>): Promise<{ error: AuthError | null }> => {
    if (!user) {
      return { error: { message: 'No user found' } as AuthError };
    }

    // Sanitize input data
    const sanitizedUpdates: Partial<Profile> = {
      ...updates,
      first_name: updates.first_name ? sanitizeText(updates.first_name) : updates.first_name || null,
      last_name: updates.last_name ? sanitizeText(updates.last_name) : updates.last_name || null,
    };

    try {
      const { data, error } = await supabase
        .from('profiles')
        .update(sanitizedUpdates)
        .eq('id', user.id)
        .select();

      if (error) {
        logError('Update profile failed', error, 'Auth');
        return { error: { message: error.message } as AuthError };
      }

      // Update local state
      setProfile((prev: Profile | null) => prev ? { ...prev, ...sanitizedUpdates } : null);
      
      debug('Profile updated successfully', { updates: Object.keys(sanitizedUpdates) }, 'Auth');
      return { error: null };
    } catch (error) {
      logError('Update profile failed', error, 'Auth');
      return { error: error as AuthError };
    }
  };

  const value: AuthContextType = {
    user,
    session,
    profile,
    loading,
    signUp,
    signIn,
    signOut,
    resetPassword,
    updateProfile,
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};
