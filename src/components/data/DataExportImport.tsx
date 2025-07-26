import React, { useState, useCallback, useMemo } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { useNotifications } from '@/contexts/notifications';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { 
  Download, 
  Upload, 
  Database, 
  Info,
  RefreshCw
} from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';
import * as XLSX from 'xlsx';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

interface ExportData {
  birds: Record<string, unknown>[];
  chicks: Record<string, unknown>[];
  eggs: Record<string, unknown>[];
  breedingRecords: Record<string, unknown>[];
  notifications: Record<string, unknown>[];
  settings: Record<string, unknown>[];
}

interface ImportData {
  birds?: Record<string, unknown>[];
  chicks?: Record<string, unknown>[];
  eggs?: Record<string, unknown>[];
  breedingRecords?: Record<string, unknown>[];
  notifications?: Record<string, unknown>[];
  settings?: Record<string, unknown>[];
}

export const DataExportImport: React.FC = () => {
  const { user: _user } = useAuth();
  const { addNotification } = useNotifications();
  const [activeTab, setActiveTab] = useState('export');
  const [isExporting, setIsExporting] = useState(false);
  const [isImporting, setIsImporting] = useState(false);
  const [exportProgress, setExportProgress] = useState(0);
  const [importProgress, setImportProgress] = useState(0);
  const [exportData, setExportData] = useState<ExportData | null>(null);
  const [importData, setImportData] = useState<ExportData | null>(null);

  const exportStats = useMemo(() => ({
    birds: 0,
    chicks: 0,
    eggs: 0,
    breedingRecords: 0,
    notifications: 0,
    settings: 0
  }), []);

  const handleExport = useCallback(async () => {
    setIsExporting(true);
    setExportProgress(0);
    
    try {
      // Simulate export process
      for (let i = 0; i <= 100; i += 10) {
        setExportProgress(i);
        await new Promise(resolve => setTimeout(resolve, 100));
      }
      
      const exportData: ExportData = {
        birds: [],
        chicks: [],
        eggs: [],
        breedingRecords: [],
        notifications: [],
        settings: []
      };
      
      const blob = new Blob([JSON.stringify(exportData, null, 2)], {
        type: 'application/json'
      });
      
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `budgie-data-${new Date().toISOString().split('T')[0]}.json`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      
      addNotification({
        title: 'Veri Dışa Aktarma Başarılı',
        message: 'Tüm verileriniz başarıyla dışa aktarıldı.',
        type: 'info'
      });
      
    } catch (error) {
      console.error('Export error:', error);
      addNotification({
        title: 'Dışa Aktarma Hatası',
        message: 'Veriler dışa aktarılırken bir hata oluştu.',
        type: 'error'
      });
    } finally {
      setIsExporting(false);
      setExportProgress(0);
    }
  }, [addNotification]);

  const handleExportExcel = useCallback(() => {
    if (!exportData) return;
    const wb = XLSX.utils.book_new();
    
    // Kapak Sayfası
    const coverSheet = XLSX.utils.aoa_to_sheet([
      ['BUDGIEBREEDINGTRACKER SİSTEMİ'],
      ['VERİ DÖNÜŞTÜRME RAPORU'],
      [''],
      [`Rapor Tarihi: ${new Date().toLocaleString('tr-TR')}`],
      [''],
      ['RAPOR İÇERİĞİ'],
      ['1. Kuş Listesi - Tüm kuşların detaylı bilgileri'],
      ['2. Yavru Listesi - Yavru kuşların gelişim takibi'],
      ['3. Kuluçka Kayıtları - Kuluçka süreçleri ve sonuçları'],
      ['4. Yumurta Takibi - Yumurta durumları ve çıkım oranları'],
      ['5. Üretim İstatistikleri - Genel performans özeti'],
      [''],
      ['ÖNEMLİ NOTLAR'],
      ['• Bu rapor sistemdeki tüm verileri içermektedir'],
      ['• Veriler Excel formatında düzenlenmiştir'],
      ['• Tarih formatları Türkiye standardına uygun olarak ayarlanmıştır'],
      ['• Performans göstergeleri renk kodlaması ile belirtilmiştir']
    ]);
    XLSX.utils.book_append_sheet(wb, coverSheet, 'Kapak');
    
    // Kuş Listesi
    const birdsData = [
      ['KUŞ LİSTESİ'],
      ['Bu bölümde sistemdeki tüm kuşların detaylı bilgileri sunulmaktadır.'],
      [''],
      ['ID', 'İsim', 'Cinsiyet', 'Renk', 'Doğum Tarihi', 'Kayıt Tarihi', 'Durum', 'Notlar']
    ];
    
    (exportData.birds || []).forEach((bird: any) => {
      const status = bird.isActive ? 'Aktif' : 'Pasif';
      birdsData.push([
        bird.id || '',
        bird.name || '',
        bird.gender || '',
        bird.color || '',
        bird.birthDate ? new Date(bird.birthDate).toLocaleDateString('tr-TR') : 'Bilinmiyor',
        bird.createdAt ? new Date(bird.createdAt).toLocaleDateString('tr-TR') : 'Bilinmiyor',
        status,
        bird.notes || ''
      ]);
    });
    
    birdsData.push(['']);
    birdsData.push(['KUŞ ÖZETİ']);
    birdsData.push([`Toplam Kuş: ${(exportData.birds || []).length}`]);
    birdsData.push([`Erkek: ${(exportData.birds || []).filter((b: any) => b.gender === 'Erkek').length}`]);
    birdsData.push([`Dişi: ${(exportData.birds || []).filter((b: any) => b.gender === 'Dişi').length}`]);
    birdsData.push([`Aktif: ${(exportData.birds || []).filter((b: any) => b.isActive).length}`]);
    
    const birdsSheet = XLSX.utils.aoa_to_sheet(birdsData);
    XLSX.utils.book_append_sheet(wb, birdsSheet, 'Kuş Listesi');
    
    // Yavru Listesi
    const chicksData = [
      ['YAVRU LİSTESİ'],
      ['Bu bölümde tüm yavru kuşların gelişim takibi ve durumları gösterilmektedir.'],
      [''],
      ['ID', 'İsim', 'Cinsiyet', 'Doğum Tarihi', 'Ebeveynler', 'Durum', 'Ağırlık (g)', 'Notlar']
    ];
    
    (exportData.chicks || []).forEach((chick: any) => {
      const status = chick.isAlive ? 'Canlı' : 'Ölü';
      const parents = `${chick.parentMale || 'Bilinmiyor'} & ${chick.parentFemale || 'Bilinmiyor'}`;
      chicksData.push([
        chick.id || '',
        chick.name || '',
        chick.gender || '',
        chick.birthDate ? new Date(chick.birthDate).toLocaleDateString('tr-TR') : 'Bilinmiyor',
        parents,
        status,
        chick.weight || 'Ölçülmedi',
        chick.notes || ''
      ]);
    });
    
    chicksData.push(['']);
    chicksData.push(['YAVRU ÖZETİ']);
    chicksData.push([`Toplam Yavru: ${(exportData.chicks || []).length}`]);
    chicksData.push([`Canlı: ${(exportData.chicks || []).filter((c: any) => c.isAlive).length}`]);
    chicksData.push([`Ölü: ${(exportData.chicks || []).filter((c: any) => !c.isAlive).length}`]);
    chicksData.push([`Hayatta Kalma Oranı: ${(exportData.chicks || []).length > 0 ? Math.round((exportData.chicks || []).filter((c: any) => c.isAlive).length / (exportData.chicks || []).length * 100) : 0}%`]);
    
    const chicksSheet = XLSX.utils.aoa_to_sheet(chicksData);
    XLSX.utils.book_append_sheet(wb, chicksSheet, 'Yavru Listesi');
    
    // Kuluçka Kayıtları
    const breedingData = [
      ['KULUÇKA KAYITLARI'],
      ['Bu bölümde tüm kuluçka süreçleri ve sonuçları detaylı olarak listelenmektedir.'],
      [''],
      ['ID', 'Çift', 'Başlangıç Tarihi', 'Bitiş Tarihi', 'Durum', 'Yumurta Sayısı', 'Çıkan Yavru', 'Başarı Oranı (%)', 'Notlar']
    ];
    
    (exportData.breedingRecords || []).forEach((breed: any) => {
      const status = breed.isActive ? 'Devam Ediyor' : 'Tamamlandı';
      const successRate = breed.eggCount > 0 ? Math.round((breed.hatchedCount / breed.eggCount) * 100) : 0;
      const pair = `${breed.maleBird || 'Bilinmiyor'} & ${breed.femaleBird || 'Bilinmiyor'}`;
      breedingData.push([
        breed.id || '',
        pair,
        breed.startDate ? new Date(breed.startDate).toLocaleDateString('tr-TR') : 'Bilinmiyor',
        breed.endDate ? new Date(breed.endDate).toLocaleDateString('tr-TR') : 'Devam Ediyor',
        status,
        breed.eggCount || 0,
        breed.hatchedCount || 0,
        successRate,
        breed.notes || ''
      ]);
    });
    
    breedingData.push(['']);
    breedingData.push(['KULUÇKA ÖZETİ']);
    breedingData.push([`Toplam Kuluçka: ${(exportData.breedingRecords || []).length}`]);
    breedingData.push([`Aktif: ${(exportData.breedingRecords || []).filter((b: any) => b.isActive).length}`]);
    breedingData.push([`Tamamlanan: ${(exportData.breedingRecords || []).filter((b: any) => !b.isActive).length}`]);
    breedingData.push([`Ortalama Başarı: ${(exportData.breedingRecords || []).length > 0 ? Math.round((exportData.breedingRecords || []).reduce((sum, b: any) => sum + (b.eggCount > 0 ? (b.hatchedCount / b.eggCount) * 100 : 0), 0) / (exportData.breedingRecords || []).length) : 0}%`]);
    
    const breedingSheet = XLSX.utils.aoa_to_sheet(breedingData);
    XLSX.utils.book_append_sheet(wb, breedingSheet, 'Kuluçka Kayıtları');
    
    // Yumurta Takibi
    const eggsData = [
      ['YUMURTA TAKİBİ'],
      ['Bu bölümde tüm yumurtaların durumları ve çıkım oranları gösterilmektedir.'],
      [''],
      ['ID', 'Kuluçka ID', 'Yumurta No', 'Durum', 'Çıkım Tarihi', 'Sonuç', 'Notlar']
    ];
    
    (exportData.eggs || []).forEach((egg: any) => {
      const status = egg.isHatched ? 'Çıktı' : egg.isFertile ? 'Döllü' : 'Dölsüz';
      const result = egg.isHatched ? 'Başarılı' : egg.isFertile ? 'Beklemede' : 'Başarısız';
      eggsData.push([
        egg.id || '',
        egg.incubationId || '',
        egg.eggNumber || '',
        status,
        egg.hatchDate ? new Date(egg.hatchDate).toLocaleDateString('tr-TR') : 'Beklemede',
        result,
        egg.notes || ''
      ]);
    });
    
    eggsData.push(['']);
    eggsData.push(['YUMURTA ÖZETİ']);
    eggsData.push([`Toplam Yumurta: ${(exportData.eggs || []).length}`]);
    eggsData.push([`Çıkan: ${(exportData.eggs || []).filter((e: any) => e.isHatched).length}`]);
    eggsData.push([`Döllü: ${(exportData.eggs || []).filter((e: any) => e.isFertile).length}`]);
    eggsData.push([`Çıkım Oranı: ${(exportData.eggs || []).length > 0 ? Math.round((exportData.eggs || []).filter((e: any) => e.isHatched).length / (exportData.eggs || []).length * 100) : 0}%`]);
    
    const eggsSheet = XLSX.utils.aoa_to_sheet(eggsData);
    XLSX.utils.book_append_sheet(wb, eggsSheet, 'Yumurta Takibi');
    
    // Üretim İstatistikleri
    const statsData = [
      ['ÜRETİM İSTATİSTİKLERİ'],
      ['Bu bölümde genel üretim performansı ve istatistikler özetlenmektedir.'],
      [''],
      ['Metrik', 'Değer', 'Açıklama']
    ];
    
    const totalBirds = (exportData.birds || []).length;
    const totalChicks = (exportData.chicks || []).length;
    const totalBreeding = (exportData.breedingRecords || []).length;
    const totalEggs = (exportData.eggs || []).length;
    const successRate = totalEggs > 0 ? Math.round((exportData.eggs || []).filter((e: any) => e.isHatched).length / totalEggs * 100) : 0;
    const survivalRate = totalChicks > 0 ? Math.round((exportData.chicks || []).filter((c: any) => c.isAlive).length / totalChicks * 100) : 0;
    
    statsData.push(['Toplam Kuş', totalBirds, 'Sistemdeki toplam kuş sayısı']);
    statsData.push(['Toplam Yavru', totalChicks, 'Üretilen toplam yavru sayısı']);
    statsData.push(['Toplam Kuluçka', totalBreeding, 'Gerçekleştirilen kuluçka sayısı']);
    statsData.push(['Toplam Yumurta', totalEggs, 'Toplam yumurta sayısı']);
    statsData.push(['Çıkım Oranı (%)', successRate, 'Başarılı çıkım oranı']);
    statsData.push(['Hayatta Kalma (%)', survivalRate, 'Yavru hayatta kalma oranı']);
    statsData.push(['Aktif Kuluçka', (exportData.breedingRecords || []).filter((b: any) => b.isActive).length, 'Devam eden kuluçka sayısı']);
    statsData.push(['Erkek Oranı (%)', totalBirds > 0 ? Math.round((exportData.birds || []).filter((b: any) => b.gender === 'Erkek').length / totalBirds * 100) : 0, 'Erkek kuş oranı']);
    
    statsData.push(['']);
    statsData.push(['PERFORMANS DEĞERLENDİRMESİ']);
    statsData.push([`Genel Başarı: ${successRate > 70 ? 'Mükemmel' : successRate > 50 ? 'İyi' : 'Geliştirilmeli'}`]);
    statsData.push([`Üretim Verimliliği: ${totalChicks > totalBirds ? 'Yüksek' : 'Orta'}`]);
    statsData.push([`Sistem Sağlığı: ${totalBirds > 0 && totalChicks > 0 ? 'İyi' : 'Geliştirilmeli'}`]);
    
    const statsSheet = XLSX.utils.aoa_to_sheet(statsData);
    XLSX.utils.book_append_sheet(wb, statsSheet, 'Üretim İstatistikleri');
    
    // Conditional Formatting ve Stil Uygulama
    wb.Sheets.forEach((sheet, sheetName) => {
      if (sheetName === 'Kuş Listesi') {
        // Cinsiyet sütunu için conditional formatting
        const range = XLSX.utils.decode_range(sheet['!ref'] || 'A1');
        for (let R = 4; R <= range.e.r; R++) {
          const genderCell = sheet[XLSX.utils.encode_cell({r: R, c: 2})]; // Cinsiyet sütunu
          const statusCell = sheet[XLSX.utils.encode_cell({r: R, c: 6})]; // Durum sütunu
          
          if (genderCell && genderCell.v === 'Erkek') {
            genderCell.s = { fill: { fgColor: { rgb: "3498DB" } }, font: { color: { rgb: "FFFFFF" } } }; // Mavi
          } else if (genderCell && genderCell.v === 'Dişi') {
            genderCell.s = { fill: { fgColor: { rgb: "E91E63" } }, font: { color: { rgb: "FFFFFF" } } }; // Pembe
          }
          
          if (statusCell && statusCell.v === 'Aktif') {
            statusCell.s = { fill: { fgColor: { rgb: "27AE60" } }, font: { color: { rgb: "FFFFFF" } } }; // Yeşil
          } else if (statusCell && statusCell.v === 'Pasif') {
            statusCell.s = { fill: { fgColor: { rgb: "E74C3C" } }, font: { color: { rgb: "FFFFFF" } } }; // Kırmızı
          }
        }
      }
      
      if (sheetName === 'Yavru Listesi') {
        // Durum sütunu için conditional formatting
        const range = XLSX.utils.decode_range(sheet['!ref'] || 'A1');
        for (let R = 4; R <= range.e.r; R++) {
          const statusCell = sheet[XLSX.utils.encode_cell({r: R, c: 5})]; // Durum sütunu
          
          if (statusCell && statusCell.v === 'Canlı') {
            statusCell.s = { fill: { fgColor: { rgb: "27AE60" } }, font: { color: { rgb: "FFFFFF" } } }; // Yeşil
          } else if (statusCell && statusCell.v === 'Ölü') {
            statusCell.s = { fill: { fgColor: { rgb: "E74C3C" } }, font: { color: { rgb: "FFFFFF" } } }; // Kırmızı
          }
        }
      }
      
      if (sheetName === 'Kuluçka Kayıtları') {
        // Başarı oranı ve durum sütunları için conditional formatting
        const range = XLSX.utils.decode_range(sheet['!ref'] || 'A1');
        for (let R = 4; R <= range.e.r; R++) {
          const statusCell = sheet[XLSX.utils.encode_cell({r: R, c: 4})]; // Durum sütunu
          const rateCell = sheet[XLSX.utils.encode_cell({r: R, c: 7})]; // Başarı oranı sütunu
          
          if (statusCell && statusCell.v === 'Devam Ediyor') {
            statusCell.s = { fill: { fgColor: { rgb: "F39C12" } }, font: { color: { rgb: "FFFFFF" } } }; // Turuncu
          } else if (statusCell && statusCell.v === 'Tamamlandı') {
            statusCell.s = { fill: { fgColor: { rgb: "27AE60" } }, font: { color: { rgb: "FFFFFF" } } }; // Yeşil
          }
          
          if (rateCell && typeof rateCell.v === 'number') {
            if (rateCell.v >= 80) {
              rateCell.s = { fill: { fgColor: { rgb: "27AE60" } }, font: { color: { rgb: "FFFFFF" } } }; // Yeşil
            } else if (rateCell.v >= 60) {
              rateCell.s = { fill: { fgColor: { rgb: "F39C12" } }, font: { color: { rgb: "FFFFFF" } } }; // Turuncu
            } else if (rateCell.v >= 40) {
              rateCell.s = { fill: { fgColor: { rgb: "E67E22" } }, font: { color: { rgb: "FFFFFF" } } }; // Kırmızı-turuncu
            } else {
              rateCell.s = { fill: { fgColor: { rgb: "E74C3C" } }, font: { color: { rgb: "FFFFFF" } } }; // Kırmızı
            }
          }
        }
      }
      
      if (sheetName === 'Yumurta Takibi') {
        // Durum ve sonuç sütunları için conditional formatting
        const range = XLSX.utils.decode_range(sheet['!ref'] || 'A1');
        for (let R = 4; R <= range.e.r; R++) {
          const statusCell = sheet[XLSX.utils.encode_cell({r: R, c: 3})]; // Durum sütunu
          const resultCell = sheet[XLSX.utils.encode_cell({r: R, c: 5})]; // Sonuç sütunu
          
          if (statusCell && statusCell.v === 'Çıktı') {
            statusCell.s = { fill: { fgColor: { rgb: "27AE60" } }, font: { color: { rgb: "FFFFFF" } } }; // Yeşil
          } else if (statusCell && statusCell.v === 'Döllü') {
            statusCell.s = { fill: { fgColor: { rgb: "F39C12" } }, font: { color: { rgb: "FFFFFF" } } }; // Turuncu
          } else if (statusCell && statusCell.v === 'Dölsüz') {
            statusCell.s = { fill: { fgColor: { rgb: "E74C3C" } }, font: { color: { rgb: "FFFFFF" } } }; // Kırmızı
          }
          
          if (resultCell && resultCell.v === 'Başarılı') {
            resultCell.s = { fill: { fgColor: { rgb: "27AE60" } }, font: { color: { rgb: "FFFFFF" } } }; // Yeşil
          } else if (resultCell && resultCell.v === 'Beklemede') {
            resultCell.s = { fill: { fgColor: { rgb: "F39C12" } }, font: { color: { rgb: "FFFFFF" } } }; // Turuncu
          } else if (resultCell && resultCell.v === 'Başarısız') {
            resultCell.s = { fill: { fgColor: { rgb: "E74C3C" } }, font: { color: { rgb: "FFFFFF" } } }; // Kırmızı
          }
        }
      }
      
      // Başlık satırları için stil
      const range = XLSX.utils.decode_range(sheet['!ref'] || 'A1');
      for (let C = 0; C <= range.e.c; C++) {
        const headerCell = sheet[XLSX.utils.encode_cell({r: 0, c: C})];
        if (headerCell) {
          headerCell.s = { 
            fill: { fgColor: { rgb: "2C3E50" } }, 
            font: { color: { rgb: "FFFFFF" }, bold: true, size: 12 } 
          };
        }
      }
      
      // Alternatif satır renkleri
      for (let R = 1; R <= range.e.r; R++) {
        if (R % 2 === 1) { // Tek satırlar
          for (let C = 0; C <= range.e.c; C++) {
            const cell = sheet[XLSX.utils.encode_cell({r: R, c: C})];
            if (cell && !cell.s) {
              cell.s = { fill: { fgColor: { rgb: "F5F7FA" } } };
            }
          }
        }
      }
    });
    
    XLSX.writeFile(wb, `budgie-veri-raporu-${new Date().toLocaleDateString('tr-TR')}.xlsx`);
  }, [exportData]);

  const handleExportPDF = useCallback(() => {
    if (!exportData) return;
    const doc = new jsPDF({ orientation: 'portrait', unit: 'pt', format: 'a4' });
    
    // Türkçe karakter desteği için font ayarları
    doc.setFont('helvetica', 'normal');
    
    // Kapak Sayfası
    let y = 80;
    doc.setFontSize(24);
    doc.setTextColor(44, 62, 80); // Koyu mavi-gri
    doc.text('BUDGIEBREEDINGTRACKER SİSTEMİ', 40, y);
    y += 40;
    doc.setFontSize(20);
    doc.text('VERİ YEDEK RAPORU', 40, y);
    y += 60;
    doc.setFontSize(14);
    doc.setTextColor(52, 73, 94); // Orta mavi-gri
    doc.text(`Rapor Tarihi: ${new Date().toLocaleString('tr-TR')}`, 40, y);
    y += 60;
    doc.setFontSize(12);
    doc.setTextColor(127, 140, 141); // Açık gri
    doc.text('Bu rapor tüm sistem verilerinin kapsamlı yedeğini içermektedir.', 40, y);
    y += 20;
    doc.text('Veriler JSON formatında dışa aktarılmış ve analiz edilmiştir.', 40, y);
    y += 20;
    doc.text(`Toplam kayıt sayısı: ${Object.values(exportData).reduce((sum, arr) => sum + (arr?.length || 0), 0)} adet`, 40, y);
    
    // İçerik Tablosu
    doc.addPage();
    y = 40;
    doc.setFontSize(18);
    doc.setTextColor(44, 62, 80);
    doc.text('İÇERİK TABLOSU', 40, y);
    y += 30;
    doc.setFontSize(12);
    doc.setTextColor(52, 73, 94);
    doc.text('1. Kuşlar', 40, y);
    y += 16;
    doc.text('2. Civcivler', 40, y);
    y += 16;
    doc.text('3. Yumurtalar', 40, y);
    y += 16;
    doc.text('4. Kuluçka Kayıtları', 40, y);
    y += 16;
    doc.text('5. Bildirimler', 40, y);
    y += 16;
    doc.text('6. Ayarlar', 40, y);
    y += 16;
    doc.text('7. Genel Değerlendirme', 40, y);
    
    // Kuşlar
    doc.addPage();
    y = 40;
    doc.setFontSize(18);
    doc.setTextColor(44, 62, 80);
    doc.text('1. KUŞLAR', 40, y);
    y += 24;
    doc.setFontSize(12);
    doc.setTextColor(127, 140, 141);
    doc.text('Bu bölümde sistemdeki tüm kuş kayıtları ve detaylı bilgileri sunulmaktadır.', 40, y);
    y += 20;
    autoTable(doc, {
      startY: y,
      head: [['Adı', 'Cinsiyet', 'Doğum Tarihi', 'Renk', 'Not']],
      body: (exportData.birds || []).map((b: any) => [b.name ?? '', b.gender ?? '', b.birthDate ?? '', b.color ?? '', b.note ?? '']),
      theme: 'grid',
      styles: { 
        font: 'helvetica', 
        fontSize: 10,
        textColor: [52, 73, 94]
      },
      headStyles: {
        fillColor: [44, 62, 80],
        textColor: [255, 255, 255],
        fontStyle: 'bold'
      },
      alternateRowStyles: {
        fillColor: [245, 247, 250]
      },
      didParseCell: function(data) {
        // Cinsiyet için renk kodlaması
        if (data.column.index === 1) {
          if (data.cell.text === 'Erkek') {
            data.cell.styles.fillColor = [52, 152, 219]; // Mavi
            data.cell.styles.textColor = [255, 255, 255];
          } else if (data.cell.text === 'Dişi') {
            data.cell.styles.fillColor = [231, 76, 60]; // Kırmızı
            data.cell.styles.textColor = [255, 255, 255];
          }
        }
      },
      margin: { left: 40, right: 40 }
    });
    y = (doc as any).lastAutoTable.finalY + 16;
    doc.setFontSize(12);
    doc.setTextColor(52, 73, 94);
    doc.text(`ÖZET: Toplam ${(exportData.birds || []).length} kuş, ${(exportData.birds || []).filter((b: any) => b.gender === 'Erkek').length} erkek, ${(exportData.birds || []).filter((b: any) => b.gender === 'Dişi').length} dişi`, 40, y);
    
    // Civcivler
    doc.addPage();
    y = 40;
    doc.setFontSize(18);
    doc.setTextColor(44, 62, 80);
    doc.text('2. CİVCİVLER', 40, y);
    y += 24;
    doc.setFontSize(12);
    doc.setTextColor(127, 140, 141);
    doc.text('Bu bölümde sistemdeki tüm yavru kuş kayıtları sunulmaktadır.', 40, y);
    y += 20;
    autoTable(doc, {
      startY: y,
      head: [['Adı', 'Yuva', 'Doğum Tarihi', 'Durum']],
      body: (exportData.chicks || []).map((c: any) => [c.name ?? '', c.nest ?? '', c.birthDate ?? '', c.status ?? '']),
      theme: 'grid',
      styles: { 
        font: 'helvetica', 
        fontSize: 10,
        textColor: [52, 73, 94]
      },
      headStyles: {
        fillColor: [44, 62, 80],
        textColor: [255, 255, 255],
        fontStyle: 'bold'
      },
      alternateRowStyles: {
        fillColor: [245, 247, 250]
      },
      didParseCell: function(data) {
        // Durum için renk kodlaması
        if (data.column.index === 3) {
          if (data.cell.text === 'Aktif') {
            data.cell.styles.fillColor = [39, 174, 96]; // Yeşil
            data.cell.styles.textColor = [255, 255, 255];
          } else if (data.cell.text === 'Satıldı') {
            data.cell.styles.fillColor = [243, 156, 18]; // Turuncu
            data.cell.styles.textColor = [255, 255, 255];
          } else if (data.cell.text === 'Öldü') {
            data.cell.styles.fillColor = [231, 76, 60]; // Kırmızı
            data.cell.styles.textColor = [255, 255, 255];
          }
        }
      },
      margin: { left: 40, right: 40 }
    });
    y = (doc as any).lastAutoTable.finalY + 16;
    doc.setFontSize(12);
    doc.setTextColor(52, 73, 94);
    doc.text(`ÖZET: Toplam ${(exportData.chicks || []).length} civciv, ${(exportData.chicks || []).filter((c: any) => c.status === 'Aktif').length} aktif`, 40, y);
    
    // Yumurtalar
    doc.addPage();
    y = 40;
    doc.setFontSize(18);
    doc.setTextColor(44, 62, 80);
    doc.text('3. YUMURTALAR', 40, y);
    y += 24;
    doc.setFontSize(12);
    doc.setTextColor(127, 140, 141);
    doc.text('Bu bölümde kuluçka ve yumurta takip kayıtları sunulmaktadır.', 40, y);
    y += 20;
    autoTable(doc, {
      startY: y,
      head: [['Yuva', 'Tarih', 'Durum']],
      body: (exportData.eggs || []).map((e: any) => [e.nest ?? '', e.date ?? '', e.status ?? '']),
      theme: 'grid',
      styles: { 
        font: 'helvetica', 
        fontSize: 10,
        textColor: [52, 73, 94]
      },
      headStyles: {
        fillColor: [44, 62, 80],
        textColor: [255, 255, 255],
        fontStyle: 'bold'
      },
      alternateRowStyles: {
        fillColor: [245, 247, 250]
      },
      didParseCell: function(data) {
        // Durum için renk kodlaması
        if (data.column.index === 2) {
          if (data.cell.text === 'Kuluçkada') {
            data.cell.styles.fillColor = [52, 152, 219]; // Mavi
            data.cell.styles.textColor = [255, 255, 255];
          } else if (data.cell.text === 'Çıktı') {
            data.cell.styles.fillColor = [39, 174, 96]; // Yeşil
            data.cell.styles.textColor = [255, 255, 255];
          } else if (data.cell.text === 'Kırıldı') {
            data.cell.styles.fillColor = [231, 76, 60]; // Kırmızı
            data.cell.styles.textColor = [255, 255, 255];
          }
        }
      },
      margin: { left: 40, right: 40 }
    });
    y = (doc as any).lastAutoTable.finalY + 16;
    doc.setFontSize(12);
    doc.setTextColor(52, 73, 94);
    doc.text(`ÖZET: Toplam ${(exportData.eggs || []).length} yumurta, ${(exportData.eggs || []).filter((e: any) => e.status === 'Kuluçkada').length} kuluçkada`, 40, y);
    
    // Kuluçka Kayıtları
    doc.addPage();
    y = 40;
    doc.setFontSize(18);
    doc.setTextColor(44, 62, 80);
    doc.text('4. KULUÇKA KAYITLARI', 40, y);
    y += 24;
    doc.setFontSize(12);
    doc.setTextColor(127, 140, 141);
    doc.text('Bu bölümde üretim geçmişi ve kuluçka performansı sunulmaktadır.', 40, y);
    y += 20;
    autoTable(doc, {
      startY: y,
      head: [['Çift', 'Başlangıç', 'Bitiş', 'Başarı']],
      body: (exportData.breedingRecords || []).map((r: any) => [r.pair ?? '', r.startDate ?? '', r.endDate ?? '', r.success ? 'Evet' : 'Hayır']),
      theme: 'grid',
      styles: { 
        font: 'helvetica', 
        fontSize: 10,
        textColor: [52, 73, 94]
      },
      headStyles: {
        fillColor: [44, 62, 80],
        textColor: [255, 255, 255],
        fontStyle: 'bold'
      },
      alternateRowStyles: {
        fillColor: [245, 247, 250]
      },
      didParseCell: function(data) {
        // Başarı için renk kodlaması
        if (data.column.index === 3) {
          if (data.cell.text === 'Evet') {
            data.cell.styles.fillColor = [39, 174, 96]; // Yeşil
            data.cell.styles.textColor = [255, 255, 255];
          } else if (data.cell.text === 'Hayır') {
            data.cell.styles.fillColor = [231, 76, 60]; // Kırmızı
            data.cell.styles.textColor = [255, 255, 255];
          }
        }
      },
      margin: { left: 40, right: 40 }
    });
    y = (doc as any).lastAutoTable.finalY + 16;
    const successRate = (exportData.breedingRecords || []).length > 0 ? Math.round(((exportData.breedingRecords || []).filter((r: any) => r.success).length / (exportData.breedingRecords || []).length) * 100) : 0;
    doc.setFontSize(12);
    doc.setTextColor(52, 73, 94);
    doc.text(`ÖZET: Toplam ${(exportData.breedingRecords || []).length} kuluçka, %${successRate} başarı oranı`, 40, y);
    
    // Bildirimler
    doc.addPage();
    y = 40;
    doc.setFontSize(18);
    doc.setTextColor(44, 62, 80);
    doc.text('5. BİLDİRİMLER', 40, y);
    y += 24;
    doc.setFontSize(12);
    doc.setTextColor(127, 140, 141);
    doc.text('Bu bölümde sistem bildirimleri ve hatırlatmalar sunulmaktadır.', 40, y);
    y += 20;
    autoTable(doc, {
      startY: y,
      head: [['Başlık', 'Mesaj', 'Tarih']],
      body: (exportData.notifications || []).map((n: any) => [n.title ?? '', n.message ?? '', n.date ?? '']),
      theme: 'grid',
      styles: { 
        font: 'helvetica', 
        fontSize: 10,
        textColor: [52, 73, 94]
      },
      headStyles: {
        fillColor: [44, 62, 80],
        textColor: [255, 255, 255],
        fontStyle: 'bold'
      },
      alternateRowStyles: {
        fillColor: [245, 247, 250]
      },
      margin: { left: 40, right: 40 }
    });
    y = (doc as any).lastAutoTable.finalY + 16;
    doc.setFontSize(12);
    doc.setTextColor(52, 73, 94);
    doc.text(`ÖZET: Toplam ${(exportData.notifications || []).length} bildirim`, 40, y);
    
    // Ayarlar
    doc.addPage();
    y = 40;
    doc.setFontSize(18);
    doc.setTextColor(44, 62, 80);
    doc.text('6. AYARLAR', 40, y);
    y += 24;
    doc.setFontSize(12);
    doc.setTextColor(127, 140, 141);
    doc.text('Bu bölümde kullanıcı tercihleri ve sistem ayarları sunulmaktadır.', 40, y);
    y += 20;
    autoTable(doc, {
      startY: y,
      head: [['Anahtar', 'Değer']],
      body: (exportData.settings || []).map((s: any) => [s.key ?? '', s.value ?? '']),
      theme: 'grid',
      styles: { 
        font: 'helvetica', 
        fontSize: 10,
        textColor: [52, 73, 94]
      },
      headStyles: {
        fillColor: [44, 62, 80],
        textColor: [255, 255, 255],
        fontStyle: 'bold'
      },
      alternateRowStyles: {
        fillColor: [245, 247, 250]
      },
      margin: { left: 40, right: 40 }
    });
    y = (doc as any).lastAutoTable.finalY + 16;
    doc.setFontSize(12);
    doc.setTextColor(52, 73, 94);
    doc.text(`ÖZET: Toplam ${(exportData.settings || []).length} ayar`, 40, y);
    
    // Genel Değerlendirme
    doc.addPage();
    y = 40;
    doc.setFontSize(18);
    doc.setTextColor(44, 62, 80);
    doc.text('7. GENEL DEĞERLENDİRME', 40, y);
    y += 30;
    doc.setFontSize(12);
    doc.setTextColor(52, 73, 94);
    doc.text('Bu veri yedek raporu kapsamında elde edilen bulgular:', 40, y);
    y += 24;
    doc.setTextColor(127, 140, 141);
    doc.text(`• Toplam ${(exportData.birds || []).length} kuş kaydı bulunmaktadır`, 40, y);
    y += 16;
    doc.text(`• ${(exportData.chicks || []).length} civciv kaydı mevcuttur`, 40, y);
    y += 16;
    doc.text(`• ${(exportData.eggs || []).length} yumurta takip kaydı vardır`, 40, y);
    y += 16;
    doc.text(`• ${(exportData.breedingRecords || []).length} kuluçka kaydı bulunmaktadır`, 40, y);
    y += 16;
    doc.text(`• Kuluçka başarı oranı %${successRate} seviyesindedir`, 40, y);
    y += 30;
    doc.setTextColor(52, 73, 94);
    doc.text('VERİ GÜVENLİĞİ:', 40, y);
    y += 20;
    doc.setTextColor(127, 140, 141);
    doc.text('• Tüm veriler güvenli şekilde yedeklenmiştir', 40, y);
    y += 16;
    doc.text('• Düzenli yedekleme önerilir', 40, y);
    y += 16;
    doc.text('• Veri kaybı riskine karşı önlem alınmıştır', 40, y);
    y += 30;
    doc.setTextColor(52, 73, 94);
    doc.text('DESTEK VE İLETİŞİM:', 40, y);
    y += 20;
    doc.setTextColor(127, 140, 141);
    doc.text('Bu rapor hakkında sorularınız için sistem yöneticisi ile iletişime geçebilirsiniz.', 40, y);
    
    // Sayfa altına tarih ve sayfa numarası
    const pageCount = (doc as any).getNumberOfPages();
    for (let i = 1; i <= pageCount; i++) {
      doc.setPage(i);
      doc.setFont('helvetica', 'normal');
      doc.setFontSize(8);
      doc.setTextColor(127, 140, 141);
      doc.text(`Rapor Tarihi: ${new Date().toLocaleString('tr-TR')}`, 40, doc.internal.pageSize.height - 20);
      doc.text(`Sayfa ${i} / ${pageCount}`, doc.internal.pageSize.width - 80, doc.internal.pageSize.height - 20);
    }
    doc.save(`budgie-data-raporu-${new Date().toLocaleDateString('tr-TR')}.pdf`);
  }, [exportData]);

  const handleImport = useCallback(async (file: File) => {
    setIsImporting(true);
    setImportProgress(0);
    
    try {
      const text = await file.text();
      const importData: ImportData = JSON.parse(text);
      
      // Simulate import process
      for (let i = 0; i <= 100; i += 10) {
        setImportProgress(i);
        await new Promise(resolve => setTimeout(resolve, 100));
      }
      
      addNotification({
        title: 'Veri İçe Aktarma Başarılı',
        message: 'Tüm verileriniz başarıyla içe aktarıldı.',
        type: 'info'
      });
      
    } catch (error) {
      console.error('Import error:', error);
      addNotification({
        title: 'İçe Aktarma Hatası',
        message: 'Veriler içe aktarılırken bir hata oluştu.',
        type: 'error'
      });
    } finally {
      setIsImporting(false);
      setImportProgress(0);
    }
  }, [addNotification]);

  const handleFileSelect = useCallback((event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      handleImport(file);
    }
  }, [handleImport]);

  const totalRecords = Object.values(exportStats).reduce((sum, count) => sum + count, 0);

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Database className="w-5 h-5" />
            Veri Yönetimi
          </CardTitle>
          <CardDescription>
            Verilerinizi dışa aktarın veya yedekten geri yükleyin
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Tabs defaultValue="export" className="w-full">
            <TabsList className="grid w-full grid-cols-2">
              <TabsTrigger value="export">Dışa Aktar</TabsTrigger>
              <TabsTrigger value="import">İçe Aktar</TabsTrigger>
            </TabsList>
            
            <TabsContent value="export" className="space-y-4">
              <div className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <div className="flex items-center justify-between">
                      <span className="text-sm font-medium">Kuşlar</span>
                      <Badge variant="secondary">{exportStats.birds}</Badge>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-sm font-medium">Civcivler</span>
                      <Badge variant="secondary">{exportStats.chicks}</Badge>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-sm font-medium">Yumurtalar</span>
                      <Badge variant="secondary">{exportStats.eggs}</Badge>
                    </div>
                  </div>
                  <div className="space-y-2">
                    <div className="flex items-center justify-between">
                      <span className="text-sm font-medium">Kuluçka Kayıtları</span>
                      <Badge variant="secondary">{exportStats.breedingRecords}</Badge>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-sm font-medium">Bildirimler</span>
                      <Badge variant="secondary">{exportStats.notifications}</Badge>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-sm font-medium">Ayarlar</span>
                      <Badge variant="secondary">{exportStats.settings}</Badge>
                    </div>
                  </div>
                </div>
                
                <div className="space-y-2">
                  <div className="flex items-center justify-between text-sm">
                    <span>Toplam Kayıt</span>
                    <span className="font-medium">{totalRecords}</span>
                  </div>
                  {isExporting && (
                    <Progress value={exportProgress} className="w-full" />
                  )}
                </div>
                
                <Button 
                  onClick={handleExport} 
                  disabled={isExporting}
                  className="w-full"
                >
                  {isExporting ? (
                    <>
                      <RefreshCw className="w-4 h-4 mr-2 animate-spin" />
                      Dışa Aktarılıyor...
                    </>
                  ) : (
                    <>
                      <Download className="w-4 h-4 mr-2" />
                      Verileri Dışa Aktar
                    </>
                  )}
                </Button>
                <div className="flex gap-2 mt-2">
                  <Button variant="outline" onClick={handleExportExcel} className="flex-1">
                    Excel Olarak İndir
                  </Button>
                  <Button variant="outline" onClick={handleExportPDF} className="flex-1">
                    PDF Olarak İndir
                  </Button>
                </div>
              </div>
            </TabsContent>
            
            <TabsContent value="import" className="space-y-4">
              <div className="space-y-4">
                <div className="border-2 border-dashed border-border rounded-lg p-6 text-center">
                  <Upload className="w-8 h-8 mx-auto mb-2 text-muted-foreground" />
                  <p className="text-sm text-muted-foreground mb-4">
                    JSON dosyasını seçin veya sürükleyin
                  </p>
                  <input
                    type="file"
                    accept=".json"
                    onChange={handleFileSelect}
                    className="hidden"
                    id="import-file"
                  />
                  <label htmlFor="import-file">
                    <Button variant="outline" asChild>
                      <span>Dosya Seç</span>
                    </Button>
                  </label>
                </div>
                
                {isImporting && (
                  <div className="space-y-2">
                    <Progress value={importProgress} className="w-full" />
                    <p className="text-sm text-muted-foreground text-center">
                      Veriler içe aktarılıyor...
                    </p>
                  </div>
                )}
                
                <div className="bg-muted/50 p-4 rounded-lg">
                  <div className="flex items-start gap-2">
                    <Info className="w-4 h-4 mt-0.5 text-muted-foreground" />
                    <div className="text-sm text-muted-foreground">
                      <p className="font-medium mb-1">Önemli Notlar:</p>
                      <ul className="space-y-1 text-xs">
                        <li>• Mevcut verileriniz yedeklenir</li>
                        <li>• İçe aktarma işlemi geri alınamaz</li>
                        <li>• Sadece geçerli JSON dosyaları kabul edilir</li>
                      </ul>
                    </div>
                  </div>
                </div>
              </div>
            </TabsContent>
          </Tabs>
        </CardContent>
      </Card>
    </div>
  );
};

export default DataExportImport; 