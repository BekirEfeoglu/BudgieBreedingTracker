import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Checkbox } from '@/components/ui/checkbox';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { Download, FileText, BarChart3, Calendar, Users, Database, CheckCircle, AlertCircle } from 'lucide-react';

interface ExportOptions {
  format: 'csv' | 'excel' | 'pdf' | 'json';
  dataTypes: {
    birds: boolean;
    chicks: boolean;
    eggs: boolean;
    breeding: boolean;
    incubations: boolean;
    analytics: boolean;
  };
  timeRange: '7d' | '30d' | '90d' | '1y' | 'all';
  includeCharts: boolean;
  includeSummary: boolean;
}

interface DataExportProps {
  onExport: (options: ExportOptions) => Promise<void>;
  isExporting: boolean;
  exportProgress: number;
}

const DataExport: React.FC<DataExportProps> = ({
  onExport,
  isExporting,
  exportProgress
}) => {
  const [options, setOptions] = useState<ExportOptions>({
    format: 'csv',
    dataTypes: {
      birds: true,
      chicks: true,
      eggs: true,
      breeding: true,
      incubations: true,
      analytics: true
    },
    timeRange: '30d',
    includeCharts: false,
    includeSummary: true
  });

  const updateOption = (key: keyof ExportOptions, value: any) => {
    setOptions(prev => ({
      ...prev,
      [key]: value
    }));
  };

  const updateDataType = (type: keyof ExportOptions['dataTypes'], value: boolean) => {
    setOptions(prev => ({
      ...prev,
      dataTypes: {
        ...prev.dataTypes,
        [type]: value
      }
    }));
  };

  const getSelectedDataTypesCount = () => {
    return Object.values(options.dataTypes).filter(Boolean).length;
  };

  const getFormatInfo = (format: string) => {
    switch (format) {
      case 'csv':
        return { icon: FileText, description: 'Excel ile uyumlu, basit tablo formatı' };
      case 'excel':
        return { icon: BarChart3, description: 'Grafikler ve formatlamalar dahil' };
      case 'pdf':
        return { icon: FileText, description: 'Yazdırılabilir rapor formatı' };
      case 'json':
        return { icon: Database, description: 'Programatik kullanım için' };
      default:
        return { icon: FileText, description: '' };
    }
  };

  const formatInfo = getFormatInfo(options.format);

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Download className="w-5 h-5" />
          Veri Dışa Aktarma
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-6">
          {/* Format Seçimi */}
          <div className="space-y-3">
            <Label>Dosya Formatı</Label>
            <Select 
              value={options.format} 
              onValueChange={(value: 'csv' | 'excel' | 'pdf' | 'json') => updateOption('format', value)}
            >
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="csv">CSV (.csv)</SelectItem>
                <SelectItem value="excel">Excel (.xlsx)</SelectItem>
                <SelectItem value="pdf">PDF (.pdf)</SelectItem>
                <SelectItem value="json">JSON (.json)</SelectItem>
              </SelectContent>
            </Select>
            <div className="flex items-center gap-2 p-3 bg-gray-50 rounded-lg">
              <formatInfo.icon className="w-4 h-4 text-gray-600" />
              <span className="text-sm text-gray-600">{formatInfo.description}</span>
            </div>
          </div>

          {/* Zaman Aralığı */}
          <div className="space-y-3">
            <Label>Zaman Aralığı</Label>
            <Select 
              value={options.timeRange} 
              onValueChange={(value: '7d' | '30d' | '90d' | '1y' | 'all') => updateOption('timeRange', value)}
            >
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="7d">Son 7 gün</SelectItem>
                <SelectItem value="30d">Son 30 gün</SelectItem>
                <SelectItem value="90d">Son 90 gün</SelectItem>
                <SelectItem value="1y">Son 1 yıl</SelectItem>
                <SelectItem value="all">Tüm veriler</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {/* Veri Türleri */}
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <Label>Veri Türleri</Label>
              <Badge variant="secondary">
                {getSelectedDataTypesCount()} seçili
              </Badge>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="birds"
                  checked={options.dataTypes.birds}
                  onCheckedChange={(checked) => updateDataType('birds', checked as boolean)}
                />
                <Label htmlFor="birds" className="flex items-center gap-2">
                  <Users className="w-4 h-4" />
                  Kuşlar
                </Label>
              </div>
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="chicks"
                  checked={options.dataTypes.chicks}
                  onCheckedChange={(checked) => updateDataType('chicks', checked as boolean)}
                />
                <Label htmlFor="chicks" className="flex items-center gap-2">
                  <Users className="w-4 h-4" />
                  Yavrular
                </Label>
              </div>
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="eggs"
                  checked={options.dataTypes.eggs}
                  onCheckedChange={(checked) => updateDataType('eggs', checked as boolean)}
                />
                <Label htmlFor="eggs" className="flex items-center gap-2">
                  <Calendar className="w-4 h-4" />
                  Yumurtalar
                </Label>
              </div>
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="breeding"
                  checked={options.dataTypes.breeding}
                  onCheckedChange={(checked) => updateDataType('breeding', checked as boolean)}
                />
                <Label htmlFor="breeding" className="flex items-center gap-2">
                  <Users className="w-4 h-4" />
                  Üreme Kayıtları
                </Label>
              </div>
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="incubations"
                  checked={options.dataTypes.incubations}
                  onCheckedChange={(checked) => updateDataType('incubations', checked as boolean)}
                />
                <Label htmlFor="incubations" className="flex items-center gap-2">
                  <Calendar className="w-4 h-4" />
                  Kuluçka Kayıtları
                </Label>
              </div>
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="analytics"
                  checked={options.dataTypes.analytics}
                  onCheckedChange={(checked) => updateDataType('analytics', checked as boolean)}
                />
                <Label htmlFor="analytics" className="flex items-center gap-2">
                  <BarChart3 className="w-4 h-4" />
                  Analiz Verileri
                </Label>
              </div>
            </div>
          </div>

          {/* Ek Seçenekler */}
          <div className="space-y-3">
            <Label>Ek Seçenekler</Label>
            <div className="space-y-2">
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="includeCharts"
                  checked={options.includeCharts}
                  onCheckedChange={(checked) => updateOption('includeCharts', checked)}
                />
                <Label htmlFor="includeCharts">Grafikleri dahil et (Excel/PDF)</Label>
              </div>
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="includeSummary"
                  checked={options.includeSummary}
                  onCheckedChange={(checked) => updateOption('includeSummary', checked)}
                />
                <Label htmlFor="includeSummary">Özet raporu dahil et</Label>
              </div>
            </div>
          </div>

          {/* İlerleme */}
          {isExporting && (
            <div className="space-y-2">
              <div className="flex items-center gap-2">
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-blue-500"></div>
                <span className="text-sm">Dışa aktarılıyor...</span>
              </div>
              <Progress value={exportProgress} className="h-2" />
              <span className="text-xs text-gray-600">%{exportProgress} tamamlandı</span>
            </div>
          )}

          {/* Dışa Aktarma Butonu */}
          <Button
            onClick={() => onExport(options)}
            disabled={isExporting || getSelectedDataTypesCount() === 0}
            className="w-full"
            size="lg"
          >
            {isExporting ? (
              <>
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                Dışa Aktarılıyor...
              </>
            ) : (
              <>
                <Download className="w-4 h-4 mr-2" />
                Veriyi Dışa Aktar
              </>
            )}
          </Button>

          {/* Bilgi Kartı */}
          <div className="p-4 bg-blue-50 rounded-lg">
            <div className="flex items-start gap-3">
              <CheckCircle className="w-5 h-5 text-blue-600 mt-0.5" />
              <div className="text-sm text-blue-800">
                <div className="font-medium mb-1">Dışa Aktarma Hakkında</div>
                <ul className="space-y-1 text-xs">
                  <li>• CSV formatı Excel ile uyumludur</li>
                  <li>• Excel formatı grafikleri ve formatlamaları içerir</li>
                  <li>• PDF formatı yazdırılabilir raporlar oluşturur</li>
                  <li>• JSON formatı programatik kullanım içindir</li>
                  <li>• Büyük veri setleri için işlem süresi uzayabilir</li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
};

export default DataExport; 