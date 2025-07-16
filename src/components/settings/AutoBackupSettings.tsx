import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Switch } from '@/components/ui/switch';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { useAutoBackup } from '@/hooks/useAutoBackup';
import { RefreshCw, Download, Clock, Database, CheckCircle } from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';

export const AutoBackupSettings = () => {
  const { settings, status, updateBackupSettings, startManualBackup } = useAutoBackup();
  const { t } = useLanguage();

  const formatTime = (date: Date | null) => {
    if (!date) return 'Henüz yok';
    return date.toLocaleString('tr-TR');
  };

  const getStatusColor = () => {
    if (status.isRunning) return 'bg-blue-500';
    if (status.lastBackupTime) return 'bg-green-500';
    return 'bg-gray-500';
  };

  const getStatusText = () => {
    if (status.isRunning) return 'Yedekleme Çalışıyor';
    if (status.lastBackupTime) return 'Güncel';
    return 'Henüz Yedekleme Yok';
  };

  return (
    <div className="space-y-6">
      {/* Yedekleme Durumu */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Database className="w-5 h-5" />
            Yedekleme Durumu
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <div className={`w-3 h-3 rounded-full ${getStatusColor()}`} />
              <span className="font-medium">{getStatusText()}</span>
            </div>
            <Badge variant="outline" className="font-mono">
              {status.totalBackups} toplam yedek
            </Badge>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
            <div className="flex items-center gap-2">
              <CheckCircle className="w-4 h-4 text-green-500" />
              <div>
                <div className="font-medium">Son Yedekleme</div>
                <div className="text-muted-foreground">{formatTime(status.lastBackupTime)}</div>
              </div>
            </div>
            
            {status.nextBackupTime && (
              <div className="flex items-center gap-2">
                <Clock className="w-4 h-4 text-blue-500" />
                <div>
                  <div className="font-medium">Sonraki Otomatik Yedekleme</div>
                  <div className="text-muted-foreground">{formatTime(status.nextBackupTime)}</div>
                </div>
              </div>
            )}
          </div>

          <Separator />

          <Button 
            onClick={startManualBackup}
            disabled={status.isRunning}
            className="w-full"
          >
            {status.isRunning ? (
              <>
                <RefreshCw className="w-4 h-4 mr-2 animate-spin" />
                Yedekleme Çalışıyor...
              </>
            ) : (
              <>
                <Download className="w-4 h-4 mr-2" />
                Manuel Yedekleme Başlat
              </>
            )}
          </Button>
        </CardContent>
      </Card>

      {/* Otomatik Yedekleme Ayarları */}
      <Card>
        <CardHeader>
          <CardTitle>Otomatik Yedekleme Ayarları</CardTitle>
        </CardHeader>
        <CardContent className="space-y-6">
          {/* Otomatik Yedekleme Aktif/Pasif */}
          <div className="flex items-center justify-between">
            <div className="space-y-1">
              <Label htmlFor="auto-backup" className="text-base font-medium">
                Otomatik Yedekleme
              </Label>
              <div className="text-sm text-muted-foreground">
                Belirli aralıklarla otomatik olarak verilerinizi yedekler
              </div>
            </div>
            <Switch
              id="auto-backup"
              checked={settings.autoBackupEnabled}
              onCheckedChange={(checked) => 
                updateBackupSettings({ autoBackupEnabled: checked })
              }
            />
          </div>

          {settings.autoBackupEnabled && (
            <>
              <Separator />
              
              {/* Yedekleme Sıklığı */}
              <div className="space-y-3">
                <Label className="text-base font-medium">Yedekleme Sıklığı</Label>
                <Select
                  value={settings.backupFrequencyHours.toString()}
                  onValueChange={(value) => 
                    updateBackupSettings({ backupFrequencyHours: parseInt(value) })
                  }
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="6">Her 6 saatte bir</SelectItem>
                    <SelectItem value="12">Her 12 saatte bir</SelectItem>
                    <SelectItem value="24">{t('common.daily')}</SelectItem>
                    <SelectItem value="72">3 günde bir</SelectItem>
                    <SelectItem value="168">{t('common.weekly')}</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              {/* Saklama Süresi */}
              <div className="space-y-3">
                <Label className="text-base font-medium">Yedekleri Saklama Süresi</Label>
                <Select
                  value={settings.retentionDays.toString()}
                  onValueChange={(value) => 
                    updateBackupSettings({ retentionDays: parseInt(value) })
                  }
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="7">7 gün</SelectItem>
                    <SelectItem value="14">14 gün</SelectItem>
                    <SelectItem value="30">30 gün</SelectItem>
                    <SelectItem value="60">60 gün</SelectItem>
                    <SelectItem value="90">90 gün</SelectItem>
                  </SelectContent>
                </Select>
                <div className="text-sm text-muted-foreground">
                  Bu süreden eski yedekler otomatik olarak silinir
                </div>
              </div>

              {/* Yedeklenecek Tablolar */}
              <div className="space-y-3">
                <Label className="text-base font-medium">Yedeklenecek Veriler</Label>
                <div className="flex flex-wrap gap-2">
                  {['birds', 'clutches', 'eggs', 'chicks', 'calendar'].map((table) => (
                    <Badge key={table} variant="secondary" className="px-3 py-1">
                      {table === 'birds' && '🦜 Kuşlar'}
                      {table === 'clutches' && '🥚 Üreme Kayıtları'}
                      {table === 'eggs' && '🥚 Yumurtalar'}
                      {table === 'chicks' && '🐣 Yavrular'}
                      {table === 'calendar' && '📅 Takvim'}
                    </Badge>
                  ))}
                </div>
                <div className="text-sm text-muted-foreground">
                  Tüm temel verileriniz otomatik olarak yedeklenir
                </div>
              </div>
            </>
          )}
        </CardContent>
      </Card>
    </div>
  );
};
