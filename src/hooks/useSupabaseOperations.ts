import { useAuth } from '@/hooks/useAuth';
import { useOfflineSync } from '@/hooks/useOfflineSync';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';

export const useSupabaseOperations = () => {
  const { user } = useAuth();
  const { addToQueue, isOnline } = useOfflineSync();
  const { toast } = useToast();

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

  const executeOperation = async (
    table: string,
    operation: 'insert' | 'update' | 'delete',
    data: any,
    showToast = true
  ) => {
    if (!user) {
      console.error('❌ User not authenticated for operation:', operation, table);
      if (showToast) {
        toast({
          title: 'Yetkilendirme Hatası',
          description: 'İşlem için giriş yapmalısınız.',
          variant: 'destructive'
        });
      }
      return { success: false, error: 'User not authenticated' };
    }

    // Transform data for database
    const transformedData = transformDataForDatabase(data, table);

    // Add user_id to data for insert/update operations
    if (operation === 'insert' || operation === 'update') {
      transformedData.user_id = user.id;
      
      // Validate user_id is not null
      if (!user.id) {
        console.error('❌ User ID is null for operation:', operation, table);
        if (showToast) {
          toast({
            title: 'Yetkilendirme Hatası',
            description: 'Kullanıcı kimliği bulunamadı. Lütfen yeniden giriş yapın.',
            variant: 'destructive'
          });
        }
        return { success: false, error: 'User ID is null' };
      }
    }

    console.log(`🔄 Attempting ${operation} on ${table}:`, {
      isOnline,
      data: { ...transformedData, user_id: transformedData.user_id ? '[PRESENT]' : '[MISSING]' }
    });

    try {
      if (isOnline) {
        let result;
        switch (operation) {
          case 'insert':
            console.log(`📤 Direct INSERT to ${table}`);
            result = await supabase.from(table as any).insert(transformedData).select();
            break;
          case 'update':
            console.log(`📤 Direct UPDATE to ${table} with ID: ${transformedData.id}`);
            result = await supabase.from(table as any).update(transformedData).eq('id', transformedData.id).select();
            break;
          case 'delete':
            console.log(`📤 Direct DELETE from ${table} with ID: ${transformedData.id}`);
            result = await supabase.from(table as any).delete().eq('id', transformedData.id);
            break;
        }

        if (result?.error) {
          console.error(`❌ Direct ${operation} failed:`, result.error);
          
          // Enhanced error handling with specific error types
          const errorMessage = result.error.message || 'Bilinmeyen veritabanı hatası';
          
          // Network/connectivity errors
          if (result.error.message?.includes('fetch') || result.error.message?.includes('network')) {
            if (showToast) {
              toast({
                title: 'Bağlantı Hatası',
                description: 'İnternet bağlantınızı kontrol edin ve tekrar deneyin.',
                variant: 'destructive'
              });
            }
            // Add to queue for retry
            addToQueue(table, operation, data);
            return { success: false, error: errorMessage, retryable: true };
          }
          
          // Permission errors
          if (result.error.code === 'PGRST301' || result.error.message.includes('permission') || result.error.code === '42501') {
            if (showToast) {
              toast({
                title: 'Yetki Hatası',
                description: 'Bu işlem için yetkiniz bulunmamaktadır.',
                variant: 'destructive'
              });
            }
            return { success: false, error: errorMessage, retryable: false };
          }
          
          // Validation errors
          if (result.error.code?.startsWith('23') || result.error.message.includes('violates')) {
            if (showToast) {
              toast({
                title: 'Veri Doğrulama Hatası',
                description: 'Girilen veriler geçerli değil. Lütfen kontrol edin.',
                variant: 'destructive'
              });
            }
            return { success: false, error: errorMessage, retryable: false };
          }
          
          // Server errors (5xx) - retryable
          if (result.error.code?.startsWith('5') || errorMessage.includes('server')) {
            if (showToast) {
              toast({
                title: 'Sunucu Hatası',
                description: 'Sunucuda geçici bir sorun var. İşleminiz kuyruğa eklendi.',
                variant: 'destructive'
              });
            }
            addToQueue(table, operation, data);
            return { success: false, error: errorMessage, retryable: true };
          }
          
          // Generic error handling
          console.log(`📤 Adding failed ${operation} to offline queue due to error`);
          addToQueue(table, operation, data);
          if (showToast) {
            toast({
              title: 'İşlem Kuyruğa Eklendi',
              description: 'İşlem şu anda gerçekleştirilemedi, kuyruğa eklendi.',
              variant: 'destructive'
            });
          }
          return { success: false, error: errorMessage, retryable: true };
        } else {
          console.log(`✅ Direct ${operation} successful on ${table}:`, result.data);
          return { success: true, data: result.data };
        }
      } else {
        console.log(`📤 Offline: Adding ${operation} to queue for ${table}`);
        // Offline: add to queue
        addToQueue(table, operation, transformedData);
        if (showToast) {
          toast({
            title: 'Çevrimdışı Mod',
            description: 'İşlem kuyruğa eklendi. Bağlantı sağlandığında otomatik olarak gönderilecek.',
          });
        }
        return { success: true, queued: true };
      }
    } catch (error) {
      console.error(`💥 Exception during ${operation} on ${table}:`, error);
      
      // Enhanced exception handling
      let errorMessage = 'Bilinmeyen hata';
      let isRetryable = true;
      
      if (error instanceof Error) {
        errorMessage = error.message;
        
        // Network errors
        if (error.message.includes('fetch') || error.message.includes('network') || error.name === 'NetworkError') {
          errorMessage = 'Ağ bağlantısı hatası';
          if (showToast) {
            toast({
              title: 'Bağlantı Sorunu',
              description: 'İnternet bağlantınızı kontrol edin.',
              variant: 'destructive'
            });
          }
        }
        // Timeout errors
        else if (error.message.includes('timeout') || error.name === 'TimeoutError') {
          errorMessage = 'İşlem zaman aşımına uğradı';
          if (showToast) {
            toast({
              title: 'Zaman Aşımı',
              description: 'İşlem çok uzun sürdü, tekrar denenecek.',
              variant: 'destructive'
            });
          }
        }
        // Validation errors
        else if (error.message.includes('validation') || error.message.includes('invalid')) {
          errorMessage = 'Veri doğrulama hatası';
          isRetryable = false;
          if (showToast) {
            toast({
              title: 'Geçersiz Veri',
              description: 'Girilen bilgileri kontrol edin.',
              variant: 'destructive'
            });
          }
        }
        // Generic error
        else {
          if (showToast) {
            toast({
              title: 'Hata',
              description: 'İşlem kuyruğa eklendi ve tekrar denenecek.',
              variant: 'destructive'
            });
          }
        }
      }
      
      // Add to queue if retryable
      if (isRetryable) {
        addToQueue(table, operation, transformedData);
      }
      
      return { success: false, error: errorMessage, retryable: isRetryable };
    }
  };

  const insertRecord = (table: string, data: any, showToast = true) => {
    // Reduced logging for performance
    return executeOperation(table, 'insert', data, showToast);
  };

  const updateRecord = (table: string, data: any, showToast = true) => {
    // Reduced logging for performance
    return executeOperation(table, 'update', data, showToast);
  };

  const deleteRecord = (table: string, id: string, showToast = true) => {
    // Reduced logging for performance
    return executeOperation(table, 'delete', { id }, showToast);
  };

  return {
    insertRecord,
    updateRecord,
    deleteRecord,
    isOnline
  };
};
