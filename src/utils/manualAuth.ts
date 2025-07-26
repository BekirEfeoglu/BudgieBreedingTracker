import { supabase } from '@/integrations/supabase/client';

export const manualSignUp = async (email: string, password: string) => {
  try {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
    });

    if (error) {
      throw error;
    }

    return { success: true, data };
  } catch (error) {
    console.error('Manuel kayıt hatası:', error);
    return { success: false, error };
  }
};

export const manualSignIn = async (email: string, password: string) => {
  try {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) {
      throw error;
    }

    return { success: true, data };
  } catch (error) {
    console.error('Manuel giriş hatası:', error);
    return { success: false, error };
  }
};

export const manualSignOut = async () => {
  try {
    const { error } = await supabase.auth.signOut();
    
    if (error) {
      throw error;
    }

    return { success: true };
  } catch (error) {
    console.error('Manuel çıkış hatası:', error);
    return { success: false, error };
  }
}; 