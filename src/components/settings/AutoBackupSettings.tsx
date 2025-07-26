import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Switch } from '@/components/ui/switch';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { useToast } from '@/hooks/use-toast';
import { useBackupSettings } from '@/hooks/backup/useBackupSettings';
import { useBackupStatus } from '@/hooks/backup/useBackupStatus';
import { useBackupOperations } from '@/hooks/backup/useBackupOperations';
import { Clock, Download, Calendar, HardDrive, Settings, Image } from 'lucide-react';

const AutoBackupSettings = () => {
  const { toast } = useToast();
  const { settings, loading: settingsLoading, updateSettings } = useBackupSettings();
  const { status, loading: statusLoading } = useBackupStatus();
  const { createBackup, getBackupList } = useBackupOperations();
  const [backups, setBackups] = useState<any[]>([]);
  const [loadingBackups, setLoadingBackups] = useState(false);

  useEffect(() => {
    loadBackups();
  }, []);

  const loadBackups = async () => {
    setLoadingBackups(true);
    try {
      const result = await getBackupList();
      if (result.success && result.data) {
        setBackups(result.data);
      }
    } catch (error) {
      console.error('Yedekler yüklenirken hata:', error);
    } finally {
      setLoadingBackups(false);
    }
  };

  const handleAutoBackupToggle = async (enabled: boolean) => {
    await updateSettings({ autoBackupEnabled: enabled });
  };

  const handleFrequencyChange = async (frequency: 'daily' | 'weekly' | 'monthly') => {
    await updateSettings({ backupFrequency: frequency });
  };

  const handleTimeChange = async (time: string) => {
    await updateSettings({ backupTime: time });
  };

  const handleMaxBackupsChange = async (max: number) => {
    await updateSettings({ maxBackups: max });
  };

  const handleIncludePhotosToggle = async (enabled: boolean) => {
    await updateSettings({ includePhotos: enabled });
  };

  const handleIncludeSettingsToggle = async (enabled: boolean) => {
    await updateSettings({ includeSettings: enabled });
  };

  const handleManualBackup = async () => {
    const result = await createBackup();
    if (result.success) {
      loadBackups(); // Refresh backup list
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('tr-TR', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  if (settingsLoading || statusLoading) {
    return (
      <div className="space-y-6">
        {[...Array(3)].map((_, i) => (
          <Card key={i} className="animate-pulse">
            <CardHeader>
              <div className="h-6 bg-muted rounded w-1/3"></div>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                <div className="h-4 bg-muted rounded w-full"></div>
                <div className="h-4 bg-muted rounded w-2/3"></div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Otomatik Yedekleme Ayarları */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Calendar className="h-5 w-5" />
            Otomatik Yedekleme
          </CardTitle>
          <CardDescription>
            Verilerinizin otomatik olarak yedeklenmesini sağlayın
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="flex items-center justify-between">
            <div className="space-y-0.5">
              <Label>Otomatik Yedekleme</Label>
              <p className="text-sm text-muted-foreground">
                Düzenli aralıklarla verilerinizi otomatik olarak yedekleyin
              </p>
            </div>
            <Switch
              checked={settings.autoBackupEnabled}
              onCheckedChange={handleAutoBackupToggle}
            />
          </div>

          {settings.autoBackupEnabled && (
            <>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>Yedekleme Sıklığı</Label>
                  <Select
                    value={settings.backupFrequency}
                    onValueChange={handleFrequencyChange}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="daily">Günlük</SelectItem>
                      <SelectItem value="weekly">Haftalık</SelectItem>
                      <SelectItem value="monthly">Aylık</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2">
                  <Label>Yedekleme Saati</Label>
                  <Input
                    type="time"
                    value={settings.backupTime}
                    onChange={(e) => handleTimeChange(e.target.value)}
                  />
                </div>
              </div>

              <div className="space-y-2">
                <Label>Maksimum Yedek Sayısı: {settings.maxBackups}</Label>
                <input
                  type="range"
                  min="5"
                  max="50"
                  value={settings.maxBackups}
                  onChange={(e) => handleMaxBackupsChange(parseInt(e.target.value))}
                  className="w-full"
                />
                <div className="flex justify-between text-xs text-muted-foreground">
                  <span>5</span>
                  <span>50</span>
                </div>
              </div>
            </>
          )}
        </CardContent>
      </Card>

      {/* Yedekleme İçeriği */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <HardDrive className="h-5 w-5" />
            Yedekleme İçeriği
          </CardTitle>
          <CardDescription>
            Hangi verilerin yedekleneceğini seçin
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Image className="h-4 w-4" />
              <div className="space-y-0.5">
                <Label>Fotoğraflar</Label>
                <p className="text-sm text-muted-foreground">Kuş fotoğraflarını dahil et</p>
              </div>
            </div>
            <Switch
              checked={settings.includePhotos}
              onCheckedChange={handleIncludePhotosToggle}
            />
          </div>

          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Settings className="h-4 w-4" />
              <div className="space-y-0.5">
                <Label>Ayarlar</Label>
                <p className="text-sm text-muted-foreground">Uygulama ayarlarını dahil et</p>
              </div>
            </div>
            <Switch
              checked={settings.includeSettings}
              onCheckedChange={handleIncludeSettingsToggle}
            />
          </div>
        </CardContent>
      </Card>

      {/* Yedekleme Durumu */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Clock className="h-5 w-5" />
            Yedekleme Durumu
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="text-center p-4 border rounded-lg">
              <p className="text-sm text-muted-foreground">Son Yedekleme</p>
              <p className="font-medium">
                {status.lastBackup ? formatDate(status.lastBackup) : 'Henüz yok'}
              </p>
            </div>
            <div className="text-center p-4 border rounded-lg">
              <p className="text-sm text-muted-foreground">Toplam Yedek</p>
              <p className="font-medium">{status.totalBackups}</p>
            </div>
            <div className="text-center p-4 border rounded-lg">
              <p className="text-sm text-muted-foreground">Toplam Boyut</p>
              <p className="font-medium">{status.totalSize}</p>
            </div>
          </div>

          <Button
            onClick={handleManualBackup}
            disabled={status.isBackingUp}
            className="w-full"
          >
            {status.isBackingUp ? (
              <>
                <Clock className="h-4 w-4 mr-2 animate-spin" />
                Yedekleniyor...
              </>
            ) : (
              <>
                <Download className="h-4 w-4 mr-2" />
                Manuel Yedekleme
              </>
            )}
          </Button>
        </CardContent>
      </Card>

      {/* Son Yedekler */}
      <Card>
        <CardHeader>
          <CardTitle>Son Yedekler</CardTitle>
        </CardHeader>
        <CardContent>
          {loadingBackups ? (
            <div className="space-y-2">
              {[...Array(3)].map((_, i) => (
                <div key={i} className="h-12 bg-muted rounded animate-pulse"></div>
              ))}
            </div>
          ) : backups.length > 0 ? (
            <div className="space-y-2">
              {backups.slice(0, 5).map((backup) => (
                <div key={backup.id} className="flex items-center justify-between p-3 border rounded-lg">
                  <div>
                    <p className="font-medium">{backup.name}</p>
                    <p className="text-sm text-muted-foreground">
                      {formatDate(backup.date)} • {backup.size}
                    </p>
                  </div>
                  <Badge variant={backup.type === 'auto' ? 'default' : 'secondary'}>
                    {backup.type === 'auto' ? 'Otomatik' : 'Manuel'}
                  </Badge>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-center text-muted-foreground py-4">
              Henüz yedek bulunmuyor
            </p>
          )}
        </CardContent>
      </Card>
    </div>
  );
};

export default AutoBackupSettings;

