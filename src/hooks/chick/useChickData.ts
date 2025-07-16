import { useState, useEffect } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';
import { Chick } from '@/types';
import { transformChick } from '@/utils/chickTransforms';

export const useChickData = () => {
  const [chicks, setChicks] = useState<Chick[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const { user } = useAuth();
  const { toast } = useToast();

  // Load chicks from Supabase
  const loadChicks = async () => {
    if (!user) {
      setChicks([]);
      setLoading(false);
      return;
    }

    try {
      const { data, error } = await supabase
        .from('chicks')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false });

      if (error) {
        setError(error.message);
        const errorMessage = error.message.includes('permission')
          ? 'Yavru verilerine erişim izni yok. Lütfen yeniden giriş yapın.'
          : 'Yavru verileri yüklenirken bir hata oluştu.';
        
        toast({
          title: 'Veri Yükleme Hatası',
          description: errorMessage,
          variant: 'destructive'
        });
        return;
      }

      const transformedChicks = data ? data.map(transformChick) : [];
      setChicks(transformedChicks);
      setError(null);

    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Bilinmeyen hata';
      setError(errorMessage);
      toast({
        title: 'Bağlantı Hatası',
        description: 'Internet bağlantınızı kontrol edin ve tekrar deneyin.',
        variant: 'destructive'
      });
    } finally {
      setLoading(false);
    }
  };

  // Load data on mount and when user changes
  useEffect(() => {
    loadChicks();
  }, [user, loadChicks]);

  // Manual refresh function
  const refreshChicks = async () => {
    setLoading(true);
    await loadChicks();
  };

  return {
    chicks,
    setChicks,
    loading,
    error,
    refetch: loadChicks,
    refreshChicks
  };
};
