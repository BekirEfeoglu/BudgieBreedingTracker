import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { useToast } from '@/hooks/use-toast';
import { RefreshCw, AlertTriangle, CheckCircle } from 'lucide-react';

const DataRestoreSettings = () => {
  const { toast } = useToast();
  const [selectedBackup, setSelectedBackup] = useState('');

  const mockBackups = [
    { id: '1', name: 'Yedek 1 - 21 Temmuz 2025', date: '2025-07-21', size: '2.3 MB' },
    { id: '2', name: 'Yedek 2 - 20 Temmuz 2025', date: '2025-07-20', size: '2.1 MB' },
    { id: '3', name: 'Yedek 3 - 19 Temmuz 2025', date: '2025-07-19', size: '2.0 MB' },
  ];

  const handleRestore = async () => {
    if (!selectedBackup) {
      toast({
        title: 'Yedek Seçilmedi',
        description: 'Lütfen geri yüklenecek yedeği seçin',
        variant: 'destructive',
      });
      return;
    }

    try {
      // Mock restore implementation
      await new Promise(resolve => setTimeout(resolve, 3000));
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
            <RefreshCw className="h-5 w-5" />
            Veri Geri Yükleme
          </CardTitle>
          <CardDescription>
            Önceden oluşturulan yedeklerden verilerinizi geri yükleyin
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-2">
            <Label>Mevcut Yedekler</Label>
            <div className="space-y-2">
              {mockBackups.map((backup) => (
                <div
                  key={backup.id}
                  className={`p-3 border rounded-lg cursor-pointer transition-colors ${
                    selectedBackup === backup.id
                      ? 'border-primary bg-primary/5'
                      : 'border-border hover:border-primary/50'
                  }`}
                  onClick={() => setSelectedBackup(backup.id)}
                >
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="font-medium">{backup.name}</p>
                      <p className="text-sm text-muted-foreground">
                        Boyut: {backup.size} • Tarih: {backup.date}
                      </p>
                    </div>
                    {selectedBackup === backup.id && (
                      <CheckCircle className="h-4 w-4 text-primary" />
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>

          <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
            <div className="flex items-start gap-2">
              <AlertTriangle className="h-5 w-5 text-yellow-600 mt-0.5" />
              <div>
                <p className="font-medium text-yellow-800">Dikkat</p>
                <p className="text-sm text-yellow-700">
                  Geri yükleme işlemi mevcut verilerinizi değiştirecektir. 
                  Bu işlem geri alınamaz.
                </p>
              </div>
            </div>
          </div>

          <Button
            onClick={handleRestore}
            disabled={!selectedBackup}
            className="w-full"
          >
            <RefreshCw className="h-4 w-4 mr-2" />
            Seçili Yedeği Geri Yükle
          </Button>
        </CardContent>
      </Card>
    </div>
  );
};

export default DataRestoreSettings; 