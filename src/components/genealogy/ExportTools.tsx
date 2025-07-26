import React, { useState, useCallback } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Textarea } from '@/components/ui/textarea';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { 
  Download, 
  Share2, 
  FileText, 
  Image, 
  Save, 
  Upload,
  Copy,
  Check,
  Settings,
  BarChart3
} from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';
import { Bird, Chick } from '@/types';

interface ExportToolsProps {
  familyData: {
    father: Bird | Chick | null;
    mother: Bird | Chick | null;
    children: (Bird | Chick)[];
    grandparents: {
      paternalGrandfather: Bird | Chick | null;
      paternalGrandmother: Bird | Chick | null;
      maternalGrandfather: Bird | Chick | null;
      maternalGrandmother: Bird | Chick | null;
    };
    siblings: (Bird | Chick)[];
    cousins: (Bird | Chick)[];
  };
  selectedBird: Bird | Chick;
}

interface ExportOptions {
  format: 'pdf' | 'png' | 'svg' | 'json';
  includePhotos: boolean;
  includeStats: boolean;
  includeTimeline: boolean;
  includeGeneticAnalysis: boolean;
  quality: 'low' | 'medium' | 'high';
  size: 'small' | 'medium' | 'large';
}

interface ShareOptions {
  platform: 'email' | 'whatsapp' | 'telegram' | 'copy';
  includeDescription: boolean;
  includeContact: boolean;
  privacy: 'public' | 'private' | 'friends';
}

