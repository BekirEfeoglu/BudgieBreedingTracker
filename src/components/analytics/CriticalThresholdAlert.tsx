import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { Badge } from '@/components/ui/badge';
import { AlertTriangle, TrendingDown, TrendingUp, Info } from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';

interface CriticalThresholdAlertProps {
  birds: Array<{ status?: string; gender?: string }>;
  breeding: Array<{ status: string; startDate: string }>;
  eggs: Array<{ status: string }>;
  incubations: Array<{ status: string; startDate: string }>;
}

interface AlertItem {
  type: 'warning' | 'error' | 'info' | 'success';
  title: string;
  description: string;
  icon: React.ReactNode;
  severity: 'low' | 'medium' | 'high';
}

const CriticalThresholdAlert: React.FC<CriticalThresholdAlertProps> = ({ 
  birds, 
  breeding, 
  eggs, 
  incubations 
}) => {
  const { t } = useLanguage();

  const alerts = React.useMemo((): AlertItem[] => {
    const alertsList: AlertItem[] = [];
    
    // Ölüm oranı kontrolü
    const totalBirds = birds.length;
    const deadBirds = birds.filter(b => b.status === 'dead').length;
    const deathRate = totalBirds > 0 ? (deadBirds / totalBirds) * 100 : 0;
    
    if (deathRate > 15) {
      alertsList.push({
        type: 'error',
        title: 'Yüksek Ölüm Oranı',
        description: `Ölüm oranı %${deathRate.toFixed(1)} seviyesinde. Bu normal değerlerin üzerinde.`,
        icon: <AlertTriangle className="h-4 w-4" />,
        severity: 'high'
      });
    } else if (deathRate > 10) {
      alertsList.push({
        type: 'warning',
        title: 'Artış Gösteren Ölüm Oranı',
        description: `Ölüm oranı %${deathRate.toFixed(1)} seviyesinde. Dikkat edilmesi gereken bir durum.`,
        icon: <TrendingDown className="h-4 w-4" />,
        severity: 'medium'
      });
    }

    // Başarı oranı kontrolü
    const totalBreeding = breeding.length;
    const successfulBreeding = breeding.filter(b => b.status === 'successful').length;
    const successRate = totalBreeding > 0 ? (successfulBreeding / totalBreeding) * 100 : 0;
    
    if (successRate < 30) {
      alertsList.push({
        type: 'error',
        title: 'Düşük Başarı Oranı',
        description: `Üreme başarı oranı %${successRate.toFixed(1)} seviyesinde. Bu çok düşük bir oran.`,
        icon: <TrendingDown className="h-4 w-4" />,
        severity: 'high'
      });
    } else if (successRate < 50) {
      alertsList.push({
        type: 'warning',
        title: 'Geliştirilmesi Gereken Başarı Oranı',
        description: `Üreme başarı oranı %${successRate.toFixed(1)} seviyesinde. İyileştirme gerekli.`,
        icon: <TrendingDown className="h-4 w-4" />,
        severity: 'medium'
      });
    }

    // Cinsiyet dengesi kontrolü
    const maleBirds = birds.filter(b => b.gender === 'male').length;
    const femaleBirds = birds.filter(b => b.gender === 'female').length;
    const genderRatio = maleBirds > 0 ? femaleBirds / maleBirds : 0;
    
    if (genderRatio < 0.5 || genderRatio > 2) {
      alertsList.push({
        type: 'warning',
        title: 'Cinsiyet Dengesi Sorunu',
        description: `Cinsiyet oranı ${genderRatio.toFixed(2)} (dişi/erkek). Optimal oran 1.0 civarında olmalı.`,
        icon: <Info className="h-4 w-4" />,
        severity: 'medium'
      });
    }

    // Kuluçka durumu kontrolü
    const activeIncubations = incubations.filter(i => i.status === 'active').length;
    const longIncubations = incubations.filter(i => {
      if (i.status !== 'active') return false;
      const startDate = new Date(i.startDate);
      const daysDiff = (new Date().getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24);
      return daysDiff > 25; // 25 günden uzun kuluçka
    }).length;
    
    if (longIncubations > 0) {
      alertsList.push({
        type: 'warning',
        title: 'Uzun Süren Kuluçka',
        description: `${longIncubations} kuluçka 25 günden uzun süredir devam ediyor. Kontrol edilmeli.`,
        icon: <AlertTriangle className="h-4 w-4" />,
        severity: 'medium'
      });
    }

    // Yumurta durumu kontrolü
    const totalEggs = eggs.length;
    const infertileEggs = eggs.filter(e => e.status === 'infertile').length;
    const infertileRate = totalEggs > 0 ? (infertileEggs / totalEggs) * 100 : 0;
    
    if (infertileRate > 50) {
      alertsList.push({
        type: 'warning',
        title: 'Yüksek Döllenmemiş Yumurta Oranı',
        description: `Döllenmemiş yumurta oranı %${infertileRate.toFixed(1)} seviyesinde. Çift uyumluluğu kontrol edilmeli.`,
        icon: <Info className="h-4 w-4" />,
        severity: 'medium'
      });
    }

    // Pozitif gelişmeler
    if (successRate > 80) {
      alertsList.push({
        type: 'success',
        title: 'Mükemmel Başarı Oranı',
        description: `Üreme başarı oranı %${successRate.toFixed(1)} seviyesinde. Harika bir performans!`,
        icon: <TrendingUp className="h-4 w-4" />,
        severity: 'low'
      });
    }

    return alertsList.sort((a, b) => {
      const severityOrder = { high: 3, medium: 2, low: 1 };
      return severityOrder[b.severity] - severityOrder[a.severity];
    });
  }, [birds, breeding, eggs, incubations]);

  if (alerts.length === 0) {
    return (
      <Card className="enhanced-card">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Info className="h-5 w-5 text-green-600" />
            Sistem Durumu
          </CardTitle>
        </CardHeader>
        <CardContent>
          <Alert>
            <Info className="h-4 w-4" />
            <AlertTitle>Her şey yolunda!</AlertTitle>
            <AlertDescription>
              Tüm kritik metrikler normal değerler arasında. Sistem sağlıklı çalışıyor.
            </AlertDescription>
          </Alert>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="enhanced-card">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <AlertTriangle className="h-5 w-5 text-orange-600" />
          Kritik Uyarılar ({alerts.length})
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-3">
          {alerts.map((alert, index) => (
            <Alert key={index} variant={alert.type === 'error' ? 'destructive' : 'default'}>
              {alert.icon}
              <AlertTitle className="flex items-center gap-2">
                {alert.title}
                <Badge variant={alert.severity === 'high' ? 'destructive' : alert.severity === 'medium' ? 'secondary' : 'outline'}>
                  {alert.severity === 'high' ? 'Kritik' : alert.severity === 'medium' ? 'Orta' : 'Düşük'}
                </Badge>
              </AlertTitle>
              <AlertDescription>
                {alert.description}
              </AlertDescription>
            </Alert>
          ))}
        </div>
      </CardContent>
    </Card>
  );
};

export default CriticalThresholdAlert; 