import React, { createContext, useContext, useEffect, useRef, useState } from 'react';
import { User, Session, AuthError } from '@supabase/supabase-js';
import { supabase } from '@/integrations/supabase/client';
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

  const fetchProfile = async (userId: string): Promise<void> => {
    if (profileFetchingRef.current) {
      return;
    }

    profileFetchingRef.current = true;
    
    try {
      
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
            return;
          }

          if (process.env.NODE_ENV === 'development') {
            console.log('✅ Yeni profil oluşturuldu:', newProfile);
          }
          setProfile(newProfile as Profile);
        } else {
          console.error('❌ Profil yükleme hatası:', error);
          return;
        }
      } else {
              // Reduced logging for performance
        
        // data bir array ise ilk elemanı al
        const profileData = Array.isArray(data) ? data[0] : data;
        
        // Reduced logging for performance
        
        if (process.env.NODE_ENV === 'development') {
          console.log('✅ Profile data loaded successfully', { profileExists: !!profileData });
        }
        setProfile(profileData as Profile);
      }
    } catch (error) {
      console.error('❌ Profil yükleme exception:', error);
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
    if (process.env.NODE_ENV === 'development') {
      console.log('🔄 Starting sign up process', { email });
    }
    
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
        console.error('❌ Sign up failed:', error);
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

      if (process.env.NODE_ENV === 'development') {
        console.log('✅ Sign up successful', { userId: data.user?.id });
      }
      return { error: null };
    } catch (error) {
      console.error('❌ Sign up exception:', error);
      return { error: error as AuthError };
    }
  };

  const signIn = async (email: string, password: string): Promise<{ error: AuthError | null }> => {
    if (process.env.NODE_ENV === 'development') {
      console.log('🔄 Starting sign in process', { email });
    }

    if (!validateEmail(email)) {
      return { error: { message: 'Geçerli bir e-posta adresi girin.' } as AuthError };
    }
    
    try {
      const { data, error } = await supabase.auth.signInWithPassword({
          email: email.toLowerCase().trim(),
        password: password
      });
      
      if (error) {
        console.error('❌ Sign in failed:', error);
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

      if (process.env.NODE_ENV === 'development') {
        console.log('✅ Sign in successful', { userId: data.user?.id });
      }
      return { error: null };
    } catch (error) {
      console.error('❌ Sign in exception:', error);
      return { error: error as AuthError };
    }
  };

  const signOut = async (): Promise<void> => {
    if (process.env.NODE_ENV === 'development') {
      console.log('🔄 Starting sign out process');
    }
    console.log('🔄 useAuth.signOut başlatılıyor');

    try {
      const { error } = await supabase.auth.signOut();
      
      if (error) {
        console.error('❌ Sign out failed:', error);
      } else {
        setUser(null);
        setSession(null);
        setProfile(null);
        
        if (process.env.NODE_ENV === 'development') {
          console.log('✅ Sign out successful');
        }
        
        // Çıkış yaptıktan sonra login sayfasına yönlendir
        if (typeof window !== 'undefined') {
          window.location.href = '/login';
        }
      }
    } catch (error) {
      console.error('❌ Sign out exception:', error);
    }
  };

  const resetPassword = async (email: string): Promise<{ error: AuthError | null }> => {
    if (process.env.NODE_ENV === 'development') {
      console.log('🔄 Starting password reset process', { email });
    }

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
      console.error('❌ Reset password failed:', error);
      return { error: error as AuthError };
    }
  };

  const updateProfile = async (updates: Partial<Profile>): Promise<{ error: AuthError | null }> => {
    if (!user) {
      return { error: { message: 'Kullanıcı oturumu bulunamadı' } as AuthError };
    }

    if (process.env.NODE_ENV === 'development') {
      console.log('🔄 Starting profile update', { userId: user.id, updates });
    }

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
      if (process.env.NODE_ENV === 'development') {
        console.log('🔄 Profil güncelleniyor...');
        console.log('🔄 Updating profile in Supabase', { sanitizedUpdates });
      }
      
      const { data, error } = await supabase
        .from('profiles')
        .update(sanitizedUpdates)
        .eq('id', user.id)
        .select('id, first_name, last_name, avatar_url, updated_at');

      if (process.env.NODE_ENV === 'development') {
        console.log('📊 Supabase güncelleme yanıtı:', { data, error });
        console.log('📊 Supabase response', { data, error });
      }

      if (error) {
        console.error('❌ Update profile failed:', error);
        return { error: { message: `Profil güncellenirken hata: ${error.message}` } as AuthError };
      }

      // Eğer data yoksa, mevcut profili güncelle
      if (!data || data.length === 0) {
        if (process.env.NODE_ENV === 'development') {
          console.log('⚠️ Veri döndürülmedi, local state güncelleniyor:', sanitizedUpdates);
        }
        
        // Local state'i güncelle
        setProfile((prev: Profile | null) => {
          if (!prev) return null;
          const updatedProfile = {
            ...prev,
            ...sanitizedUpdates,
            updated_at: new Date().toISOString()
          };
          if (process.env.NODE_ENV === 'development') {
            console.log('🔄 Local state güncellendi:', updatedProfile);
          }
          return updatedProfile;
        });
        
        return { error: null };
      }

      const updatedProfile = data[0] as Profile;
      if (process.env.NODE_ENV === 'development') {
        console.log('✅ Profil güncellendi ve yeni veri alındı:', updatedProfile);
      }

      // Update local state
      setProfile(updatedProfile);
      
      if (process.env.NODE_ENV === 'development') {
        console.log('✅ Profile updated successfully', { 
          updatedFields: Object.keys(sanitizedUpdates),
          newProfile: updatedProfile 
        });
      }
      
      return { error: null };
    } catch (error) {
      console.error('❌ Update profile failed:', error);
      return { error: { message: 'Profil güncellenirken beklenmeyen bir hata oluştu' } as AuthError };
    }
  };

  const updatePassword = async (newPassword: string, currentPassword: string): Promise<void> => {
    if (!user) {
      throw new Error('Kullanıcı oturumu bulunamadı');
    }

    try {
      if (process.env.NODE_ENV === 'development') {
        console.log('🔄 Şifre güncelleniyor...');
        console.log('🔄 Updating password');
      }
      
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
        console.error('❌ Error updating password:', error);
        throw new Error(error.message);
      }

      if (process.env.NODE_ENV === 'development') {
        console.log('✅ Şifre başarıyla güncellendi');
        console.log('✅ Password updated successfully');
      }
    } catch (error) {
      console.error('❌ Exception updating password:', error);
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
