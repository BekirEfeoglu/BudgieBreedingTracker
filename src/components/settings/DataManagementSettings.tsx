import React, { useState } from 'react';
import { Download, Trash2, Database, FileText, AlertTriangle, Info } from 'lucide-react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import DataExportImport from '@/components/data/DataExportImport';
import { useDataExportImport } from '@/hooks/useDataExportImport';
import { useLanguage } from '@/contexts/LanguageContext';

interface Bird {
  id: string;
  name: string;
  [key: string]: unknown;
}

interface Chick {
  id: string;
  name: string;
  [key: string]: unknown;
}

interface Breeding {
  id: string;
  [key: string]: unknown;
}

interface Egg {
  id: string;
  [key: string]: unknown;
}

interface Incubation {
  id: string;
  [key: string]: unknown;
}

interface DataManagementSettingsProps {
  birds: Bird[];
  chicks?: Chick[];
  breeding?: Breeding[];
  eggs?: Egg[];
  incubations?: Incubation[];
  onDataImport: (data: Record<string, unknown[]>) => Promise<void>;
  onDataClear?: () => Promise<void>;
}

const DataManagementSettings: React.FC<DataManagementSettingsProps> = ({
  birds = [],
  chicks = [],
  breeding = [],
  eggs = [],
  incubations = [],
  onDataImport,
  onDataClear
}) => {
  const { t } = useLanguage();
  
  const {
    exportAllData,
    isExporting,
    isImporting,
    exportProgress,
    importProgress,
    isProcessing
  } = useDataExportImport();

  const [showClearConfirm, setShowClearConfirm] = useState(false);

  // Calculate data statistics
  const dataStats = {
    birds: birds.length,
    chicks: chicks.length,
    breeding: breeding.length,
    eggs: eggs.length,
    incubations: incubations.length,
    get total() {
      return this.birds + this.chicks + this.breeding + this.eggs + this.incubations;
    },
    get estimatedSize() {
      // Rough estimation in KB
      const avgRecordSize = 0.5; // KB per record
      return Math.round(this.total * avgRecordSize);
    }
  };

  // Quick export handlers
  const handleQuickExportJSON = async () => {
    await exportAllData({
      birds,
      chicks,
      breeding,
      eggs,
      incubations
    }, 'json');
  };

  const handleQuickExportCSV = async () => {
    await exportAllData({
      birds,
      chicks,
      breeding,
      eggs,
      incubations
    }, 'csv');
  };

  // Handle data clear
  const handleDataClear = async () => {
    if (onDataClear) {
      await onDataClear();
      setShowClearConfirm(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Data Overview */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Database className="w-5 h-5" />
            Veri Özeti
          </CardTitle>
          <CardDescription>
            Uygulamanızdaki toplam veri miktarı ve dağılımı
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-4">
            <div className="text-center p-3 bg-blue-50 rounded-lg">
              <div className="text-2xl font-bold text-blue-600">{dataStats.birds}</div>
              <div className="text-sm text-blue-600">🦜 Kuşlar</div>
            </div>
            <div className="text-center p-3 bg-yellow-50 rounded-lg">
              <div className="text-2xl font-bold text-yellow-600">{dataStats.chicks}</div>
              <div className="text-sm text-yellow-600">🐣 Yavrular</div>
            </div>
            <div className="text-center p-3 bg-pink-50 rounded-lg">
              <div className="text-2xl font-bold text-pink-600">{dataStats.breeding}</div>
              <div className="text-sm text-pink-600">💕 Üreme</div>
            </div>
            <div className="text-center p-3 bg-orange-50 rounded-lg">
              <div className="text-2xl font-bold text-orange-600">{dataStats.eggs}</div>
              <div className="text-sm text-orange-600">🥚 Yumurtalar</div>
            </div>
            <div className="text-center p-3 bg-red-50 rounded-lg">
              <div className="text-2xl font-bold text-red-600">{dataStats.incubations}</div>
              <div className="text-sm text-red-600">🔥 Kuluçka</div>
            </div>
            <div className="text-center p-3 bg-gray-50 rounded-lg">
              <div className="text-2xl font-bold text-gray-600">{dataStats.total}</div>
              <div className="text-sm text-gray-600">📊 Toplam</div>
            </div>
          </div>
          
          <div className="mt-4 p-3 bg-muted rounded-lg">
            <div className="flex items-center justify-between text-sm">
              <span>Tahmini Veri Boyutu:</span>
              <Badge variant="outline">{dataStats.estimatedSize} KB</Badge>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Quick Export/Import */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <FileText className="w-5 h-5" />
            Hızlı Dışa/İçe Aktarım
          </CardTitle>
          <CardDescription>
            Verilerinizi tek tıkla dışa aktarın veya içe aktarın
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Quick Export */}
          <div className="flex flex-col sm:flex-row gap-2">
            <Button 
              onClick={handleQuickExportJSON}
              disabled={isProcessing || dataStats.total === 0}
              className="flex-1 gap-2"
              variant="outline"
            >
              <Download className="w-4 h-4" />
              JSON Dışa Aktar
            </Button>
            <Button 
              onClick={handleQuickExportCSV}
              disabled={isProcessing || dataStats.total === 0}
              className="flex-1 gap-2"
              variant="outline"
            >
              <Download className="w-4 h-4" />
              CSV Dışa Aktar
            </Button>
          </div>

          {/* Export Progress */}
          {isExporting && (
            <div className="space-y-2">
              <div className="flex items-center justify-between text-sm">
                <span>Dışa aktarılıyor...</span>
                <span>{exportProgress}%</span>
              </div>
              <Progress value={exportProgress} className="h-2" />
            </div>
          )}

          {/* Import Progress */}
          {isImporting && (
            <div className="space-y-2">
              <div className="flex items-center justify-between text-sm">
                <span>İçe aktarılıyor...</span>
                <span>{importProgress}%</span>
              </div>
              <Progress value={importProgress} className="h-2" />
            </div>
          )}

          {dataStats.total === 0 && (
            <Alert>
              <Info className="h-4 w-4" />
              <AlertDescription>
                Henüz dışa aktarılacak veri yok. Önce kuş, yavru veya diğer verileri ekleyin.
              </AlertDescription>
            </Alert>
          )}
        </CardContent>
      </Card>

      {/* Advanced Export/Import */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Database className="w-5 h-5" />
            Gelişmiş Veri İşlemleri
          </CardTitle>
          <CardDescription>
            Detaylı seçeneklerle veri yönetimi
          </CardDescription>
        </CardHeader>
        <CardContent>
          <DataExportImport
            birds={birds}
            chicks={chicks}
            breeding={breeding}
            eggs={eggs}
            incubations={incubations}
            onDataImport={onDataImport}
          />
        </CardContent>
      </Card>

      {/* Data Cleanup */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Trash2 className="w-5 h-5 text-destructive" />
            Veri Temizleme
          </CardTitle>
          <CardDescription>
            Tüm verileri silme ve sıfırlama işlemleri
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <Alert variant="destructive">
            <AlertTriangle className="h-4 w-4" />
            <AlertDescription>
              <strong>Dikkat:</strong> Bu işlemler geri alınamaz. Verilerinizi silmeden önce mutlaka yedek alın.
            </AlertDescription>
          </Alert>

          <div className="space-y-3">
            {!showClearConfirm ? (
              <Button 
                variant="destructive" 
                onClick={() => setShowClearConfirm(true)}
                disabled={dataStats.total === 0}
                className="gap-2"
              >
                <Trash2 className="w-4 h-4" />
                Tüm Verileri Sil
              </Button>
            ) : (
              <div className="space-y-3 p-4 border border-destructive rounded-lg bg-destructive/5">
                <div className="space-y-2">
                  <h4 className="font-medium text-destructive">Tüm verileri silmek istediğinizden emin misiniz?</h4>
                  <p className="text-sm text-muted-foreground">
                    Bu işlem aşağıdaki tüm verileri kalıcı olarak silecektir:
                  </p>
                  <ul className="text-sm text-muted-foreground list-disc list-inside space-y-1">
                    <li>{dataStats.birds} Kuş</li>
                    <li>{dataStats.chicks} Yavru</li>
                    <li>{dataStats.breeding} Üreme kaydı</li>
                    <li>{dataStats.eggs} Yumurta</li>
                    <li>{dataStats.incubations} Kuluçka kaydı</li>
                  </ul>
                </div>
                
                <div className="flex gap-2">
                  <Button 
                    variant="destructive" 
                    onClick={handleDataClear}
                    disabled={!onDataClear}
                    className="gap-2"
                  >
                    <Trash2 className="w-4 h-4" />
                    Evet, Tümünü Sil
                  </Button>
                  <Button 
                    variant="outline" 
                    onClick={() => setShowClearConfirm(false)}
                  >
                    İptal
                  </Button>
                </div>
              </div>
            )}
          </div>

          {dataStats.total === 0 && (
            <Alert>
              <Info className="h-4 w-4" />
              <AlertDescription>
                Silinecek veri yok. Veritabanınız zaten temiz.
              </AlertDescription>
            </Alert>
          )}
        </CardContent>
      </Card>

      {/* Tips */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Info className="w-5 h-5" />
            Veri Yönetimi İpuçları
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-3 text-sm text-muted-foreground">
          <div className="flex items-start gap-2">
            <div className="w-1.5 h-1.5 bg-primary rounded-full mt-2 flex-shrink-0"></div>
            <p>{t('common.regularBackup')}</p>
          </div>
          <div className="flex items-start gap-2">
            <div className="w-1.5 h-1.5 bg-primary rounded-full mt-2 flex-shrink-0"></div>
            <p>CSV formatı Excel ve diğer elektronik tablolarla uyumludur.</p>
          </div>
          <div className="flex items-start gap-2">
            <div className="w-1.5 h-1.5 bg-primary rounded-full mt-2 flex-shrink-0"></div>
            <p>JSON formatı tüm verilerinizi tam olarak korur ve geri yükleme için idealdir.</p>
          </div>
          <div className="flex items-start gap-2">
            <div className="w-1.5 h-1.5 bg-primary rounded-full mt-2 flex-shrink-0"></div>
            <p>İçe aktarım işlemi mevcut verilerinizi korur, sadece yeni veriler ekler.</p>
          </div>
          <div className="flex items-start gap-2">
            <div className="w-1.5 h-1.5 bg-primary rounded-full mt-2 flex-shrink-0"></div>
            <p>Büyük veri setleri için daha iyi performans için verileri filtreleyerek dışa aktarın.</p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default DataManagementSettings; 