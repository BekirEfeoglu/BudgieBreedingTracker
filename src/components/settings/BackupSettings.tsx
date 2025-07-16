import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { toast } from '@/hooks/use-toast';
import { useLanguage } from '@/contexts/LanguageContext';
import { useAuth } from '@/hooks/useAuth';
import { supabase } from '@/integrations/supabase/client';
import { Download, Loader2, Upload } from 'lucide-react';

const BackupSettings = () => {
  const { user } = useAuth();
  const [isBackingUp, setIsBackingUp] = useState(false);
  const [isRestoring, setIsRestoring] = useState(false);

  const exportData = async () => {
    if (!user) {
      toast({
        title: 'Hata',
        description: 'Giriş yapmalısınız.',
        variant: 'destructive'
      });
      return;
    }

    setIsBackingUp(true);
    
    try {
      console.log('🔄 Starting data backup for user:', user.id);

      // Fetch all user data
      const [birdsResponse, clutchesResponse, eggsResponse, chicksResponse, calendarResponse, incubationsResponse] = await Promise.all([
        supabase.from('birds').select('*').eq('user_id', user.id),
        supabase.from('clutches').select('*').eq('user_id', user.id),
        supabase.from('eggs').select('*').eq('user_id', user.id),
        supabase.from('chicks').select('*').eq('user_id', user.id),
        supabase.from('calendar').select('*').eq('user_id', user.id),
        supabase.from('incubations').select('*').eq('user_id', user.id)
      ]);

      // Check for errors
      const responses = [birdsResponse, clutchesResponse, eggsResponse, chicksResponse, calendarResponse, incubationsResponse];
      const hasError = responses.some(response => response.error);
      
      if (hasError) {
        const errorMessages = responses
          .filter(response => response.error)
          .map(response => response.error?.message)
          .join(', ');
        
        console.error('❌ Backup failed:', errorMessages);
        throw new Error(`Veri çekme hatası: ${errorMessages}`);
      }

      // Prepare backup data
      const backupData = {
        exportDate: new Date().toISOString(),
        userId: user.id,
        userEmail: user.email,
        version: '1.0',
        data: {
          birds: birdsResponse.data || [],
          clutches: clutchesResponse.data || [],
          eggs: eggsResponse.data || [],
          chicks: chicksResponse.data || [],
          calendar: calendarResponse.data || [],
          incubations: incubationsResponse.data || []
        },
        summary: {
          totalBirds: birdsResponse.data?.length || 0,
          totalClutches: clutchesResponse.data?.length || 0,
          totalEggs: eggsResponse.data?.length || 0,
          totalChicks: chicksResponse.data?.length || 0,
          totalCalendarEvents: calendarResponse.data?.length || 0,
          totalIncubations: incubationsResponse.data?.length || 0
        }
      };

      // Create and download file
      const dataStr = JSON.stringify(backupData, null, 2);
      const dataBlob = new Blob([dataStr], { type: 'application/json' });
      
      const url = URL.createObjectURL(dataBlob);
      const link = document.createElement('a');
      link.href = url;
      
      // Generate filename with timestamp
      const timestamp = new Date().toISOString().slice(0, 19).replace(/:/g, '-');
      link.download = `budgie-yedek-${timestamp}.json`;
      
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      URL.revokeObjectURL(url);

      console.log('✅ Backup completed successfully:', backupData.summary);

      toast({
        title: 'Yedekleme Tamamlandı',
        description: `${Object.values(backupData.summary).reduce((a, b) => a + b, 0)} kayıt başarıyla yedeklendi.`,
      });

    } catch (error) {
      console.error('💥 Backup failed:', error);
      
      toast({
        title: 'Yedekleme Hatası',
        description: error instanceof Error ? error.message : 'Beklenmedik bir hata oluştu.',
        variant: 'destructive'
      });
    } finally {
      setIsBackingUp(false);
    }
  };

  // Geri yükleme fonksiyonu
  const handleRestore = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;
    if (!user) {
      toast({ title: 'Hata', description: 'Giriş yapmalısınız.', variant: 'destructive' });
      return;
    }
    setIsRestoring(true);
    try {
      const text = await file.text();
      const backup = JSON.parse(text);
      if (!backup.data) throw new Error('Geçersiz yedek dosyası.');
      // Her tablo için upsert işlemi
      const tables = ['birds', 'clutches', 'eggs', 'chicks', 'calendar', 'incubations'];
      for (const table of tables) {
        if (Array.isArray(backup.data[table]) && backup.data[table].length > 0) {
          // user_id alanını güncelle
          const records = backup.data[table].map((rec: Record<string, unknown>) => ({ ...rec, user_id: user.id }));
          const { error } = await (supabase as any).from(table as any).upsert(records, { onConflict: 'id' });
          if (error) throw new Error(`${table} tablosu yüklenirken hata: ${error.message}`);
        }
      }
      toast({ title: 'Geri Yükleme Başarılı', description: 'Verileriniz başarıyla geri yüklendi.' });
    } catch (error) {
      toast({ title: 'Geri Yükleme Hatası', description: error instanceof Error ? error.message : 'Beklenmedik bir hata oluştu.', variant: 'destructive' });
    } finally {
      setIsRestoring(false);
    }
  };

  return (
    <Card className="budgie-card shadow-sm">
      <CardHeader className="pb-4">
        <CardTitle className="flex items-center gap-2 text-lg">
          <Download className="w-5 h-5" />
          Yedekleme
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <Button 
          variant="outline" 
          className="w-full justify-start min-h-[48px] text-base touch-manipulation" 
          onClick={exportData}
          disabled={isBackingUp}
        >
          {isBackingUp ? (
            <Loader2 className="w-5 h-5 mr-3 animate-spin" />
          ) : (
            <Download className="w-5 h-5 mr-3" />
          )}
          {isBackingUp ? 'Yedekleniyor...' : 'Verileri Yedekle'}
        </Button>
        {/* Geri Yükleme Alanı */}
        <label className="w-full flex flex-col items-start gap-2 cursor-pointer">
          <span className="flex items-center gap-2 text-base font-medium"><Upload className="w-5 h-5" /> Yedekten Geri Yükle</span>
          <input type="file" accept="application/json" className="hidden" onChange={handleRestore} disabled={isRestoring} />
          <span className="text-xs text-muted-foreground">Yedek dosyanızı seçin ve verilerinizi geri yükleyin</span>
          {isRestoring && <Loader2 className="w-4 h-4 animate-spin ml-2" />}
        </label>
        
        <div className="text-sm text-muted-foreground bg-muted/30 p-3 rounded-lg space-y-2">
          <p className="font-medium">Yedekleme hakkında:</p>
          <ul className="space-y-1 text-xs">
            <li>• Tüm kuş, yumurta, yavru ve takvim verileriniz JSON formatında yedeklenir</li>
            <li>• Yedek dosyası bilgisayarınıza indirilir</li>
            <li>• Dosyayı güvenli bir yerde saklayın</li>
            <li>• Gerektiğinde verilerinizi geri yükleyebilirsiniz</li>
          </ul>
        </div>
      </CardContent>
    </Card>
  );
};

export default BackupSettings;
