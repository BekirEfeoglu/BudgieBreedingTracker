
import { useState, useEffect } from 'react';
import { useToast } from '@/hooks/use-toast';

export const useNetworkStatus = () => {
  const [isOnline, setIsOnline] = useState(navigator.onLine);
  const { toast } = useToast();

  useEffect(() => {
    const handleOnline = () => {
      setIsOnline(true);
      // Reduced logging for performance
      toast({
        title: 'Bağlantı Sağlandı',
        description: 'İnternet bağlantısı yeniden kuruldu. Veriler senkronize ediliyor...',
      });
    };

    const handleOffline = () => {
      setIsOnline(false);
      // Reduced logging for performance
      toast({
        title: 'Bağlantı Kesildi',
        description: 'Çevrimdışı modda çalışıyorsunuz. Veriler yerel olarak saklanacak.',
        variant: 'destructive'
      });
    };

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, [toast]);

  return { isOnline };
};
