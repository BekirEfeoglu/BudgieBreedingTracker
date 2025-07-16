import { useState, useEffect } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';
import { Breeding } from '@/types';

export const useClutchesData = () => {
  const [clutches, setClutches] = useState<Breeding[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const { user } = useAuth();
  const { toast } = useToast();

  // Transform database clutch to application breeding
  const transformClutch = (dbClutch: any): Breeding => ({
    id: dbClutch.id,
    maleBirdId: dbClutch.male_bird_id,
    femaleBirdId: dbClutch.female_bird_id,
    pairDate: dbClutch.pair_date,
    expectedHatchDate: dbClutch.expected_hatch_date,
    notes: dbClutch.notes,
    nestName: dbClutch.nest_name,
    eggs: [], // Will be populated from eggs table
    maleBird: '', // Will be populated from birds
    femaleBird: '', // Will be populated from birds
  });

  // Load clutches from Supabase
  const loadClutches = async () => {
    if (!user) {
      setLoading(false);
      return;
    }

    try {
      const { data, error } = await supabase
        .from('clutches')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false });

      if (error) {
        setError(error.message);
        toast({
          title: 'Veri Yükleme Hatası',
          description: 'Kuluçka verileri yüklenirken bir hata oluştu.',
          variant: 'destructive'
        });
        return;
      }

      const transformedClutches = data ? data.map(transformClutch) : [];
      setClutches(transformedClutches);
      setError(null);

    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Bilinmeyen hata';
      setError(errorMessage);
      toast({
        title: 'Bağlantı Hatası',
        description: 'Kuluçka verileri yüklenirken bir hata oluştu.',
        variant: 'destructive'
      });
    } finally {
      setLoading(false);
    }
  };

  // Load data on mount and when user changes
  useEffect(() => {
    setLoading(true);
    loadClutches();
  }, [user]);

  // Set up real-time subscription for clutches
  useEffect(() => {
    if (!user) return;
    
    const channel = supabase
      .channel('clutches_changes')
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'clutches',
          filter: `user_id=eq.${user.id}`
        },
        (payload) => {
          const newClutch = transformClutch(payload.new);
          setClutches(prev => {
            const exists = prev.some(clutch => clutch.id === newClutch.id);
            if (exists) return prev;
            return [newClutch, ...prev];
          });
        }
      )
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'clutches',
          filter: `user_id=eq.${user.id}`
        },
        (payload) => {
          const updatedClutch = transformClutch(payload.new);
          setClutches(prev => prev.map(clutch => 
            clutch.id === updatedClutch.id ? updatedClutch : clutch
          ));
        }
      )
      .on(
        'postgres_changes',
        {
          event: 'DELETE',
          schema: 'public',
          table: 'clutches',
          filter: `user_id=eq.${user.id}`
        },
        (payload) => {
          setClutches(prev => prev.filter(clutch => clutch.id !== payload.old.id));
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [user]);

  return {
    clutches,
    setClutches,
    loading,
    error,
    refetch: loadClutches
  };
};
