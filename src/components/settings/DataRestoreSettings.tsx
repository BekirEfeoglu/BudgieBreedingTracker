import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { toast } from '@/hooks/use-toast';
import { useAuth } from '@/hooks/useAuth';
import { supabase } from '@/integrations/supabase/client';
import { Upload, FileText, AlertTriangle, Loader2 } from 'lucide-react';
import { Alert, AlertDescription } from '@/components/ui/alert';

interface BackupData {
  exportDate: string;
  userId: string;
  userEmail: string;
  version: string;
  data: {
    birds: Record<string, unknown>[];
    clutches: Record<string, unknown>[];
    eggs: Record<string, unknown>[];
    chicks: Record<string, unknown>[];
    calendar: Record<string, unknown>[];
    incubations: Record<string, unknown>[];
  };
  summary: {
    totalBirds: number;
    totalClutches: number;
    totalEggs: number;
    totalChicks: number;
    totalCalendarEvents: number;
    totalIncubations: number;
  };
}

const DataRestoreSettings = () => {
  const { user } = useAuth();
  const [_selectedFile, setSelectedFile] = useState<File | null>(null);
  const [backupPreview, setBackupPreview] = useState<BackupData | null>(null);
  const [isRestoring, setIsRestoring] = useState(false);

  const handleFileSelect = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    if (file.type !== 'application/json') {
      toast({
        title: 'Hatalı Dosya',
        description: 'Lütfen geçerli bir JSON yedek dosyası seçin.',
        variant: 'destructive'
      });
      return;
    }

    try {
      const text = await file.text();
      const data = JSON.parse(text) as BackupData;
      
      // Validate backup file structure
      if (!data.data || !data.summary || !data.exportDate) {
        throw new Error('Geçersiz yedek dosyası formatı');
      }

      setSelectedFile(file);
      setBackupPreview(data);
      
      toast({
        title: 'Yedek Dosyası Yüklendi',
        description: 'Dosya başarıyla analiz edildi. Geri yüklemek için butona tıklayın.',
      });

    } catch (error) {
      toast({
        title: 'Dosya Hatası',
        description: 'Yedek dosyası okunamadı. Geçerli bir yedek dosyası seçin.',
        variant: 'destructive'
      });
    }
  };

  const handleRestore = async () => {
    if (!user || !backupPreview) return;

    setIsRestoring(true);

    try {
      // Delete existing data first (in reverse dependency order)
      const deletionOrder = ['calendar', 'chicks', 'eggs', 'incubations', 'clutches', 'birds'];
      
      for (const table of deletionOrder) {
        const { error } = await supabase
          .from(table as keyof typeof backupPreview.data)
          .delete()
          .eq('user_id', user.id);
          
        if (error) {
          // Silently handle deletion errors
        }
      }

      // Restore data (in dependency order)
      const restorationOrder = ['birds', 'clutches', 'incubations', 'eggs', 'chicks', 'calendar'];
      let totalRestored = 0;

      for (const table of restorationOrder) {
        const tableData = backupPreview.data[table as keyof typeof backupPreview.data];
        
        if (tableData && tableData.length > 0) {
          // Update user_id to current user
          const dataWithCorrectUserId = tableData.map(item => ({
            ...item,
            user_id: user.id
          }));

          const { error } = await supabase
            .from(table as keyof typeof backupPreview.data)
            .insert(dataWithCorrectUserId);

          if (error) {
            throw new Error(`${table} tablosu geri yüklenemedi: ${error.message}`);
          } else {
            totalRestored += tableData.length;
          }
        }
      }

      toast({
        title: 'Geri Yükleme Tamamlandı',
        description: `${totalRestored} kayıt başarıyla geri yüklendi. Sayfa yenileniyor...`,
      });

      // Refresh the page to load new data
      setTimeout(() => {
        window.location.reload();
      }, 2000);

    } catch (error) {
      toast({
        title: 'Geri Yükleme Hatası',
        description: error instanceof Error ? error.message : 'Beklenmedik bir hata oluştu.',
        variant: 'destructive'
      });
    } finally {
      setIsRestoring(false);
    }
  };

  return (
    <Card className="budgie-card shadow-sm">
      <CardHeader className="pb-4">
        <CardTitle className="flex items-center gap-2 text-lg">
          <Upload className="w-5 h-5" />
          Veri Geri Yükleme
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="space-y-2">
          <label htmlFor="backup-file" className="text-sm font-medium">
            Yedek Dosyası Seçin
          </label>
          <Input
            id="backup-file"
            type="file"
            accept=".json"
            onChange={handleFileSelect}
            className="min-h-[48px] touch-manipulation"
          />
        </div>

        {backupPreview && (
          <div className="space-y-3">
            <div className="bg-muted/30 p-3 rounded-lg">
              <div className="flex items-center gap-2 mb-2">
                <FileText className="w-4 h-4" />
                <span className="font-medium text-sm">Yedek Dosyası Özeti</span>
              </div>
              <div className="grid grid-cols-2 gap-2 text-xs">
                <div>Tarih: {new Date(backupPreview.exportDate).toLocaleDateString('tr-TR')}</div>
                <div>Kuşlar: {backupPreview.summary.totalBirds}</div>
                <div>Çiftleştirmeler: {backupPreview.summary.totalClutches}</div>
                <div>Yumurtalar: {backupPreview.summary.totalEggs}</div>
                <div>Yavrular: {backupPreview.summary.totalChicks}</div>
                <div>Etkinlikler: {backupPreview.summary.totalCalendarEvents}</div>
              </div>
            </div>

            <Alert>
              <AlertTriangle className="h-4 w-4" />
              <AlertDescription className="text-sm">
                <strong>DİKKAT:</strong> Bu işlem mevcut tüm verilerinizi silecek ve yedek dosyasındaki verilerle değiştirecek. Bu işlem geri alınamaz.
              </AlertDescription>
            </Alert>

            <Button
              onClick={handleRestore}
              disabled={isRestoring}
              className="w-full min-h-[48px] touch-manipulation"
              variant="destructive"
            >
              {isRestoring ? (
                <Loader2 className="w-5 h-5 mr-2 animate-spin" />
              ) : (
                <Upload className="w-5 h-5 mr-2" />
              )}
              {isRestoring ? 'Geri Yükleniyor...' : 'Verileri Geri Yükle'}
            </Button>
          </div>
        )}

        <div className="text-sm text-muted-foreground bg-muted/30 p-3 rounded-lg space-y-2">
          <p className="font-medium">Geri yükleme hakkında:</p>
          <ul className="space-y-1 text-xs">
            <li>• Sadece JSON formatındaki yedek dosyalarını yükleyebilirsiniz</li>
            <li>• Mevcut tüm verileriniz silinecek ve yedekteki verilerle değiştirilecek</li>
            <li>• İşlem tamamlandıktan sonra sayfa otomatik yenilenecek</li>
            <li>• Bu işlem geri alınamaz, dikkatli olun</li>
          </ul>
        </div>
      </CardContent>
    </Card>
  );
};

export default DataRestoreSettings;
