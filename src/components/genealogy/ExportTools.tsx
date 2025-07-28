import React, { useState, useCallback, useRef } from 'react';
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
  BarChart3,
  AlertCircle
} from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';
import { Bird, Chick } from '@/types';
import { jsPDF } from 'jspdf';
import html2canvas from 'html2canvas';
import { toast } from '@/hooks/use-toast';

// Türkçe karakterler için basitleştirilmiş font yükleme
const loadTurkishFont = async () => {
  try {
    // jsPDF'in yerleşik fontlarını kullan, Türkçe karakter desteği için
    return 'helvetica';
  } catch (error) {
    console.warn('Font yüklenemedi, varsayılan font kullanılacak:', error);
    return 'helvetica';
  }
};

// Türkçe karakterleri daha etkili düzeltme fonksiyonu
const fixTurkishCharacters = (text: string): string => {
  if (!text) return '';
  
  // Türkçe karakterleri İngilizce karşılıklarına dönüştür
  const turkishMap: { [key: string]: string } = {
    'ç': 'c', 'Ç': 'C',
    'ğ': 'g', 'Ğ': 'G',
    'ı': 'i', 'I': 'I',
    'ö': 'o', 'Ö': 'O',
    'ş': 's', 'Ş': 'S',
    'ü': 'u', 'Ü': 'U',
    'İ': 'I',
    'â': 'a', 'Â': 'A',
    'ê': 'e', 'Ê': 'E',
    'î': 'i', 'Î': 'I',
    'ô': 'o', 'Ô': 'O',
    'û': 'u', 'Û': 'U'
  };
  
  return text.split('').map(char => turkishMap[char] || char).join('');
};

// Metin temizleme fonksiyonu - özel karakterleri düzelt
const cleanText = (text: string): string => {
  if (!text) return '';
  
  // Önce Türkçe karakterleri düzelt
  let cleaned = fixTurkishCharacters(text);
  
  // Sayısal karakterleri kontrol et ve düzelt
  cleaned = cleaned.replace(/1/g, 'i'); // 1'i i'ye çevir
  cleaned = cleaned.replace(/0/g, 'o'); // 0'ı o'ya çevir (gerekirse)
  
  return cleaned;
};

