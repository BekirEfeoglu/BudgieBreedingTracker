import React, { createContext, useContext, useEffect, useRef, useState } from 'react';
import { User, Session, AuthError } from '@supabase/supabase-js';
import { supabase } from '@/integrations/supabase/client';
import { useOptimizedLogging } from '@/hooks/useOptimizedLogging';
import { sanitizeText } from '@/utils/inputSanitization';

interface Profile {
  id: string;
  first_name: string | null;
  last_name: string | null;  
  full_name?: string | null;
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
  updatePassword: (newPassword: string, currentPassword: string) => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

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
  const initializationRef = useRef(false);
  const profileFetchingRef = useRef(false);
  const { debug, error: logError } = useOptimizedLogging();

  const fetchProfile = async (userId: string): Promise<void> => {
    if (profileFetchingRef.current) {
      debug('Profile fetch already in progress, skipping', { userId }, 'Auth');
      return;
    }

    profileFetchingRef.current = true;
    
    try {
          // Reduced logging for performance
      debug('Fetching profile for user', { userId }, 'Auth');
      
      const { data, error } = await supabase
        .from('profiles')
        .select('id, first_name, last_name, avatar_url, updated_at')
        .eq('id', userId)
        .single();

      // Reduced logging for performance

      if (error) {
        if (error.code === 'PGRST116') {
          if (process.env.NODE_ENV === 'development') {
            console.log('📝 Profil bulunamadı, yeni profil oluşturuluyor...');
          }
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
            console.error('❌ Profil oluşturma hatası:', createError);
            logError('Failed to create profile', createError, 'Auth');
            return;
          }

          if (process.env.NODE_ENV === 'development') {
            console.log('✅ Yeni profil oluşturuldu:', newProfile);
          }
          setProfile(newProfile as Profile);
        } else {
          console.error('❌ Profil yükleme hatası:', error);
          logError('Error fetching profile', error, 'Auth');
          return;
        }
      } else {
              // Reduced logging for performance
        
        // data bir array ise ilk elemanı al
        const profileData = Array.isArray(data) ? data[0] : data;
        
        // Reduced logging for performance
        
        debug('Profile data loaded successfully', { profileExists: !!profileData }, 'Auth');
        setProfile(profileData as Profile);
      }
    } catch (error) {
      console.error('❌ Profil yükleme exception:', error);
      logError('Exception fetching profile', error, 'Auth');
    } finally {
      profileFetchingRef.current = false;
    }
  };

  // Basit auth initialization
  useEffect(() => {
    if (initializationRef.current) {
      return;
    }
    
    initializationRef.current = true;
    if (process.env.NODE_ENV === 'development') {
      console.log('🚀 Auth initialization başlıyor...');
    }
    
    const initializeAuth = async () => {
      try {
        // Reduced logging for performance
        
        // Mevcut session'ı al
        const { data: { session }, error } = await supabase.auth.getSession();
        // Reduced logging for performance
        
        if (session) {
          // Reduced logging for performance
          setSession(session);
          setUser(session.user);
          
          // Profil yükle
          // Reduced logging for performance
          await fetchProfile(session.user.id);
        } else {
          if (process.env.NODE_ENV === 'development') {
            console.log('❌ Session bulunamadı');
          }
          setSession(null);
          setUser(null);
          setProfile(null);
        }
        
        setLoading(false);
      } catch (error) {
        console.error('💥 Auth initialization error:', error);
        setLoading(false);
      }
    };
    
    initializeAuth();

    // Auth state listener
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event: string, session: Session | null) => {
        // Reduced logging for performance
        
        if (event === 'INITIAL_SESSION') {
          return;
        }
        
        setSession(session);
        setUser(session?.user ?? null);
        
        if (session?.user) {
          // Reduced logging for performance
          fetchProfile(session.user.id);
        } else {
          if (process.env.NODE_ENV === 'development') {
            console.log('🔄 Auth state change: Profil temizleniyor...', { event });
          }
          setProfile(null);
        }
      }
    );

    return () => {
      subscription.unsubscribe();
      initializationRef.current = false;
    };
  }, []);

  const signUp = async (email: string, password: string, firstName?: string, lastName?: string): Promise<{ error: AuthError | null }> => {
    debug('Starting sign up process', { email }, 'Auth');
    console.log('🔄 useAuth.signUp başlatılıyor:', { email, firstName, lastName, passwordLength: password.length });
    
    if (!validateEmail(email)) {
      return { error: { message: 'Geçerli bir e-posta adresi girin.' } as AuthError };
    }

    try {
      const { data, error } = await supabase.auth.signUp({
            email: email.toLowerCase().trim(),
        password: password,
            options: {
              data: {
            first_name: firstName ? sanitizeText(firstName) : null,
            last_name: lastName ? sanitizeText(lastName) : null,
        }
      }
      });
      
      if (error) {
        logError('Sign up failed', error, 'Auth');
        return { error };
      }

      if (data.user) {
        setUser(data.user);
        setSession(data.session);
        
        // Create profile
        if (data.user.id) {
          await fetchProfile(data.user.id);
        }
      }

      debug('Sign up successful', { userId: data.user?.id }, 'Auth');
      return { error: null };
    } catch (error) {
      logError('Sign up exception', error, 'Auth');
      return { error: error as AuthError };
    }
  };

  const signIn = async (email: string, password: string): Promise<{ error: AuthError | null }> => {
    debug('Starting sign in process', { email }, 'Auth');
    console.log('🔄 useAuth.signIn başlatılıyor:', { email, passwordLength: password.length });

    if (!validateEmail(email)) {
      return { error: { message: 'Geçerli bir e-posta adresi girin.' } as AuthError };
    }
    
    try {
      const { data, error } = await supabase.auth.signInWithPassword({
          email: email.toLowerCase().trim(),
        password: password
      });
      
      if (error) {
        logError('Sign in failed', error, 'Auth');
        return { error };
      }

      if (data.user) {
        setUser(data.user);
        setSession(data.session);
        
        // Load profile
        if (data.user.id) {
          await fetchProfile(data.user.id);
        }
      }

      debug('Sign in successful', { userId: data.user?.id }, 'Auth');
      return { error: null };
    } catch (error) {
      logError('Sign in exception', error, 'Auth');
      return { error: error as AuthError };
    }
  };

  const signOut = async (): Promise<void> => {
    debug('Starting sign out process', undefined, 'Auth');
    console.log('🔄 useAuth.signOut başlatılıyor');

    try {
      const { error } = await supabase.auth.signOut();
      
      if (error) {
        logError('Sign out failed', error, 'Auth');
      } else {
      setUser(null);
      setSession(null);
      setProfile(null);
        debug('Sign out successful', undefined, 'Auth');
      }
    } catch (error) {
      logError('Sign out exception', error, 'Auth');
    }
  };

  const resetPassword = async (email: string): Promise<{ error: AuthError | null }> => {
    debug('Starting password reset process', { email }, 'Auth');
    console.log('🔄 useAuth.resetPassword başlatılıyor:', { email });

    if (!validateEmail(email)) {
      return { error: { message: 'Geçerli bir e-posta adresi girin.' } as AuthError };
    }

    try {
      const redirectUrl = 'https://www.budgiebreedingtracker.com/';
      
      const { error } = await supabase.auth.resetPasswordForEmail(email.toLowerCase().trim(), {
          redirectTo: redirectUrl,
      });
      
      return { error };
    } catch (error) {
      logError('Reset password failed', error, 'Auth');
      return { error: error as AuthError };
    }
  };

  const updateProfile = async (updates: Partial<Profile>): Promise<{ error: AuthError | null }> => {
    if (!user) {
      return { error: { message: 'Kullanıcı oturumu bulunamadı' } as AuthError };
    }

    debug('Starting profile update', { userId: user.id, updates }, 'Auth');

    // Sanitize input data
    const sanitizedUpdates: any = {
      ...updates,
    };

    // full_name'i first_name ve last_name olarak parçala
    if (updates.full_name) {
      const fullName = sanitizeText(updates.full_name);
      const parts = fullName.trim().split(' ');
      sanitizedUpdates.first_name = parts[0] || null;
      sanitizedUpdates.last_name = parts.slice(1).join(' ') || null;
      
      // full_name alanını kaldır
      delete sanitizedUpdates.full_name;
    }

    try {
      console.log('🔄 Profil güncelleniyor...', { sanitizedUpdates });
      debug('Updating profile in Supabase', { sanitizedUpdates }, 'Auth');
      
      const { data, error } = await supabase
        .from('profiles')
        .update(sanitizedUpdates)
        .eq('id', user.id)
        .select('id, first_name, last_name, avatar_url, updated_at');

      console.log('📊 Supabase güncelleme yanıtı:', { data, error });
      debug('Supabase response', { data, error }, 'Auth');

      if (error) {
        logError('Update profile failed', error, 'Auth');
        return { error: { message: `Profil güncellenirken hata: ${error.message}` } as AuthError };
      }

      // Eğer data yoksa, mevcut profili güncelle
      if (!data || data.length === 0) {
        console.log('⚠️ Veri döndürülmedi, local state güncelleniyor:', sanitizedUpdates);
        debug('No data returned, updating local state with sanitized updates', { sanitizedUpdates }, 'Auth');
        
        // Local state'i güncelle
        setProfile((prev: Profile | null) => {
          if (!prev) return null;
          const updatedProfile = {
            ...prev,
            ...sanitizedUpdates,
            updated_at: new Date().toISOString()
          };
          console.log('🔄 Local state güncellendi:', updatedProfile);
          return updatedProfile;
        });
        
        return { error: null };
      }

      const updatedProfile = data[0] as Profile;
      console.log('✅ Profil güncellendi ve yeni veri alındı:', updatedProfile);

      // Update local state
      setProfile(updatedProfile);
      
      debug('Profile updated successfully', { 
        updatedFields: Object.keys(sanitizedUpdates),
        newProfile: updatedProfile 
      }, 'Auth');
      
      return { error: null };
    } catch (error) {
      logError('Update profile failed', error, 'Auth');
      return { error: { message: 'Profil güncellenirken beklenmeyen bir hata oluştu' } as AuthError };
    }
  };

  const updatePassword = async (newPassword: string, currentPassword: string): Promise<void> => {
    if (!user) {
      throw new Error('Kullanıcı oturumu bulunamadı');
    }

    try {
      console.log('🔄 Şifre güncelleniyor...');
      debug('Updating password', {}, 'Auth');
      
      // Önce mevcut şifreyi doğrula
      const { error: signInError } = await supabase.auth.signInWithPassword({
        email: user.email || '',
        password: currentPassword
      });

      if (signInError) {
        throw new Error('Mevcut şifre yanlış');
      }

      // Şifreyi güncelle
      const { error } = await supabase.auth.updateUser({
        password: newPassword
      });

      if (error) {
        logError('Error updating password', error, 'Auth');
        throw new Error(error.message);
      }

      console.log('✅ Şifre başarıyla güncellendi');
      debug('Password updated successfully', {}, 'Auth');
    } catch (error) {
      logError('Exception updating password', error, 'Auth');
      throw error;
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
    updatePassword,
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};

// Helper functions
function validateEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}
