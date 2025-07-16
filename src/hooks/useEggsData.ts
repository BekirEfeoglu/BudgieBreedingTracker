import { useState, useEffect } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';
import { Egg } from '@/types';

export const useEggsData = () => {
  const [eggs, setEggs] = useState<Egg[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const { user } = useAuth();
  const { toast } = useToast();

  // Transform database egg to application egg
  const transformEgg = (dbEgg: any): Egg => ({
    id: dbEgg.id,
    breedingId: dbEgg.incubation_id || dbEgg.clutch_id, // Use incubation_id first, fallback to clutch_id
    layDate: dbEgg.lay_date,
    status: dbEgg.status || 'laid',
    hatchDate: dbEgg.hatch_date,
    notes: dbEgg.notes,
    number: dbEgg.egg_number,
  });

  // Load eggs from Supabase
  const loadEggs = async () => {
    if (!user) {
      setLoading(false);
      return;
    }

    try {
      const { data, error } = await supabase
        .from('eggs')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false });

      if (error) {
        setError(error.message);
        toast({
          title: 'Veri Yükleme Hatası',
          description: 'Yumurta verileri yüklenirken bir hata oluştu.',
          variant: 'destructive'
        });
        return;
      }

      const transformedEggs = data ? data.map(transformEgg) : [];
      setEggs(transformedEggs);
      setError(null);

    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Bilinmeyen hata';
      setError(errorMessage);
      toast({
        title: 'Bağlantı Hatası',
        description: 'Yumurta verileri yüklenirken bir hata oluştu.',
        variant: 'destructive'
      });
    } finally {
      setLoading(false);
    }
  };

  // Load data on mount and when user changes
  useEffect(() => {
    setLoading(true);
    loadEggs();
  }, [user]);

  // Set up real-time subscription for eggs
  useEffect(() => {
    if (!user) return;
    
    const channel = supabase
      .channel(`eggs_changes_${user.id}_${Date.now()}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'eggs',
          filter: `user_id=eq.${user.id}`
        },
        (payload) => {
          const newEgg = transformEgg(payload.new);
          setEggs(prev => {
            const exists = prev.some(egg => egg.id === newEgg.id);
            if (exists) {
              return prev;
            }
            return [newEgg, ...prev];
          });
        }
      )
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'eggs',
          filter: `user_id=eq.${user.id}`
        },
        (payload) => {
          const updatedEgg = transformEgg(payload.new);
          setEggs(prev => {
            const updated = prev.map(egg => 
              egg.id === updatedEgg.id ? updatedEgg : egg
            );
            return updated;
          });
        }
      )
      .on(
        'postgres_changes',
        {
          event: 'DELETE',
          schema: 'public',
          table: 'eggs',
          filter: `user_id=eq.${user.id}`
        },
        (payload) => {
          setEggs(prev => {
            const filtered = prev.filter(egg => egg.id !== payload.old.id);
            return filtered;
          });
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [user]);

  return {
    eggs,
    setEggs,
    loading,
    error,
    refetch: loadEggs
  };
};
