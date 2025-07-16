import React, { useMemo, useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { 
  Dna, 
  Heart, 
  TrendingUp, 
  Clock, 
  Users, 
  Baby, 
  AlertTriangle,
  CheckCircle,
  BarChart3,
  PieChart,
  Activity
} from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';
import { Bird, Chick } from '@/types';

interface GeneticAnalysisProps {
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

interface GeneticTrait {
  name: string;
  value: string;
  frequency: number;
  inheritance: 'dominant' | 'recessive' | 'co-dominant';
  description: string;
}

interface BreedingSuccess {
  totalBreedings: number;
  successfulBreedings: number;
  totalEggs: number;
  hatchedEggs: number;
  successRate: number;
  averageClutchSize: number;
}

interface HealthTrend {
  period: string;
  excellent: number;
  good: number;
  poor: number;
  average: number;
}

interface LifespanData {
  averageLifespan: number;
  maxLifespan: number;
  minLifespan: number;
  currentAge: number;
  lifeStage: 'young' | 'adult' | 'old';
  lifeExpectancy: number;
}

const GeneticAnalysis: React.FC<GeneticAnalysisProps> = ({
  familyData,
  selectedBird
}) => {
  const { t } = useLanguage();
  const [activeTab, setActiveTab] = useState('traits');

  // Genetik özellikler analizi
  const geneticTraits = useMemo(() => {
    const traits: GeneticTrait[] = [];
    const allFamilyMembers = [
      selectedBird,
      familyData.father,
      familyData.mother,
      ...familyData.children,
      ...familyData.siblings,
      familyData.grandparents.paternalGrandfather,
      familyData.grandparents.paternalGrandmother,
      familyData.grandparents.maternalGrandfather,
      familyData.grandparents.maternalGrandmother
    ].filter(Boolean) as (Bird | Chick)[];

    // Cinsiyet dağılımı
    const genderCounts = allFamilyMembers.reduce((acc, member) => {
      acc[member.gender] = (acc[member.gender] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);

    const totalMembers = allFamilyMembers.length;
    traits.push({
      name: 'Cinsiyet Dağılımı',
      value: `${genderCounts.male || 0} Erkek, ${genderCounts.female || 0} Dişi`,
      frequency: Math.max(genderCounts.male || 0, genderCounts.female || 0) / totalMembers,
      inheritance: 'co-dominant',
      description: 'Aile içindeki cinsiyet dağılımı'
    });

    // Renk dağılımı
    const colorCounts = allFamilyMembers.reduce((acc, member) => {
      const color = member.color || 'Bilinmiyor';
      acc[color] = (acc[color] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);

    const dominantColor = Object.entries(colorCounts).sort((a, b) => b[1] - a[1])[0];
    if (dominantColor) {
      traits.push({
        name: 'Baskın Renk',
        value: dominantColor[0],
        frequency: dominantColor[1] / totalMembers,
        inheritance: 'dominant',
        description: 'Aile içinde en yaygın renk'
      });
    }

    // Yaş dağılımı
    const ages = allFamilyMembers.map(member => {
      const birthDate = 'hatchDate' in member ? member.hatchDate : member.birthDate;
      if (birthDate) {
        return Math.floor((new Date().getTime() - new Date(birthDate).getTime()) / (1000 * 60 * 60 * 24));
      }
      return 0;
    }).filter(age => age > 0);

    if (ages.length > 0) {
      const averageAge = ages.reduce((sum, age) => sum + age, 0) / ages.length;
      traits.push({
        name: 'Ortalama Yaş',
        value: `${Math.round(averageAge / 365)} yıl`,
        frequency: averageAge / (365 * 10), // 10 yıl maksimum yaş varsayımı
        inheritance: 'co-dominant',
        description: 'Aile üyelerinin ortalama yaşı'
      });
    }

    return traits;
  }, [familyData, selectedBird]);

  // Üreme başarısı analizi
  const breedingSuccess = useMemo((): BreedingSuccess => {
    // Bu veriler gerçek üreme kayıtlarından gelecek
    // Şimdilik varsayımsal veriler
    const totalBreedings = familyData.children.length * 2; // Her çocuk için 2 üreme denemesi varsayımı
    const successfulBreedings = familyData.children.length;
    const totalEggs = totalBreedings * 4; // Ortalama 4 yumurta
    const hatchedEggs = familyData.children.length * 3; // Ortalama 3 yavru çıkışı

    return {
      totalBreedings,
      successfulBreedings,
      totalEggs,
      hatchedEggs,
      successRate: (successfulBreedings / totalBreedings) * 100,
      averageClutchSize: totalEggs / totalBreedings
    };
  }, [familyData]);

  // Sağlık geçmişi analizi
  const healthTrends = useMemo((): HealthTrend[] => {
    // Bu veriler gerçek sağlık kayıtlarından gelecek
    return [
      {
        period: 'Son 6 Ay',
        excellent: 70,
        good: 20,
        poor: 10,
        average: 85
      },
      {
        period: 'Son 1 Yıl',
        excellent: 65,
        good: 25,
        poor: 10,
        average: 82
      },
      {
        period: 'Son 2 Yıl',
        excellent: 60,
        good: 30,
        poor: 10,
        average: 80
      }
    ];
  }, []);

  // Yaşam süresi analizi
  const lifespanData = useMemo((): LifespanData => {
    const birthDate = 'hatchDate' in selectedBird ? selectedBird.hatchDate : selectedBird.birthDate;
    const currentAge = birthDate ? 
      Math.floor((new Date().getTime() - new Date(birthDate).getTime()) / (1000 * 60 * 60 * 24)) : 0;
    
    const ageInYears = currentAge / 365;
    let lifeStage: 'young' | 'adult' | 'old' = 'young';
    if (ageInYears > 5) lifeStage = 'old';
    else if (ageInYears > 1) lifeStage = 'adult';

    // Aile üyelerinin yaşam süreleri
    const allFamilyMembers = [
      familyData.father,
      familyData.mother,
      ...familyData.children,
      ...familyData.siblings,
      familyData.grandparents.paternalGrandfather,
      familyData.grandparents.paternalGrandmother,
      familyData.grandparents.maternalGrandfather,
      familyData.grandparents.maternalGrandmother
    ].filter(Boolean) as (Bird | Chick)[];

    const ages = allFamilyMembers.map(member => {
      const birthDate = 'hatchDate' in member ? member.hatchDate : member.birthDate;
      if (birthDate) {
        return Math.floor((new Date().getTime() - new Date(birthDate).getTime()) / (1000 * 60 * 60 * 24)) / 365;
      }
      return 0;
    }).filter(age => age > 0);

    const averageLifespan = ages.length > 0 ? ages.reduce((sum, age) => sum + age, 0) / ages.length : 5;
    const maxLifespan = ages.length > 0 ? Math.max(...ages) : 8;
    const minLifespan = ages.length > 0 ? Math.min(...ages) : 1;

    return {
      averageLifespan,
      maxLifespan,
      minLifespan,
      currentAge: ageInYears,
      lifeStage,
      lifeExpectancy: averageLifespan + (averageLifespan * 0.2) // %20 ek yaşam beklentisi
    };
  }, [familyData, selectedBird]);

  const renderGeneticTraits = () => (
    <div className="space-y-4">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {geneticTraits.map((trait, index) => (
          <Card key={`trait-${index}-${trait.name}`} className="enhanced-card">
            <CardHeader className="pb-3">
              <div className="flex items-center justify-between">
                <CardTitle className="text-sm flex items-center gap-2">
                  <Dna className="w-4 h-4" />
                  {trait.name}
                </CardTitle>
                <Badge 
                  variant={trait.inheritance === 'dominant' ? 'default' : 
                          trait.inheritance === 'recessive' ? 'secondary' : 'outline'}
                  className="text-xs"
                >
                  {trait.inheritance === 'dominant' ? 'Baskın' : 
                   trait.inheritance === 'recessive' ? 'Çekinik' : 'Eş Baskın'}
                </Badge>
              </div>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="text-2xl font-bold text-primary">
                {trait.value}
              </div>
              <div className="space-y-2">
                <div className="flex justify-between text-sm">
                  <span>Frekans</span>
                  <span>{Math.round(trait.frequency * 100)}%</span>
                </div>
                <Progress value={trait.frequency * 100} className="h-2" />
              </div>
              <p className="text-xs text-muted-foreground">
                {trait.description}
              </p>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );

  const renderBreedingSuccess = () => (
    <div className="space-y-6">
      {/* Genel Başarı Oranı */}
      <Card className="enhanced-card">
        <CardHeader>
          <CardTitle className="text-lg flex items-center gap-2">
            <TrendingUp className="w-5 h-5" />
            Genel Üreme Başarısı
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div className="text-center">
              <div className="text-2xl font-bold text-primary">
                {breedingSuccess.successRate.toFixed(1)}%
              </div>
              <div className="text-sm text-muted-foreground">Başarı Oranı</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-green-600">
                {breedingSuccess.successfulBreedings}
              </div>
              <div className="text-sm text-muted-foreground">Başarılı Üreme</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-blue-600">
                {breedingSuccess.totalBreedings}
              </div>
              <div className="text-sm text-muted-foreground">Toplam Üreme</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-orange-600">
                {breedingSuccess.averageClutchSize.toFixed(1)}
              </div>
              <div className="text-sm text-muted-foreground">Ort. Yumurta</div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Detaylı İstatistikler */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <Card className="enhanced-card">
          <CardHeader>
            <CardTitle className="text-sm flex items-center gap-2">
              <Baby className="w-4 h-4" />
              Yumurta ve Yavru İstatistikleri
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <div className="flex justify-between text-sm">
                <span>Toplam Yumurta</span>
                <span className="font-medium">{breedingSuccess.totalEggs}</span>
              </div>
              <Progress value={(breedingSuccess.hatchedEggs / breedingSuccess.totalEggs) * 100} className="h-2" />
              <div className="flex justify-between text-sm">
                <span>Çıkan Yavrular</span>
                <span className="font-medium text-green-600">{breedingSuccess.hatchedEggs}</span>
              </div>
            </div>
            <div className="text-xs text-muted-foreground">
              Çıkış oranı: {((breedingSuccess.hatchedEggs / breedingSuccess.totalEggs) * 100).toFixed(1)}%
            </div>
          </CardContent>
        </Card>

        <Card className="enhanced-card">
          <CardHeader>
            <CardTitle className="text-sm flex items-center gap-2">
              <Users className="w-4 h-4" />
              Aile Büyüklüğü
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4 text-center">
              <div>
                <div className="text-2xl font-bold text-blue-600">
                  {familyData.children.length}
                </div>
                <div className="text-xs text-muted-foreground">Çocuk</div>
              </div>
              <div>
                <div className="text-2xl font-bold text-green-600">
                  {familyData.siblings.length}
                </div>
                <div className="text-xs text-muted-foreground">Kardeş</div>
              </div>
            </div>
            <div className="text-xs text-muted-foreground">
              Toplam aile üyesi: {familyData.children.length + familyData.siblings.length + 1}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );

  const renderHealthTrends = () => (
    <div className="space-y-6">
      {/* Sağlık Trendi Grafiği */}
      <Card className="enhanced-card">
        <CardHeader>
          <CardTitle className="text-lg flex items-center gap-2">
            <Activity className="w-5 h-5" />
            Sağlık Trendi
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {healthTrends.map((trend, index) => (
              <div key={`health-${index}-${trend.period}`} className="space-y-2">
                <div className="flex justify-between text-sm">
                  <span className="font-medium">{trend.period}</span>
                  <span className="text-muted-foreground">Ortalama: {trend.average}%</span>
                </div>
                <div className="grid grid-cols-3 gap-2">
                  <div className="flex items-center gap-1">
                    <div className="w-3 h-3 rounded-full bg-green-500"></div>
                    <span className="text-xs">Mükemmel: {trend.excellent}%</span>
                  </div>
                  <div className="flex items-center gap-1">
                    <div className="w-3 h-3 rounded-full bg-yellow-500"></div>
                    <span className="text-xs">İyi: {trend.good}%</span>
                  </div>
                  <div className="flex items-center gap-1">
                    <div className="w-3 h-3 rounded-full bg-red-500"></div>
                    <span className="text-xs">Kötü: {trend.poor}%</span>
                  </div>
                </div>
                <Progress value={trend.average} className="h-2" />
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Sağlık Durumu Dağılımı */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card className="enhanced-card">
          <CardHeader className="pb-3">
            <CardTitle className="text-sm flex items-center gap-2">
              <CheckCircle className="w-4 h-4 text-green-500" />
              Mükemmel Sağlık
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-green-600">
              {healthTrends[0]?.excellent || 0}%
            </div>
            <div className="text-xs text-muted-foreground">
              Son 6 ayda mükemmel sağlık oranı
            </div>
          </CardContent>
        </Card>

        <Card className="enhanced-card">
          <CardHeader className="pb-3">
            <CardTitle className="text-sm flex items-center gap-2">
              <AlertTriangle className="w-4 h-4 text-yellow-500" />
              İyi Sağlık
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-yellow-600">
              {healthTrends[0]?.good || 0}%
            </div>
            <div className="text-xs text-muted-foreground">
              Son 6 ayda iyi sağlık oranı
            </div>
          </CardContent>
        </Card>

        <Card className="enhanced-card">
          <CardHeader className="pb-3">
            <CardTitle className="text-sm flex items-center gap-2">
              <AlertTriangle className="w-4 h-4 text-red-500" />
              Kötü Sağlık
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-red-600">
              {healthTrends[0]?.poor || 0}%
            </div>
            <div className="text-xs text-muted-foreground">
              Son 6 ayda kötü sağlık oranı
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );

  const renderLifespanAnalysis = () => (
    <div className="space-y-6">
      {/* Yaşam Süresi Özeti */}
      <Card className="enhanced-card">
        <CardHeader>
          <CardTitle className="text-lg flex items-center gap-2">
            <Clock className="w-5 h-5" />
            Yaşam Süresi Analizi
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div className="text-center">
              <div className="text-2xl font-bold text-blue-600">
                {lifespanData.currentAge.toFixed(1)}
              </div>
              <div className="text-sm text-muted-foreground">Mevcut Yaş</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-green-600">
                {lifespanData.averageLifespan.toFixed(1)}
              </div>
              <div className="text-sm text-muted-foreground">Ortalama Yaşam</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-orange-600">
                {lifespanData.maxLifespan.toFixed(1)}
              </div>
              <div className="text-sm text-muted-foreground">Maksimum Yaşam</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-purple-600">
                {lifespanData.lifeExpectancy.toFixed(1)}
              </div>
              <div className="text-sm text-muted-foreground">Beklenen Yaşam</div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Yaşam Aşaması */}
      <Card className="enhanced-card">
        <CardHeader>
          <CardTitle className="text-sm flex items-center gap-2">
            <BarChart3 className="w-4 h-4" />
            Yaşam Aşaması
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-sm">Yaşam Aşaması</span>
              <Badge 
                variant={lifespanData.lifeStage === 'young' ? 'default' : 
                        lifespanData.lifeStage === 'adult' ? 'secondary' : 'destructive'}
              >
                {lifespanData.lifeStage === 'young' ? 'Genç' : 
                 lifespanData.lifeStage === 'adult' ? 'Yetişkin' : 'Yaşlı'}
              </Badge>
            </div>
            <Progress 
              value={(lifespanData.currentAge / lifespanData.lifeExpectancy) * 100} 
              className="h-3" 
            />
            <div className="text-xs text-muted-foreground">
              Yaşam yolculuğunun {Math.round((lifespanData.currentAge / lifespanData.lifeExpectancy) * 100)}%'i tamamlandı
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Aile Yaşam Süresi Karşılaştırması */}
      <Card className="enhanced-card">
        <CardHeader>
          <CardTitle className="text-sm flex items-center gap-2">
            <PieChart className="w-4 h-4" />
            Aile Yaşam Süresi Karşılaştırması
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            <div className="flex justify-between text-sm">
              <span>En Genç Üye</span>
              <span className="font-medium">{lifespanData.minLifespan.toFixed(1)} yıl</span>
            </div>
            <div className="flex justify-between text-sm">
              <span>Ortalama Yaşam</span>
              <span className="font-medium">{lifespanData.averageLifespan.toFixed(1)} yıl</span>
            </div>
            <div className="flex justify-between text-sm">
              <span>En Yaşlı Üye</span>
              <span className="font-medium">{lifespanData.maxLifespan.toFixed(1)} yıl</span>
            </div>
            <div className="text-xs text-muted-foreground mt-2">
              Aile içindeki yaşam süresi varyasyonu: {(lifespanData.maxLifespan - lifespanData.minLifespan).toFixed(1)} yıl
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );

  return (
    <Card className="enhanced-card">
      <CardHeader>
        <CardTitle className="text-lg flex items-center gap-2">
          🧬 Genetik Analiz ve İstatistikler
        </CardTitle>
      </CardHeader>
      <CardContent>
        <Tabs value={activeTab} onValueChange={setActiveTab}>
          <TabsList className="grid w-full grid-cols-4">
            <TabsTrigger value="traits">Genetik Özellikler</TabsTrigger>
            <TabsTrigger value="breeding">Üreme Başarısı</TabsTrigger>
            <TabsTrigger value="health">Sağlık Geçmişi</TabsTrigger>
            <TabsTrigger value="lifespan">Yaşam Süresi</TabsTrigger>
          </TabsList>
          
          <TabsContent value="traits" className="mt-6">
            {renderGeneticTraits()}
          </TabsContent>
          
          <TabsContent value="breeding" className="mt-6">
            {renderBreedingSuccess()}
          </TabsContent>
          
          <TabsContent value="health" className="mt-6">
            {renderHealthTrends()}
          </TabsContent>
          
          <TabsContent value="lifespan" className="mt-6">
            {renderLifespanAnalysis()}
          </TabsContent>
        </Tabs>
      </CardContent>
    </Card>
  );
};

export default GeneticAnalysis; 