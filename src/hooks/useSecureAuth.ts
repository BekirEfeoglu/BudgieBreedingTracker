import { useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { User } from '@supabase/supabase-js';

export const useSecureAuth = () => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Mevcut oturumu kontrol et
    const getSession = async () => {
      try {
        const { data: { session }, error } = await supabase.auth.getSession();
        if (error) {
          console.error('Oturum kontrolü hatası:', error);
        } else {
          setUser(session?.user ?? null);
        }
      } catch (error) {
        console.error('Oturum kontrolü hatası:', error);
      } finally {
        setLoading(false);
      }
    };

    getSession();

    // Auth state değişikliklerini dinle
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        setUser(session?.user ?? null);
        setLoading(false);
      }
    );

    return () => subscription.unsubscribe();
  }, []);

  const signOut = async () => {
    try {
      const { error } = await supabase.auth.signOut();
      if (error) {
        console.error('Çıkış hatası:', error);
        throw error;
      }
    } catch (error) {
      console.error('Çıkış hatası:', error);
      throw error;
    }
  };

  return {
    user,
    loading,
    signOut,
  };
}; 