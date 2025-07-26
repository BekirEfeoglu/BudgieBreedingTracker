import React from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Switch } from '@/components/ui/switch';
import { Label } from '@/components/ui/label';
import { useToast } from '@/hooks/use-toast';
import { Download, Upload, Database, Clock } from 'lucide-react';

const BackupSettings = () => {
  const { toast } = useToast();

  const handleManualBackup = async () => {
    try {
      // Mock backup implementation
      await new Promise(resolve => setTimeout(resolve, 2000));
      toast({
        title: 'Yedekleme Başarılı',
        description: 'Verileriniz başarıyla yedeklendi',
      });
    } catch (error) {
      toast({
        title: 'Yedekleme Hatası',
        description: 'Yedekleme sırasında bir hata oluştu',
        variant: 'destructive',
      });
    }
  };

  const handleRestore = async () => {
    try {
      // Mock restore implementation
      await new Promise(resolve => setTimeout(resolve, 2000));
      toast({
        title: 'Geri Yükleme Başarılı',
        description: 'Verileriniz başarıyla geri yüklendi',
      });
    } catch (error) {
      toast({
        title: 'Geri Yükleme Hatası',
        description: 'Geri yükleme sırasında bir hata oluştu',
        variant: 'destructive',
      });
    }
  };

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Database className="h-5 w-5" />
            Manuel Yedekleme
          </CardTitle>
          <CardDescription>
            Verilerinizi manuel olarak yedekleyin veya geri yükleyin
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex gap-4">
            <Button
              onClick={handleManualBackup}
              className="flex-1"
            >
              <Download className="h-4 w-4 mr-2" />
              Yedekle
            </Button>
            <Button
              onClick={handleRestore}
              variant="outline"
              className="flex-1"
            >
              <Upload className="h-4 w-4 mr-2" />
              Geri Yükle
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default BackupSettings; 