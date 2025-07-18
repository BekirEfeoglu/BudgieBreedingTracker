
import { useState, useRef, useCallback, useEffect } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';
import { transformBird } from '@/utils/birdTransforms';
import { Bird } from '@/types';
import { useBirdRealtime, setOptimisticUpdateTracker, isGlobalSubscriptionActive } from './useBirdRealtime';

export const useBirdData = () => {
  const [birds, setBirds] = useState<Bird[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const { user, session } = useAuth();
  const { toast } = useToast();
  
  // Track loading state to prevent multiple simultaneous requests
  const isLoadingRef = useRef(false);
  const realtimeInitializedRef = useRef(false);

  // Optimistic update tracker'ı ayarla
  useEffect(() => {
    setOptimisticUpdateTracker((birdId: string) => {
      console.log('🔄 Optimistic update tracked for bird:', birdId);
    });
  }, []);

  // Realtime subscription'ı sadece bir kez başlat
  useEffect(() => {
    if (user?.id && !realtimeInitializedRef.current && !isGlobalSubscriptionActive()) {
      console.log('🔄 Initializing bird realtime subscription');
      realtimeInitializedRef.current = true;
    }
  }, [user?.id]);

  // Realtime subscription'ı başlat (sadece bir kez)
  useBirdRealtime(setBirds);

  // Memoize loadBirds to prevent unnecessary re-renders
  const loadBirds = useCallback(async () => {
    if (!user || !session || isLoadingRef.current) {
      if (!user || !session) {
        console.log('🔄 useBirdData: No user or session, clearing birds data');
        setBirds([]);
        setLoading(false);
      }
      return;
    }

    // Token'ın geçerli olup olmadığını kontrol et
    if (session.expires_at) {
      const now = Math.floor(Date.now() / 1000);
      const isExpired = session.expires_at < now;
      
      if (isExpired) {
        console.log('🔄 useBirdData: Token expired, attempting refresh...');
        try {
          const { data: refreshData, error: refreshError } = await supabase.auth.refreshSession();
          if (refreshError || !refreshData.session) {
            console.log('❌ useBirdData: Token refresh failed, clearing data');
            setBirds([]);
            setLoading(false);
            return;
          }
          console.log('✅ useBirdData: Token refreshed successfully');
        } catch (error) {
          console.log('❌ useBirdData: Token refresh error:', error);
          setBirds([]);
          setLoading(false);
          return;
        }
      }
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
        sample: transformedBirds.slice(0, 2).map((b: any) => ({ id: b.id, name: b.name }))
      });
      
      // Mevcut optimistic update'leri koruyarak güncelle
      setBirds(prev => {
        // Optimistic update'ler ile veritabanı verilerini birleştir
        const optimisticBirds = prev.filter(bird => 
          !transformedBirds.some((dbBird: any) => dbBird.id === bird.id)
        );
        
        const allBirds = [...transformedBirds, ...optimisticBirds];
        console.log('🔄 useBirdData: Merged birds:', {
          dbCount: transformedBirds.length,
          optimisticCount: optimisticBirds.length,
          totalCount: allBirds.length
        });
        
        return allBirds;
      });
      
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
  }, [user, session, toast]);

  return {
    birds,
    setBirds,
    loading,
    error,
    loadBirds
  };
};
