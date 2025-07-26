import React from 'react';
import { supabase } from '@/integrations/supabase/client';
import { Button } from '@/components/ui/button';
import { useToast } from '@/hooks/use-toast';

const EmergencyTestPage: React.FC = () => {
  const { toast } = useToast();

  const testConnection = async () => {
    try {
      const { data, error } = await supabase.from('birds').select('count').limit(1);
      
      if (error) {
        toast({
          title: 'Bağlantı Hatası',
          description: error.message,
          variant: 'destructive',
        });
      } else {
        toast({
          title: 'Bağlantı Başarılı',
          description: 'Veritabanı bağlantısı çalışıyor.',
        });
      }
    } catch (error) {
      toast({
        title: 'Hata',
        description: 'Beklenmeyen bir hata oluştu.',
        variant: 'destructive',
      });
    }
  };

  return (
    <div className="container mx-auto p-4 space-y-4">
      <h1 className="text-2xl font-bold">Acil Durum Test Sayfası</h1>
      <Button onClick={testConnection}>
        Veritabanı Bağlantısını Test Et
      </Button>
    </div>
  );
};

export default EmergencyTestPage; 