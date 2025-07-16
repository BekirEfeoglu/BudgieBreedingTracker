import { useState, useEffect, useRef } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';

export interface Incubation {
  id: string;
  name: string;
  pairId?: string;
  maleBirdId: string;
  femaleBirdId: string;
  startDate: string;
  eggCount?: number;
  enableNotifications?: boolean;
  notes?: string;
  createdAt: string | null;
  updatedAt: string | null;
}

export const useIncubationData = () => {
  const [incubations, setIncubations] = useState<Incubation[]>([]);
  const [loading, setLoading] = useState(true);
  const { user } = useAuth();
  const { toast } = useToast();
  const isSubscribedRef = useRef(false);

  const fetchIncubations = async () => {
    if (!user) return;

    try {
      setLoading(true);

      const { data, error } = await supabase
        .from('incubations')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false });

      if (error) {
        toast({
          title: 'Hata',
          description: 'Kuluçka verileri alınırken bir hata oluştu.',
          variant: 'destructive'
        });
        return;
      }

      // Convert database format to application format
      const convertedIncubations: Incubation[] = (data || []).map(item => ({
        id: item.id,
        name: item.name,
        maleBirdId: item.male_bird_id || '',
        femaleBirdId: item.female_bird_id || '',
        startDate: item.start_date,
        notes: item.notes || '',
        createdAt: item.created_at,
        updatedAt: item.updated_at
      }));

      setIncubations(convertedIncubations);

    } catch (error) {
      toast({
        title: 'Hata',
        description: 'Beklenmeyen bir hata oluştu.',
        variant: 'destructive'
      });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchIncubations();
  }, [user]);

  // Real-time subscription
  useEffect(() => {
    if (!user) return;

    // Prevent duplicate subscriptions
    if (isSubscribedRef.current) {
      return;
    }
    
    const channel = supabase
      .channel(`incubations_${user.id}_${Date.now()}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'incubations',
          filter: `user_id=eq.${user.id}`
        },
        (payload) => {
          fetchIncubations();
        }
      )
      .subscribe((status) => {
        if (status === 'SUBSCRIBED') {
          isSubscribedRef.current = true;
        } else if (status === 'CLOSED' || status === 'CHANNEL_ERROR') {
          isSubscribedRef.current = false;
        }
      });

    return () => {
      supabase.removeChannel(channel);
      isSubscribedRef.current = false;
    };
  }, [user]);

  return {
    incubations,
    setIncubations,
    loading,
    refetch: fetchIncubations
  };
};
