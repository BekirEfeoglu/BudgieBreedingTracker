import React, { useState, useEffect, createContext, useContext, useRef } from 'react';
import { User, Session, AuthError } from '@supabase/supabase-js';
import { supabase } from '@/integrations/supabase/client';
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
  updateProfile: (updates: Partial<Profile>) => Promise<{ error: Error | null }>;
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
        .select('*')
        .eq('id', userId)
        .single();

      if (error && error.code !== 'PGRST116') {
        logError('Error fetching profile', error, 'Auth');
        return;
      }

      debug('Profile data loaded successfully', { profileExists: !!data }, 'Auth');
      setProfile(data as Profile | null);
    } catch (error) {
      logError('Exception fetching profile', error, 'Auth');
    } finally {
      profileFetchingRef.current = false;
    }
  };

  useEffect(() => {
    if (initializationRef.current) {
      debug('Auth already initialized, skipping', undefined, 'Auth');
      return;
    }
    
    initializationRef.current = true;
    debug('Initializing auth state listener', undefined, 'Auth');
    
    // Get initial session first
    supabase.auth.getSession().then(({ data: { session }, error }: { data: { session: Session | null }, error: AuthError | null }) => {
      if (error) {
        logError('Error getting initial session', error, 'Auth');
      }
      
      debug('Initial session loaded', { hasSession: !!session, userId: session?.user?.id }, 'Auth');
      console.log('🔐 Auth: Initial session check:', {
        hasSession: !!session,
        userId: session?.user?.id,
        userEmail: session?.user?.email,
        error: error?.message
      });
      
      setSession(session);
      setUser(session?.user ?? null);
      
      if (session?.user) {
        fetchProfile(session.user.id);
      }
      
      setLoading(false);
    });

    // Auth state listener
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

  const signUp = async (email: string, password: string, firstName?: string, lastName?: string): Promise<{ error: AuthError | null }> => {
    debug('Starting sign up process', { email }, 'Auth');
    
    // Rate limiting
    if (!rateLimitCheck('signup', 3, 60 * 60 * 1000)) {
      return { error: { message: 'Çok fazla kayıt denemesi. Lütfen 1 saat bekleyin.' } as AuthError };
    }

    // Input validation
    if (!validateEmail(email)) {
      return { error: { message: 'Geçerli bir e-posta adresi girin.' } as AuthError };
    }

    const passwordValidation = validatePassword(password);
    if (!passwordValidation.isValid) {
      return { error: { message: passwordValidation.errors[0] } as AuthError };
    }
    
    try {
      const redirectUrl = `${window.location.origin}/`;
      
      const { error } = await supabase.auth.signUp({
        email: email.toLowerCase().trim(),
        password,
        options: {
          emailRedirectTo: redirectUrl,
          data: {
            first_name: sanitizeText(firstName),
            last_name: sanitizeText(lastName),
          }
        }
      });
      
      if (error) {
        logError('Sign up failed', error, 'Auth');
      } else {
        debug('Sign up successful', { email }, 'Auth');
      }
      
      return { error };
    } catch (error) {
      logError('Sign up exception', error, 'Auth');
      return { error: error as AuthError };
    }
  };

  const signIn = async (email: string, password: string): Promise<{ error: AuthError | null }> => {
    debug('Starting sign in process', { email }, 'Auth');
    
    // Rate limiting
    if (!rateLimitCheck('login', 5, 15 * 60 * 1000)) {
      return { error: { message: 'Çok fazla giriş denemesi. Lütfen 15 dakika bekleyin.' } as AuthError };
    }

    // Input validation
    if (!validateEmail(email)) {
      return { error: { message: 'Geçerli bir e-posta adresi girin.' } as AuthError };
    }

    if (!password || password.length < 6) {
      return { error: { message: 'Şifre en az 6 karakter olmalıdır.' } as AuthError };
    }
    
    try {
      const { error } = await supabase.auth.signInWithPassword({
        email: email.toLowerCase().trim(),
        password,
      });
      
      if (error) {
        logError('Sign in failed', error, 'Auth');
      } else {
        debug('Sign in successful', { email }, 'Auth');
        // Clear rate limit on successful login
        localStorage.removeItem('rateLimit_login');
      }
      
      return { error };
    } catch (error) {
      logError('Sign in exception', error, 'Auth');
      return { error: error as AuthError };
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
    // Rate limiting
    if (!rateLimitCheck('reset', 3, 60 * 60 * 1000)) {
      return { error: { message: 'Çok fazla şifre sıfırlama denemesi. Lütfen 1 saat bekleyin.' } as AuthError };
    }

    if (!validateEmail(email)) {
      return { error: { message: 'Geçerli bir e-posta adresi girin.' } as AuthError };
    }

    try {
      const redirectUrl = `${window.location.origin}/`;
      const { error } = await supabase.auth.resetPasswordForEmail(email.toLowerCase().trim(), {
        redirectTo: redirectUrl,
      });
      return { error };
    } catch (error) {
      logError('Reset password failed', error, 'Auth');
      return { error: error as AuthError };
    }
  };

  const updateProfile = async (updates: Partial<Profile>): Promise<{ error: Error | null }> => {
    if (!user) return { error: 'No user found' };

    // Sanitize input data
    const sanitizedUpdates = {
      ...updates,
      first_name: updates.first_name ? sanitizeText(updates.first_name) : updates.first_name,
      last_name: updates.last_name ? sanitizeText(updates.last_name) : updates.last_name,
    };

    try {
      const { error } = await supabase
        .from('profiles')
        .update(sanitizedUpdates)
        .eq('id', user.id);

      if (!error) {
        setProfile((prev: Profile | null) => prev ? { ...prev, ...sanitizedUpdates } : null);
        debug('Profile updated successfully', { updates: Object.keys(sanitizedUpdates) }, 'Auth');
      }

      return { error };
    } catch (error) {
      logError('Update profile failed', error, 'Auth');
      return { error };
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