const ExportTools: React.FC<ExportToolsProps> = ({
  familyData,
  selectedBird
}) => {
  const { t } = useLanguage();
  const [isExporting, setIsExporting] = useState(false);
  const [isSharing, setIsSharing] = useState(false);
  const [copied, setCopied] = useState(false);
  const [exportOptions, setExportOptions] = useState<ExportOptions>({
    format: 'pdf',
    includePhotos: true,
    includeStats: true,
    includeTimeline: true,
    includeGeneticAnalysis: true,
    quality: 'medium',
    size: 'medium'
  });
  const [shareOptions, setShareOptions] = useState<ShareOptions>({
    platform: 'copy',
    includeDescription: true,
    includeContact: false,
    privacy: 'private'
  });

  // PDF Raporu oluştur
  const generatePDFReport = useCallback(async () => {
    setIsExporting(true);
    try {
      // Bu fonksiyon gerçek PDF oluşturma kütüphanesi kullanacak
      // Şimdilik simüle ediyoruz
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      const reportData = {
        title: `${selectedBird.name} - Soyağacı Raporu`,
        date: new Date().toLocaleDateString('tr-TR'),
        bird: selectedBird,
        family: familyData,
        stats: {
          totalMembers: 1 + familyData.children.length + familyData.siblings.length,
          generations: 3,
          averageAge: 2.5
        }
      };

      console.log('PDF Raporu oluşturuldu:', reportData);
      
      // Gerçek uygulamada burada PDF indirme işlemi yapılacak
      const link = document.createElement('a');
      link.href = 'data:text/plain;charset=utf-8,' + encodeURIComponent(JSON.stringify(reportData, null, 2));
      link.download = `${selectedBird.name}-soyagaci-raporu.pdf`;
      link.click();
      
    } catch (error) {
      console.error('PDF oluşturma hatası:', error);
    } finally {
      setIsExporting(false);
    }
  }, [familyData, selectedBird]);

  // Görsel dışa aktarma
  const exportVisualization = useCallback(async () => {
    setIsExporting(true);
    try {
      // html2canvas veya benzeri kütüphane kullanılacak
      await new Promise(resolve => setTimeout(resolve, 1500));
      
      console.log('Görsel dışa aktarıldı:', exportOptions.format);
      
      // Simüle edilmiş indirme
      const link = document.createElement('a');
      link.href = 'data:text/plain;charset=utf-8,' + encodeURIComponent('Görsel verisi');
      link.download = `${selectedBird.name}-soyagaci.${exportOptions.format}`;
      link.click();
    } catch (error) {
      console.error('Görsel dışa aktarma hatası:', error);
    } finally {
      setIsExporting(false);
    }
  }, [exportOptions.format, selectedBird.name]);

  // Paylaşım işlemleri
  const handleShare = useCallback(async () => {
    setIsSharing(true);
    try {
      const shareData = {
        title: `${selectedBird.name} - Soyağacı`,
        text: `${selectedBird.name} kuşunun soyağacını görüntüleyin`,
        url: window.location.href
      };

      switch (shareOptions.platform) {
        case 'email':
          window.open(`mailto:?subject=${encodeURIComponent(shareData.title)}&body=${encodeURIComponent(shareData.text + '\n\n' + shareData.url)}`);
          break;
        case 'whatsapp':
          window.open(`https://wa.me/?text=${encodeURIComponent(shareData.text + '\n\n' + shareData.url)}`);
          break;
        case 'telegram':
          window.open(`https://t.me/share/url?url=${encodeURIComponent(shareData.url)}&text=${encodeURIComponent(shareData.text)}`);
          break;
        case 'copy':
          await navigator.clipboard.writeText(`${shareData.text}\n\n${shareData.url}`);
          setCopied(true);
          setTimeout(() => setCopied(false), 2000);
          break;
      }
    } catch (error) {
      console.error('Paylaşım hatası:', error);
    } finally {
      setIsSharing(false);
    }
  }, [selectedBird.name, shareOptions.platform]);

  // Yedekleme işlemleri
  const exportBackup = useCallback(async () => {
    setIsExporting(true);
    try {
      const backupData = {
        timestamp: new Date().toISOString(),
        version: '1.0.0',
        bird: selectedBird,
        familyData: familyData,
        metadata: {
          totalMembers: 1 + familyData.children.length + familyData.siblings.length,
          exportOptions: exportOptions
        }
      };

      const dataStr = JSON.stringify(backupData, null, 2);
      const dataBlob = new Blob([dataStr], { type: 'application/json' });
      
      const link = document.createElement('a');
      link.href = URL.createObjectURL(dataBlob);
      link.download = `soyagaci-yedek-${new Date().toISOString().split('T')[0]}.json`;
      link.click();
      
    } catch (error) {
      console.error('Yedekleme hatası:', error);
    } finally {
      setIsExporting(false);
    }
  }, [familyData, selectedBird, exportOptions]);

  const importBackup = useCallback((event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = (e) => {
        try {
          const backupData = JSON.parse(e.target?.result as string);
          console.log('Yedek verisi yüklendi:', backupData);
          // Burada yedek verisi geri yükleme işlemi yapılacak
        } catch (error) {
          console.error('Yedek dosyası okuma hatası:', error);
        }
      };
      reader.readAsText(file);
    }
  }, []);

  return (
    <div className="space-y-6">
      {/* Dışa Aktarma Araçları */}
      <Card className="enhanced-card">
        <CardHeader>
          <CardTitle className="text-lg flex items-center gap-2">
            📤 Dışa Aktarma ve Paylaşım
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            {/* PDF Raporu */}
            <Dialog>
              <DialogTrigger asChild>
                <Button variant="outline" className="h-auto p-4 flex flex-col items-center gap-2">
                  <FileText className="w-6 h-6" />
                  <span className="text-sm">PDF Raporu</span>
                </Button>
              </DialogTrigger>
              <DialogContent className="max-w-md">
                <DialogHeader>
                  <DialogTitle>PDF Raporu Oluştur</DialogTitle>
                </DialogHeader>
                <div className="space-y-4">
                  <div className="space-y-2">
                    <Label>Rapor Adı</Label>
                    <Input 
                      defaultValue={`${selectedBird.name} - Soyağacı Raporu`}
                      placeholder="Rapor adını girin"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label>İçerik Seçenekleri</Label>
                    <div className="space-y-2">
                      <div className="flex items-center space-x-2">
                        <Switch 
                          id="include-photos" 
                          checked={exportOptions.includePhotos}
                          onCheckedChange={(checked) => setExportOptions(prev => ({ ...prev, includePhotos: checked }))}
                        />
                        <Label htmlFor="include-photos">Fotoğrafları Dahil Et</Label>
                      </div>
                      <div className="flex items-center space-x-2">
                        <Switch 
                          id="include-stats" 
                          checked={exportOptions.includeStats}
                          onCheckedChange={(checked) => setExportOptions(prev => ({ ...prev, includeStats: checked }))}
                        />
                        <Label htmlFor="include-stats">İstatistikleri Dahil Et</Label>
                      </div>
                      <div className="flex items-center space-x-2">
                        <Switch 
                          id="include-timeline" 
                          checked={exportOptions.includeTimeline}
                          onCheckedChange={(checked) => setExportOptions(prev => ({ ...prev, includeTimeline: checked }))}
                        />
                        <Label htmlFor="include-timeline">Zaman Çizelgesini Dahil Et</Label>
                      </div>
                    </div>
                  </div>
                  <Button 
                    onClick={generatePDFReport} 
                    disabled={isExporting}
                    className="w-full"
                  >
                    {isExporting ? 'Oluşturuluyor...' : 'PDF Oluştur'}
                  </Button>
                </div>
              </DialogContent>
            </Dialog>

            {/* Görsel Dışa Aktarma */}
            <Dialog>
              <DialogTrigger asChild>
                <Button variant="outline" className="h-auto p-4 flex flex-col items-center gap-2">
                  <Image className="w-6 h-6" />
                  <span className="text-sm">Görsel Dışa Aktar</span>
                </Button>
              </DialogTrigger>
              <DialogContent className="max-w-md">
                <DialogHeader>
                  <DialogTitle>Görsel Dışa Aktarma</DialogTitle>
                </DialogHeader>
                <div className="space-y-4">
                  <div className="space-y-2">
                    <Label>Format</Label>
                    <Select 
                      value={exportOptions.format} 
                      onValueChange={(value: 'png' | 'svg') => setExportOptions(prev => ({ ...prev, format: value }))}
                    >
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="png">PNG</SelectItem>
                        <SelectItem value="svg">SVG</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="space-y-2">
                    <Label>Kalite</Label>
                    <Select 
                      value={exportOptions.quality} 
                      onValueChange={(value: 'low' | 'medium' | 'high') => setExportOptions(prev => ({ ...prev, quality: value }))}
                    >
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="low">Düşük</SelectItem>
                        <SelectItem value="medium">Orta</SelectItem>
                        <SelectItem value="high">Yüksek</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="space-y-2">
                    <Label>Boyut</Label>
                    <Select 
                      value={exportOptions.size} 
                      onValueChange={(value: 'small' | 'medium' | 'large') => setExportOptions(prev => ({ ...prev, size: value }))}
                    >
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="small">Küçük</SelectItem>
                        <SelectItem value="medium">Orta</SelectItem>
                        <SelectItem value="large">Büyük</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <Button 
                    onClick={exportVisualization} 
                    disabled={isExporting}
                    className="w-full"
                  >
                    {isExporting ? 'Dışa Aktarılıyor...' : 'Dışa Aktar'}
                  </Button>
                </div>
              </DialogContent>
            </Dialog>

            {/* Paylaşım */}
            <Dialog>
              <DialogTrigger asChild>
                <Button variant="outline" className="h-auto p-4 flex flex-col items-center gap-2">
                  <Share2 className="w-6 h-6" />
                  <span className="text-sm">Paylaş</span>
                </Button>
              </DialogTrigger>
              <DialogContent className="max-w-md">
                <DialogHeader>
                  <DialogTitle>Soyağacını Paylaş</DialogTitle>
                </DialogHeader>
                <div className="space-y-4">
                  <div className="space-y-2">
                    <Label>Paylaşım Platformu</Label>
                    <Select 
                      value={shareOptions.platform} 
                      onValueChange={(value: 'email' | 'whatsapp' | 'telegram' | 'copy') => setShareOptions(prev => ({ ...prev, platform: value }))}
                    >
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="email">E-posta</SelectItem>
                        <SelectItem value="whatsapp">WhatsApp</SelectItem>
                        <SelectItem value="telegram">Telegram</SelectItem>
                        <SelectItem value="copy">Bağlantıyı Kopyala</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="space-y-2">
                    <Label>Gizlilik</Label>
                    <Select 
                      value={shareOptions.privacy} 
                      onValueChange={(value: 'public' | 'private' | 'friends') => setShareOptions(prev => ({ ...prev, privacy: value }))}
                    >
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="public">Herkese Açık</SelectItem>
                        <SelectItem value="private">Özel</SelectItem>
                        <SelectItem value="friends">Arkadaşlar</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="space-y-2">
                    <Label>Özel Mesaj (İsteğe Bağlı)</Label>
                    <Textarea 
                      placeholder={`${selectedBird.name} kuşunun soyağacını görüntüleyin`}
                      rows={3}
                    />
                  </div>
                  <Button 
                    onClick={handleShare} 
                    disabled={isSharing}
                    className="w-full"
                  >
                    {isSharing ? 'Paylaşılıyor...' : 
                     shareOptions.platform === 'copy' ? 
                       (copied ? <><Check className="w-4 h-4 mr-2" />Kopyalandı</> : <><Copy className="w-4 h-4 mr-2" />Kopyala</>) : 
                       'Paylaş'}
                  </Button>
                </div>
              </DialogContent>
            </Dialog>

            {/* Yedekleme */}
            <Dialog>
              <DialogTrigger asChild>
                <Button variant="outline" className="h-auto p-4 flex flex-col items-center gap-2">
                  <Save className="w-6 h-6" />
                  <span className="text-sm">Yedekleme</span>
                </Button>
              </DialogTrigger>
              <DialogContent className="max-w-md">
                <DialogHeader>
                  <DialogTitle>Veri Yedekleme</DialogTitle>
                </DialogHeader>
                <div className="space-y-4">
                  <div className="space-y-2">
                    <Label>Yedekleme Seçenekleri</Label>
                    <div className="space-y-2">
                      <div className="flex items-center space-x-2">
                        <Switch 
                          id="include-genetic" 
                          checked={exportOptions.includeGeneticAnalysis}
                          onCheckedChange={(checked) => setExportOptions(prev => ({ ...prev, includeGeneticAnalysis: checked }))}
                        />
                        <Label htmlFor="include-genetic">Genetik Analizi Dahil Et</Label>
                      </div>
                    </div>
                  </div>
                  <div className="grid grid-cols-2 gap-2">
                    <Button 
                      onClick={exportBackup} 
                      disabled={isExporting}
                      variant="outline"
                    >
                      <Download className="w-4 h-4 mr-2" />
                      Dışa Aktar
                    </Button>
                    <div className="relative">
                      <input
                        type="file"
                        accept=".json"
                        onChange={importBackup}
                        className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
                      />
                      <Button variant="outline" className="w-full">
                        <Upload className="w-4 h-4 mr-2" />
                        İçe Aktar
                      </Button>
                    </div>
                  </div>
                </div>
              </DialogContent>
            </Dialog>
          </div>
        </CardContent>
      </Card>

      {/* Hızlı Eylemler */}
      <Card className="enhanced-card">
        <CardHeader>
          <CardTitle className="text-sm flex items-center gap-2">
            <Settings className="w-4 h-4" />
            Hızlı Eylemler
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex flex-wrap gap-2">
            <Button 
              variant="outline" 
              size="sm"
              onClick={generatePDFReport}
              disabled={isExporting}
            >
              <FileText className="w-4 h-4 mr-2" />
              Hızlı PDF
            </Button>
            <Button 
              variant="outline" 
              size="sm"
              onClick={handleShare}
              disabled={isSharing}
            >
              <Copy className="w-4 h-4 mr-2" />
              Bağlantı Kopyala
            </Button>
            <Button 
              variant="outline" 
              size="sm"
              onClick={exportBackup}
              disabled={isExporting}
            >
              <Save className="w-4 h-4 mr-2" />
              Hızlı Yedek
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Paylaşım İstatistikleri */}
      <Card className="enhanced-card">
        <CardHeader>
          <CardTitle className="text-sm flex items-center gap-2">
            <BarChart3 className="w-4 h-4" />
            Paylaşım İstatistikleri
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div className="text-center">
              <div className="text-2xl font-bold text-blue-600">12</div>
              <div className="text-xs text-muted-foreground">Toplam Paylaşım</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-green-600">8</div>
              <div className="text-xs text-muted-foreground">Görüntülenme</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-orange-600">3</div>
              <div className="text-xs text-muted-foreground">İndirme</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-purple-600">5</div>
              <div className="text-xs text-muted-foreground">Beğeni</div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default ExportTools; 