import { useAuth } from '@/hooks/useAuth';
import { useOfflineSync } from '@/hooks/useOfflineSync';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';

export const useSupabaseOperations = () => {
  const { user } = useAuth();
  const { addToQueue, isOnline } = useOfflineSync();
  const { toast } = useToast();

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

    // Add user_id to data for insert/update operations
    if (operation === 'insert' || operation === 'update') {
      data = { ...data, user_id: user.id };
    }

    console.log(`🔄 Attempting ${operation} on ${table}:`, {
      isOnline,
      data: { ...data, user_id: data.user_id ? '[PRESENT]' : '[MISSING]' }
    });

    try {
      if (isOnline) {
        let result;
        switch (operation) {
          case 'insert':
            console.log(`📤 Direct INSERT to ${table}`);
            result = await supabase.from(table as any).insert(data).select();
            break;
          case 'update':
            console.log(`📤 Direct UPDATE to ${table} with ID: ${data.id}`);
            result = await supabase.from(table as any).update(data).eq('id', data.id).select();
            break;
          case 'delete':
            console.log(`📤 Direct DELETE from ${table} with ID: ${data.id}`);
            result = await supabase.from(table as any).delete().eq('id', data.id);
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
        addToQueue(table, operation, data);
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
        addToQueue(table, operation, data);
      }
      
      return { success: false, error: errorMessage, retryable: isRetryable };
    }
  };

  const insertRecord = (table: string, data: any, showToast = true) => {
    console.log(`➕ Insert record request for ${table}:`, data);
    return executeOperation(table, 'insert', data, showToast);
  };

  const updateRecord = (table: string, data: any, showToast = true) => {
    console.log(`✏️ Update record request for ${table}:`, data);
    return executeOperation(table, 'update', data, showToast);
  };

  const deleteRecord = (table: string, id: string, showToast = true) => {
    console.log(`🗑️ Delete record request for ${table}, ID:`, id);
    return executeOperation(table, 'delete', { id }, showToast);
  };

  return {
    insertRecord,
    updateRecord,
    deleteRecord,
    isOnline
  };
};