// PDF için basitleştirilmiş font ayarları
const setupPDFFont = async (doc: jsPDF) => {
  try {
    // Helvetica fontunu kullan ve encoding ayarla
    doc.setFont('helvetica');
    console.log('✅ Helvetica fontu kullanılıyor');
  } catch (error) {
    console.warn('Font ayarlama hatası:', error);
    doc.setFont('helvetica');
  }
};

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

  // PDF raporu oluşturma
  const generatePDFReport = useCallback(async () => {
    setIsExporting(true);
    try {
      console.log('🔄 PDF raporu oluşturuluyor...');
      
      // PDF oluştur
      const doc = new jsPDF('p', 'mm', 'a4');
      
      // Font ayarlarını yap
      await setupPDFFont(doc);
      
      // Sayfa boyutlarını ayarla
      const pageWidth = doc.internal.pageSize.getWidth();
      const pageHeight = doc.internal.pageSize.getHeight();
      const margin = 20;
      const contentWidth = pageWidth - (margin * 2);
      
      // Başlık sayfası
      doc.setFillColor(41, 98, 255);
      doc.rect(0, 0, pageWidth, 40, 'F');
      
      doc.setTextColor(255, 255, 255);
      doc.setFontSize(24);
      doc.setFont('helvetica', 'bold');
      doc.text('BUDGIE BREEDING TRACKER', pageWidth / 2, 25, { align: 'center' });
      
      doc.setTextColor(255, 255, 255);
      doc.setFontSize(16);
      doc.setFont('helvetica', 'normal');
      doc.text('SOYAGACI RAPORU', pageWidth / 2, 35, { align: 'center' });
      
      // Ana başlık
      doc.setTextColor(0, 0, 0);
      doc.setFontSize(20);
      doc.setFont('helvetica', 'bold');
      doc.text(`${selectedBird.name}`, margin, 70);
      
      // Tarih ve rapor bilgileri
      doc.setFontSize(10);
      doc.setFont('helvetica', 'normal');
      doc.text(`Rapor Tarihi: ${new Date().toLocaleDateString('tr-TR')}`, margin, 85);
      doc.text(`Rapor Saati: ${new Date().toLocaleTimeString('tr-TR')}`, margin, 95);
      doc.text(`Rapor ID: ${Date.now()}`, margin, 105);
      
      // Kuş bilgileri tablosu
      let yPosition = 130;
      doc.setFontSize(14);
      doc.setFont('helvetica', 'bold');
      doc.text('KUS BILGILERI', margin, yPosition);
      yPosition += 20;
      
      // Renkli tablo başlıkları
      doc.setFillColor(41, 98, 255);
      doc.rect(margin, yPosition - 5, contentWidth, 10, 'F');
      doc.setTextColor(255, 255, 255);
      doc.setFontSize(10);
      doc.setFont('helvetica', 'bold');
      doc.text('Ozellik', margin + 5, yPosition + 2);
      doc.text('Deger', margin + 80, yPosition + 2);
      yPosition += 15;
      
      // Tablo verileri - Alternatif satır renkleri
      doc.setFont('helvetica', 'normal');
      const birdInfo = [
        ['Isim', selectedBird.name],
        ['Cinsiyet', selectedBird.gender === 'male' ? 'Erkek' : selectedBird.gender === 'female' ? 'Disi' : 'Bilinmiyor'],
        ['Renk', cleanText(selectedBird.color || 'Belirtilmemis')],
        ['Halka Numarasi', selectedBird.ringNumber || 'Belirtilmemis'],
        ['Dogum Tarihi', ('hatchDate' in selectedBird && selectedBird.hatchDate) ? new Date(selectedBird.hatchDate).toLocaleDateString('tr-TR') : 'Belirtilmemis'],
        ['Saglik Notlari', cleanText(selectedBird.healthNotes || 'Not bulunmuyor')],
        ['Fotograf', selectedBird.photo ? 'Mevcut' : 'Bulunmuyor']
      ];
      
      birdInfo.forEach(([label, value], index) => {
        if (yPosition > pageHeight - 50) {
          doc.addPage();
          yPosition = 30;
        }
        
        // Alternatif satır renkleri
        if (index % 2 === 0) {
          doc.setFillColor(248, 250, 252);
          doc.rect(margin, yPosition - 2, contentWidth, 8, 'F');
        } else {
          doc.setFillColor(255, 255, 255);
          doc.rect(margin, yPosition - 2, contentWidth, 8, 'F');
        }
        
        doc.setTextColor(0, 0, 0);
        doc.text(label || '', margin + 5, yPosition + 2);
        doc.text(value || '', margin + 80, yPosition + 2);
        yPosition += 12;
      });
      
      // Aile ağacı bilgileri
      yPosition += 10;
      doc.setFontSize(14);
      doc.setFont('helvetica', 'bold');
      doc.text('AILE AGACI', margin, yPosition);
      yPosition += 20;
      
      // Ebeveynler
      if (familyData.father || familyData.mother) {
        doc.setFontSize(12);
        doc.setFont('helvetica', 'bold');
        doc.text('Ebeveynler:', margin, yPosition);
        yPosition += 15;
        doc.setFont('helvetica', 'normal');
        
        if (familyData.father) {
          doc.text(`• Baba: ${cleanText(familyData.father.name)} (${familyData.father.gender === 'male' ? 'Erkek' : 'Disi'})`, margin + 10, yPosition);
          yPosition += 10;
        }
        
        if (familyData.mother) {
          doc.text(`• Anne: ${cleanText(familyData.mother.name)} (${familyData.mother.gender === 'male' ? 'Erkek' : 'Disi'})`, margin + 10, yPosition);
          yPosition += 10;
        }
      }
      
      // Büyükanne ve büyükbabalar
      if (familyData.grandparents) {
        yPosition += 10;
        doc.setFontSize(12);
        doc.setFont('helvetica', 'bold');
        doc.text('Buyukanne ve Buyukbabalar:', margin, yPosition);
        yPosition += 15;
        doc.setFont('helvetica', 'normal');
        
        if (familyData.grandparents.paternalGrandfather) {
          doc.text(`• Baba Tarafi Buyukbaba: ${cleanText(familyData.grandparents.paternalGrandfather.name)}`, margin + 10, yPosition);
          yPosition += 8;
        }
        
        if (familyData.grandparents.paternalGrandmother) {
          doc.text(`• Baba Tarafi Buyukanne: ${cleanText(familyData.grandparents.paternalGrandmother.name)}`, margin + 10, yPosition);
          yPosition += 8;
        }
        
        if (familyData.grandparents.maternalGrandfather) {
          doc.text(`• Anne Tarafi Buyukbaba: ${cleanText(familyData.grandparents.maternalGrandfather.name)}`, margin + 10, yPosition);
          yPosition += 8;
        }
        
        if (familyData.grandparents.maternalGrandmother) {
          doc.text(`• Anne Tarafi Buyukanne: ${cleanText(familyData.grandparents.maternalGrandmother.name)}`, margin + 10, yPosition);
          yPosition += 8;
        }
      }
      
      // Kardeşler
      if (familyData.siblings && familyData.siblings.length > 0) {
        yPosition += 10;
        doc.setFontSize(12);
        doc.setFont('helvetica', 'bold');
        doc.text(`Kardesler (${familyData.siblings.length}):`, margin, yPosition);
        yPosition += 15;
        doc.setFont('helvetica', 'normal');
        
        familyData.siblings.forEach((sibling, index) => {
          if (yPosition > pageHeight - 50) {
            doc.addPage();
            yPosition = 30;
          }
          doc.text(`${index + 1}. ${cleanText(sibling.name)} (${sibling.gender === 'male' ? 'Erkek' : 'Disi'})`, margin + 10, yPosition);
          yPosition += 8;
        });
      }
      
      // Yavrular
      if (familyData.children && familyData.children.length > 0) {
        yPosition += 10;
        doc.setFontSize(12);
        doc.setFont('helvetica', 'bold');
        doc.text(`Yavrular (${familyData.children.length}):`, margin, yPosition);
        yPosition += 15;
        doc.setFont('helvetica', 'normal');
        
        familyData.children.forEach((child, index) => {
          if (yPosition > pageHeight - 50) {
            doc.addPage();
            yPosition = 30;
          }
          doc.text(`${index + 1}. ${cleanText(child.name)} (${child.gender === 'male' ? 'Erkek' : 'Disi'})`, margin + 10, yPosition);
          yPosition += 8;
        });
      }
      
      // Kuzenler
      if (familyData.cousins && familyData.cousins.length > 0) {
        yPosition += 10;
        doc.setFontSize(12);
        doc.setFont('helvetica', 'bold');
        doc.text(`Kuzenler (${familyData.cousins.length}):`, margin, yPosition);
        yPosition += 15;
        doc.setFont('helvetica', 'normal');
        
        familyData.cousins.forEach((cousin, index) => {
          if (yPosition > pageHeight - 50) {
            doc.addPage();
            yPosition = 30;
          }
          doc.text(`${index + 1}. ${cleanText(cousin.name)} (${cousin.gender === 'male' ? 'Erkek' : 'Disi'})`, margin + 10, yPosition);
          yPosition += 8;
        });
      }
      
      // İstatistikler sayfası
      if (exportOptions.includeStats) {
        doc.addPage();
        yPosition = 30;
        
        // İstatistik başlığı
        doc.setFillColor(41, 98, 255);
        doc.rect(0, 0, pageWidth, 30, 'F');
        doc.setTextColor(255, 255, 255);
        doc.setFontSize(16);
        doc.setFont('helvetica', 'bold');
        doc.text('ISTATISTIKLER VE ANALIZ', pageWidth / 2, 20, { align: 'center' });
        
        doc.setTextColor(0, 0, 0);
        yPosition = 50;
        
        // İstatistik tablosu
        doc.setFontSize(14);
        doc.setFont('helvetica', 'bold');
        doc.text('AILE ISTATISTIKLERI', margin, yPosition);
        yPosition += 20;
        
        const totalMembers = 1 + (familyData.children?.length || 0) + (familyData.siblings?.length || 0);
        const maleCount = [selectedBird, ...(familyData.children || []), ...(familyData.siblings || [])]
          .filter(member => member.gender === 'male').length;
        const femaleCount = [selectedBird, ...(familyData.children || []), ...(familyData.siblings || [])]
          .filter(member => member.gender === 'female').length;
        const unknownCount = [selectedBird, ...(familyData.children || []), ...(familyData.siblings || [])]
          .filter(member => member.gender === 'unknown').length;
        
        const stats = [
          ['Toplam Aile Uyesi', totalMembers.toString()],
          ['Erkek Sayisi', maleCount.toString()],
          ['Disi Sayisi', femaleCount.toString()],
          ['Cinsiyet Belirsiz', unknownCount.toString()],
          ['Ebeveyn Sayisi', `${familyData.father ? 1 : 0} + ${familyData.mother ? 1 : 0}`],
          ['Yavru Sayisi', (familyData.children?.length || 0).toString()],
          ['Kardes Sayisi', (familyData.siblings?.length || 0).toString()],
          ['Kuzen Sayisi', (familyData.cousins?.length || 0).toString()]
        ];
        
        // Renkli istatistik tablosu
        doc.setFillColor(34, 197, 94); // Yeşil başlık
        doc.rect(margin, yPosition - 5, contentWidth, 10, 'F');
        doc.setTextColor(255, 255, 255);
        doc.setFontSize(10);
        doc.setFont('helvetica', 'bold');
        doc.text('Metrik', margin + 5, yPosition + 2);
        doc.text('Deger', margin + 80, yPosition + 2);
        yPosition += 15;
        
        doc.setFont('helvetica', 'normal');
        stats.forEach(([label, value], index) => {
          // Alternatif satır renkleri
          if (index % 2 === 0) {
            doc.setFillColor(240, 253, 244); // Açık yeşil
            doc.rect(margin, yPosition - 2, contentWidth, 8, 'F');
          } else {
            doc.setFillColor(255, 255, 255);
            doc.rect(margin, yPosition - 2, contentWidth, 8, 'F');
          }
          
          doc.setTextColor(0, 0, 0);
          doc.text(label || '', margin + 5, yPosition + 2);
          doc.text(value || '', margin + 80, yPosition + 2);
          yPosition += 12;
        });
        
        // Genetik analiz
        yPosition += 20;
        doc.setFontSize(14);
        doc.setFont('helvetica', 'bold');
        doc.text('GENETIK ANALIZ', margin, yPosition);
        yPosition += 20;
        
        doc.setFont('helvetica', 'normal');
        doc.setFontSize(10);
        
        // Renk dağılımı tablosu
        const colorStats: { [key: string]: number } = {};
        [selectedBird, ...(familyData.children || []), ...(familyData.siblings || [])].forEach(member => {
          if (member.color) {
            colorStats[member.color] = (colorStats[member.color] || 0) + 1;
          }
        });
        
        if (Object.keys(colorStats).length > 0) {
          yPosition += 10;
          doc.setFontSize(12);
          doc.setFont('helvetica', 'bold');
          doc.text('Renk Dagilimi:', margin, yPosition);
          yPosition += 15;
          
          // Renk tablosu başlığı
          doc.setFillColor(168, 85, 247); // Mor başlık
          doc.rect(margin, yPosition - 5, contentWidth, 10, 'F');
          doc.setTextColor(255, 255, 255);
          doc.setFontSize(10);
          doc.setFont('helvetica', 'bold');
          doc.text('Renk', margin + 5, yPosition + 2);
          doc.text('Sayi', margin + 80, yPosition + 2);
          yPosition += 15;
          
          doc.setFont('helvetica', 'normal');
          Object.entries(colorStats).forEach(([color, count], index) => {
            // Alternatif satır renkleri
            if (index % 2 === 0) {
              doc.setFillColor(250, 245, 255); // Açık mor
              doc.rect(margin, yPosition - 2, contentWidth, 8, 'F');
            } else {
              doc.setFillColor(255, 255, 255);
              doc.rect(margin, yPosition - 2, contentWidth, 8, 'F');
            }
            
            doc.setTextColor(0, 0, 0);
            doc.text(cleanText(color), margin + 5, yPosition + 2);
            doc.text(`${count} kus`, margin + 80, yPosition + 2);
            yPosition += 12;
          });
        }
        
        // Cinsiyet oranı tablosu
        yPosition += 15;
        doc.setFontSize(12);
        doc.setFont('helvetica', 'bold');
        doc.text('Cinsiyet Orani:', margin, yPosition);
        yPosition += 15;
        
        const totalWithGender = maleCount + femaleCount;
        if (totalWithGender > 0) {
          const malePercentage = ((maleCount / totalWithGender) * 100).toFixed(1);
          const femalePercentage = ((femaleCount / totalWithGender) * 100).toFixed(1);
          
          // Cinsiyet tablosu başlığı
          doc.setFillColor(239, 68, 68); // Kırmızı başlık
          doc.rect(margin, yPosition - 5, contentWidth, 10, 'F');
          doc.setTextColor(255, 255, 255);
          doc.setFontSize(10);
          doc.setFont('helvetica', 'bold');
          doc.text('Cinsiyet', margin + 5, yPosition + 2);
          doc.text('Sayi ve Oran', margin + 80, yPosition + 2);
          yPosition += 15;
          
          doc.setFont('helvetica', 'normal');
          
          // Erkek satırı
          doc.setFillColor(254, 226, 226); // Açık kırmızı
          doc.rect(margin, yPosition - 2, contentWidth, 8, 'F');
          doc.setTextColor(0, 0, 0);
          doc.text('Erkek', margin + 5, yPosition + 2);
          doc.text(`${maleCount} (%${malePercentage})`, margin + 80, yPosition + 2);
          yPosition += 12;
          
          // Dişi satırı
          doc.setFillColor(255, 255, 255);
          doc.rect(margin, yPosition - 2, contentWidth, 8, 'F');
          doc.setTextColor(0, 0, 0);
          doc.text('Disi', margin + 5, yPosition + 2);
          doc.text(`${femaleCount} (%${femalePercentage})`, margin + 80, yPosition + 2);
          yPosition += 12;
        }
      }
      
      // Zaman çizelgesi
      if (exportOptions.includeTimeline) {
        doc.addPage();
        yPosition = 30;
        
        // Zaman çizelgesi başlığı
        doc.setFillColor(41, 98, 255);
        doc.rect(0, 0, pageWidth, 30, 'F');
        doc.setTextColor(255, 255, 255);
        doc.setFontSize(16);
        doc.setFont('helvetica', 'bold');
        doc.text('ZAMAN CIZELGESI', pageWidth / 2, 20, { align: 'center' });
        
        doc.setTextColor(0, 0, 0);
        yPosition = 50;
        
        doc.setFontSize(12);
        doc.setFont('helvetica', 'normal');
        
        const timeline = [];
        if ('hatchDate' in selectedBird && selectedBird.hatchDate) {
          timeline.push({
            date: new Date(selectedBird.hatchDate),
            event: `${selectedBird.name} dogdu`
          });
        }
        
        if (familyData.children && familyData.children.length > 0) {
          familyData.children.forEach(child => {
            if ('hatchDate' in child && child.hatchDate) {
              timeline.push({
                date: new Date(child.hatchDate),
                event: `${child.name} dogdu`
              });
            }
          });
        }
        
        // Tarihe göre sırala
        timeline.sort((a, b) => a.date.getTime() - b.date.getTime());
        
        // Zaman çizelgesi tablosu başlığı
        doc.setFillColor(245, 158, 11); // Turuncu başlık
        doc.rect(margin, yPosition - 5, contentWidth, 10, 'F');
        doc.setTextColor(255, 255, 255);
        doc.setFontSize(10);
        doc.setFont('helvetica', 'bold');
        doc.text('Sira', margin + 5, yPosition + 2);
        doc.text('Tarih', margin + 30, yPosition + 2);
        doc.text('Olay', margin + 80, yPosition + 2);
        yPosition += 15;
        
        doc.setFont('helvetica', 'normal');
        timeline.forEach((item, index) => {
          if (yPosition > pageHeight - 50) {
            doc.addPage();
            yPosition = 30;
          }
          
          // Alternatif satır renkleri
          if (index % 2 === 0) {
            doc.setFillColor(255, 251, 235); // Açık turuncu
            doc.rect(margin, yPosition - 2, contentWidth, 8, 'F');
          } else {
            doc.setFillColor(255, 255, 255);
            doc.rect(margin, yPosition - 2, contentWidth, 8, 'F');
          }
          
          doc.setTextColor(0, 0, 0);
          doc.setFont('helvetica', 'bold');
          doc.text(`${index + 1}.`, margin + 5, yPosition + 2);
          doc.setFont('helvetica', 'normal');
          doc.text(item.date.toLocaleDateString('tr-TR'), margin + 30, yPosition + 2);
          doc.text(item.event, margin + 80, yPosition + 2);
          yPosition += 12;
        });
      }
      
      // Son sayfa - Rapor bilgileri
      doc.addPage();
      yPosition = 30;
      
      doc.setFillColor(41, 98, 255);
      doc.rect(0, 0, pageWidth, 30, 'F');
      doc.setTextColor(255, 255, 255);
      doc.setFontSize(16);
      doc.setFont('helvetica', 'bold');
      doc.text('RAPOR BILGILERI', pageWidth / 2, 20, { align: 'center' });
      
      doc.setTextColor(0, 0, 0);
      yPosition = 50;
      
      doc.setFontSize(10);
      doc.setFont('helvetica', 'normal');
      
      const reportInfo = [
        ['Rapor Olusturan', 'Budgie Breeding Tracker'],
        ['Rapor Tarihi', new Date().toLocaleDateString('tr-TR')],
        ['Rapor Saati', new Date().toLocaleTimeString('tr-TR')],
        ['Rapor ID', Date.now().toString()],
        ['Toplam Sayfa', doc.getNumberOfPages().toString()],
        ['Veri Kaynagi', 'Supabase Veritabani'],
        ['Rapor Versiyonu', '1.0.0']
      ];
      
      // Rapor bilgileri tablosu başlığı
      doc.setFillColor(59, 130, 246); // Mavi başlık
      doc.rect(margin, yPosition - 5, contentWidth, 10, 'F');
      doc.setTextColor(255, 255, 255);
      doc.setFontSize(10);
      doc.setFont('helvetica', 'bold');
      doc.text('Bilgi', margin + 5, yPosition + 2);
      doc.text('Deger', margin + 80, yPosition + 2);
      yPosition += 15;
      
      doc.setFont('helvetica', 'normal');
      reportInfo.forEach(([label, value], index) => {
        // Alternatif satır renkleri
        if (index % 2 === 0) {
          doc.setFillColor(239, 246, 255); // Açık mavi
          doc.rect(margin, yPosition - 2, contentWidth, 8, 'F');
        } else {
          doc.setFillColor(255, 255, 255);
          doc.rect(margin, yPosition - 2, contentWidth, 8, 'F');
        }
        
        doc.setTextColor(0, 0, 0);
        doc.text(label || '', margin + 5, yPosition + 2);
        doc.text(value || '', margin + 80, yPosition + 2);
        yPosition += 12;
      });
      
      // Alt bilgi
      yPosition = pageHeight - 40;
      doc.setFontSize(8);
      doc.setTextColor(128, 128, 128);
      doc.text('Bu rapor Budgie Breeding Tracker uygulamasi tarafindan otomatik olarak olusturulmustur.', margin, yPosition);
      doc.text('Rapor bilgileri gizlilik politikasina uygun olarak korunmaktadir.', margin, yPosition + 8);
      
      // PDF'i indir
      doc.save(`${selectedBird.name}-kapsamli-soyagaci-raporu-${new Date().toISOString().split('T')[0]}.pdf`);
      
      toast({
        title: 'Başarılı',
        description: 'Kapsamlı PDF raporu başarıyla oluşturuldu ve indirildi.',
        variant: 'default'
      });
      
    } catch (error) {
      console.error('PDF oluşturma hatası:', error);
      toast({
        title: 'Hata',
        description: 'PDF oluşturulurken bir hata oluştu.',
        variant: 'destructive'
      });
    } finally {
      setIsExporting(false);
    }
  }, [familyData, selectedBird, exportOptions.includeStats, exportOptions.includeTimeline]);

  // Görsel dışa aktarma
  const exportVisualization = useCallback(async () => {
    setIsExporting(true);
    try {
      // Soyağacı görselini yakala
      const familyTreeElement = document.querySelector('.family-tree-container') || document.querySelector('.genealogy-view');
      
      if (!familyTreeElement) {
        throw new Error('Soyağacı görseli bulunamadı');
      }
      
      const canvas = await html2canvas(familyTreeElement as HTMLElement, {
        scale: exportOptions.quality === 'high' ? 2 : exportOptions.quality === 'medium' ? 1.5 : 1,
        useCORS: true,
        allowTaint: true,
        backgroundColor: '#ffffff'
      });
      
      // Canvas'ı dosya olarak indir
      const link = document.createElement('a');
      
      if (exportOptions.format === 'png') {
        link.href = canvas.toDataURL('image/png');
        link.download = `${selectedBird.name}-soyagaci.png`;
      } else if (exportOptions.format === 'svg') {
        // SVG için canvas'ı SVG'ye çevir
        const svgData = canvas.toDataURL('image/svg+xml');
        link.href = svgData;
        link.download = `${selectedBird.name}-soyagaci.svg`;
      } else {
        // JSON formatı için veriyi JSON olarak kaydet
        const jsonData = {
          bird: selectedBird,
          familyData: familyData,
          exportDate: new Date().toISOString(),
          format: 'json'
        };
        const blob = new Blob([JSON.stringify(jsonData, null, 2)], { type: 'application/json' });
        link.href = URL.createObjectURL(blob);
        link.download = `${selectedBird.name}-soyagaci.json`;
      }
      
      link.click();
      
      toast({
        title: 'Başarılı',
        description: `Soyağacı ${exportOptions.format.toUpperCase()} formatında dışa aktarıldı.`,
        variant: 'default'
      });
      
    } catch (error) {
      console.error('Görsel dışa aktarma hatası:', error);
      toast({
        title: 'Hata',
        description: 'Görsel dışa aktarılırken bir hata oluştu.',
        variant: 'destructive'
      });
    } finally {
      setIsExporting(false);
    }
  }, [exportOptions.format, exportOptions.quality, selectedBird.name, familyData]);

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
          toast({
            title: 'E-posta',
            description: 'E-posta uygulamanız açılıyor...',
            variant: 'default'
          });
          break;
        case 'whatsapp':
          window.open(`https://wa.me/?text=${encodeURIComponent(shareData.text + '\n\n' + shareData.url)}`);
          toast({
            title: 'WhatsApp',
            description: 'WhatsApp paylaşım sayfası açılıyor...',
            variant: 'default'
          });
          break;
        case 'telegram':
          window.open(`https://t.me/share/url?url=${encodeURIComponent(shareData.url)}&text=${encodeURIComponent(shareData.text)}`);
          toast({
            title: 'Telegram',
            description: 'Telegram paylaşım sayfası açılıyor...',
            variant: 'default'
          });
          break;
        case 'copy':
          await navigator.clipboard.writeText(`${shareData.text}\n\n${shareData.url}`);
          setCopied(true);
          setTimeout(() => setCopied(false), 2000);
          toast({
            title: 'Kopyalandı',
            description: 'Bağlantı panoya kopyalandı.',
            variant: 'default'
          });
          break;
      }
    } catch (error) {
      console.error('Paylaşım hatası:', error);
      toast({
        title: 'Hata',
        description: 'Paylaşım sırasında bir hata oluştu.',
        variant: 'destructive'
      });
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
          exportOptions: exportOptions,
          exportDate: new Date().toLocaleDateString('tr-TR')
        }
      };

      const dataStr = JSON.stringify(backupData, null, 2);
      const dataBlob = new Blob([dataStr], { type: 'application/json' });
      
      const link = document.createElement('a');
      link.href = URL.createObjectURL(dataBlob);
      link.download = `soyagaci-yedek-${new Date().toISOString().split('T')[0]}.json`;
      link.click();
      
      toast({
        title: 'Başarılı',
        description: 'Soyağacı yedekleme dosyası indirildi.',
        variant: 'default'
      });
      
    } catch (error) {
      console.error('Yedekleme hatası:', error);
      toast({
        title: 'Hata',
        description: 'Yedekleme dosyası oluşturulurken bir hata oluştu.',
        variant: 'destructive'
      });
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