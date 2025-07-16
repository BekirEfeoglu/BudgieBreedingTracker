
import { useState, useRef, useCallback } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';
import { transformBird } from '@/utils/birdTransforms';
import { Bird } from '@/types';

export const useBirdData = () => {
  const [birds, setBirds] = useState<Bird[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const { user } = useAuth();
  const { toast } = useToast();
  
  // Track loading state to prevent multiple simultaneous requests
  const isLoadingRef = useRef(false);

  // Memoize loadBirds to prevent unnecessary re-renders
  const loadBirds = useCallback(async () => {
    if (!user || isLoadingRef.current) {
      if (!user) {
        console.log('🔄 useBirdData: No user, clearing birds data');
        setBirds([]);
        setLoading(false);
      }
      return;
    }

    isLoadingRef.current = true;
    
    try {
      console.log('🔄 useBirdData: Loading birds for user:', user.id);
      setError(null);
      
      const { data, error } = await supabase
        .from('birds')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false });

      if (error) {
        console.error('❌ useBirdData: Supabase error:', error);
        setError(error.message);
        
        const errorMessage = error.message.includes('permission') 
          ? 'Kuş verilerine erişim izni yok. Lütfen yeniden giriş yapın.'
          : `Kuş verileri yüklenirken hata: ${error.message}`;
        
        toast({
          title: 'Veri Yükleme Hatası',
          description: errorMessage,
          variant: 'destructive'
        });
        return;
      }
      
      const transformedBirds = data ? data.map(transformBird) : [];
      console.log('✅ useBirdData: Successfully loaded birds:', {
        count: transformedBirds.length,
        sample: transformedBirds.slice(0, 2).map(b => ({ id: b.id, name: b.name }))
      });
      
      setBirds(transformedBirds);
      setError(null);

    } catch (err) {
      console.error('💥 useBirdData: Exception loading birds:', err);
      const errorMessage = err instanceof Error ? err.message : 'Bilinmeyen hata';
      setError(errorMessage);
      toast({
        title: 'Bağlantı Hatası',
        description: 'Internet bağlantınızı kontrol edin ve tekrar deneyin.',
        variant: 'destructive'
      });
    } finally {
      setLoading(false);
      isLoadingRef.current = false;
    }
  }, [user, toast]);

  return {
    birds,
    setBirds,
    loading,
    error,
    loadBirds
  };
};
