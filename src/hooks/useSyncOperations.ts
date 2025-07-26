import { useCallback } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/hooks/useAuth';

export const useSyncOperations = () => {
  const { user } = useAuth();

  const syncBirds = useCallback(async () => {
    if (!user) return { success: false, error: 'Kullanıcı girişi gerekli' };

    try {
      const { data, error } = await supabase
        .from('birds')
        .select('*')
        .eq('user_id', user.id);

      if (error) throw error;
      return { success: true, data };
    } catch (error) {
      console.error('Kuşlar senkronizasyon hatası:', error);
      return { success: false, error };
    }
  }, [user]);

  const syncChicks = useCallback(async () => {
    if (!user) return { success: false, error: 'Kullanıcı girişi gerekli' };

    try {
      const { data, error } = await supabase
        .from('chicks')
        .select('*')
        .eq('user_id', user.id);

      if (error) throw error;
      return { success: true, data };
    } catch (error) {
      console.error('Civcivler senkronizasyon hatası:', error);
      return { success: false, error };
    }
  }, [user]);

  const syncEggs = useCallback(async () => {
    if (!user) return { success: false, error: 'Kullanıcı girişi gerekli' };

    try {
      const { data, error } = await supabase
        .from('eggs')
        .select('*')
        .eq('user_id', user.id);

      if (error) throw error;
      return { success: true, data };
    } catch (error) {
      console.error('Yumurtalar senkronizasyon hatası:', error);
      return { success: false, error };
    }
  }, [user]);

  const syncClutches = useCallback(async () => {
    if (!user) return { success: false, error: 'Kullanıcı girişi gerekli' };

    try {
      const { data, error } = await supabase
        .from('clutches')
        .select('*')
        .eq('user_id', user.id);

      if (error) throw error;
      return { success: true, data };
    } catch (error) {
      console.error('Kuluçkalar senkronizasyon hatası:', error);
      return { success: false, error };
    }
  }, [user]);

    // Helper function to transform data for database
  const transformDataForDatabase = (data: any, table: string) => {
    const transformed = { ...data };
    
    // Transform field names for specific tables
    if (table === 'birds') {
      if (transformed.birthDate !== undefined) {
        transformed.birth_date = transformed.birthDate;
        delete transformed.birthDate;
      }
      if (transformed.ringNumber !== undefined) {
        transformed.ring_number = transformed.ringNumber;
        delete transformed.ringNumber;
      }
      if (transformed.healthNotes !== undefined) {
        transformed.health_notes = transformed.healthNotes;
        delete transformed.healthNotes;
      }
      if (transformed.photo !== undefined) {
        transformed.photo_url = transformed.photo;
        delete transformed.photo;
      }
      if (transformed.motherId !== undefined) {
        // Convert empty string to null for UUID fields
        transformed.mother_id = transformed.motherId === '' ? null : transformed.motherId;
        delete transformed.motherId;
      }
      if (transformed.fatherId !== undefined) {
        // Convert empty string to null for UUID fields
        transformed.father_id = transformed.fatherId === '' ? null : transformed.fatherId;
        delete transformed.fatherId;
      }
      
      // Clean up any empty string UUID fields
      if (transformed.mother_id === '') transformed.mother_id = null;
      if (transformed.father_id === '') transformed.father_id = null;
    }
    
    return transformed;
  };

  const processQueue = useCallback(async (queue: any[]) => {
    if (!user) {
      console.warn('Kullanıcı girişi olmadan kuyruk işlenemez');
      return { 
        success: false, 
        failedItems: queue, 
        processedCount: 0, 
        failedCount: queue.length 
      };
    }

    const failedItems: any[] = [];
    let processedCount = 0;
    
    for (const item of queue) {
      try {
        const { operation, table, data, recordId } = item;
        const id = recordId; // Use recordId field
        
        // Transform data for database
        const transformedData = transformDataForDatabase(data, table);
        
        switch (operation.toLowerCase()) {
          case 'insert':
            const { error: insertError } = await supabase
              .from(table)
              .insert({ ...transformedData, user_id: user.id });
            if (insertError) throw insertError;
            processedCount++;
            break;
            
          case 'update':
            if (!id) {
              console.warn('Update operation requires ID');
              failedItems.push(item);
              break;
            }
            const { error: updateError } = await supabase
              .from(table)
              .update(transformedData)
              .eq('id', id)
              .eq('user_id', user.id);
            if (updateError) throw updateError;
            processedCount++;
            break;
            
          case 'delete':
            if (!id) {
              console.warn('Delete operation requires ID');
              failedItems.push(item);
              break;
            }
            const { error: deleteError } = await supabase
              .from(table)
              .delete()
              .eq('id', id)
              .eq('user_id', user.id);
            if (deleteError) throw deleteError;
            processedCount++;
            break;
            
          default:
            console.warn('Bilinmeyen operasyon:', operation);
            failedItems.push(item);
        }
      } catch (error) {
        console.error('Kuyruk öğesi işlenirken hata:', error, item);
        failedItems.push(item);
      }
    }
    
    return { 
      success: failedItems.length === 0,
      failedItems, 
      processedCount, 
      failedCount: failedItems.length 
    };
  }, [user]);

  return {
    syncBirds,
    syncChicks,
    syncEggs,
    syncClutches,
    processQueue,
  };
}; 