import React, { useState, useCallback, useMemo } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { 
  ChevronLeft, 
  ChevronRight, 
  Users, 
  Heart, 
  Baby, 
  Calendar,
  Info,
  Share2,
  Download,
  TreePine
} from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';
import { Bird, Chick } from '@/types';
import { format } from 'date-fns';
import { tr } from 'date-fns/locale';
import GeneticAnalysis from './GeneticAnalysis';
import ExportTools from './ExportTools';

interface FamilyData {
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
}

interface AdvancedFamilyTreeProps {
  selectedBird: Bird | Chick;
  familyData: FamilyData;
  allBirds: (Bird | Chick)[];
  onBirdSelect: (bird: Bird | Chick) => void;
}

const AdvancedFamilyTree: React.FC<AdvancedFamilyTreeProps> = ({
  selectedBird,
  familyData,
  allBirds,
  onBirdSelect
}) => {
  const { t } = useLanguage();
  const [selectedForDetail, setSelectedForDetail] = useState<Bird | Chick | null>(null);
  const [activeView, setActiveView] = useState<'tree' | 'timeline' | 'stats'>('tree');
  const [generation, setGeneration] = useState(2); // 2 = parents, 3 = grandparents

  const getBirdAge = useCallback((bird: Bird | Chick) => {
    const birthDate = 'hatchDate' in bird ? bird.hatchDate : bird.birthDate;
    if (!birthDate) return null;
    
    const age = Math.floor((new Date().getTime() - new Date(birthDate).getTime()) / (1000 * 60 * 60 * 24));
    if (age < 30) return `${age} gün`;
    if (age < 365) return `${Math.floor(age / 30)} ay`;
    return `${Math.floor(age / 365)} yıl`;
  }, []);

  const getBirdStats = useMemo(() => {
    const totalFamily = [
      familyData.father,
      familyData.mother,
      ...familyData.children,
      ...Object.values(familyData.grandparents).filter(Boolean),
      ...familyData.siblings,
      ...familyData.cousins
    ].filter(Boolean);

    const genderStats = totalFamily.reduce((acc, bird) => {
      if (bird) {
        acc[bird.gender] = (acc[bird.gender] || 0) + 1;
      }
      return acc;
    }, {} as Record<string, number>);

    const ageStats = totalFamily.reduce((acc, bird) => {
      if (bird) {
        const age = getBirdAge(bird);
        if (age) {
          if (age.includes('gün')) acc.young++;
          else if (age.includes('ay')) acc.young++;
          else if (parseInt(age) < 5) acc.adult++;
          else acc.old++;
        }
      }
      return acc;
    }, { young: 0, adult: 0, old: 0 });

    return {
      total: totalFamily.length,
      genderStats,
      ageStats,
      generations: generation
    };
  }, [familyData, generation, getBirdAge]);

  const renderBirdCard = useCallback((bird: Bird | Chick, title: string, size: 'sm' | 'md' | 'lg' = 'md') => {
    if (!bird) return null;
    
    const age = getBirdAge(bird);
    const birthDate = 'hatchDate' in bird ? bird.hatchDate : bird.birthDate;
    const isChick = 'hatchDate' in bird;
    
    const sizeClasses = {
      sm: 'w-12 h-12 md:w-16 md:h-16 text-xs md:text-sm',
      md: 'w-16 h-16 md:w-20 md:h-20 text-sm md:text-base',
      lg: 'w-20 h-20 md:w-24 md:h-24 text-base md:text-lg'
    };

    return (
      <Card 
        className="enhanced-card cursor-pointer hover:shadow-md transition-all duration-200 hover:scale-105"
        onClick={() => onBirdSelect(bird)}
      >
        <CardContent className={`p-2 md:p-3 ${size === 'sm' ? 'p-1 md:p-2' : size === 'lg' ? 'p-3 md:p-4' : 'p-2 md:p-3'}`}>
          <div className="flex flex-col items-center text-center space-y-1 md:space-y-2">
            {bird.photo ? (
              <img 
                src={bird.photo} 
                alt={bird.name}
                className={`${sizeClasses[size]} rounded-full object-cover border-2 border-white shadow-md`}
              />
            ) : (
              <div className={`${sizeClasses[size]} rounded-full bg-gradient-to-br from-blue-100 to-blue-200 flex items-center justify-center border-2 border-white shadow-md`}>
                {bird.gender === 'male' ? '♂️' : bird.gender === 'female' ? '♀️' : '❓'}
              </div>
            )}
            
            <div className="space-y-0.5 md:space-y-1">
              <h4 className={`font-semibold truncate w-full ${size === 'sm' ? 'text-xs' : 'text-sm'}`}>
                {bird.name}
              </h4>
              <p className={`text-muted-foreground ${size === 'sm' ? 'text-xs' : 'text-sm'}`}>
                {title}
              </p>
              {bird.ringNumber && (
                <p className={`text-muted-foreground font-mono ${size === 'sm' ? 'text-xs' : 'text-sm'}`}>
                  {bird.ringNumber}
                </p>
              )}
              {age && (
                <Badge variant="secondary" className={`${size === 'sm' ? 'text-xs px-1 py-0.5' : 'text-sm px-2 py-1'}`}>
                  {age}
                </Badge>
              )}
            </div>
          </div>
        </CardContent>
      </Card>
    );
  }, [getBirdAge, onBirdSelect]);

  const renderTimeline = useCallback(() => {
    const timelineData = [
      { bird: familyData.father, title: 'Baba', position: 'left' },
      { bird: familyData.mother, title: 'Anne', position: 'right' },
      { bird: selectedBird, title: 'Seçili Kuş', position: 'center' },
      ...familyData.children.map((child, index) => ({ 
        bird: child, 
        title: `Çocuk ${index + 1}`, 
        position: 'bottom' 
      }))
    ].filter(item => item.bird);

    return (
      <div className="space-y-6">
        <div className="text-center">
          <h3 className="text-lg font-semibold mb-2">Aile Zaman Çizelgesi</h3>
          <p className="text-sm text-muted-foreground">Kuşların doğum tarihlerine göre sıralanmış</p>
        </div>
        
        <div className="relative">
          <div className="absolute left-1/2 top-0 bottom-0 w-0.5 bg-border transform -translate-x-1/2"></div>
          
                     {timelineData
             .filter(item => item.bird)
             .sort((a, b) => {
               if (!a.bird || !b.bird) return 0;
               const aDate = 'hatchDate' in a.bird ? a.bird.hatchDate : a.bird.birthDate;
               const bDate = 'hatchDate' in b.bird ? b.bird.hatchDate : b.bird.birthDate;
               if (!aDate || !bDate) return 0;
               return new Date(aDate).getTime() - new Date(bDate).getTime();
             })
             .map((item, index) => {
               if (!item.bird) return null;
               const birthDate = 'hatchDate' in item.bird ? item.bird.hatchDate : item.bird.birthDate;
               return (
                 <div key={`timeline-${index}-${item.bird.id}`} className="relative flex items-center justify-center py-4">
                   <div className="absolute left-1/2 w-3 h-3 bg-primary rounded-full transform -translate-x-1/2"></div>
                   <div className="flex items-center gap-4">
                     {renderBirdCard(item.bird, item.title, 'sm')}
                     {birthDate && (
                       <div className="text-sm text-muted-foreground">
                         {format(new Date(birthDate), 'dd MMM yyyy', { locale: tr })}
                       </div>
                     )}
                   </div>
                 </div>
               );
             })}
        </div>
      </div>
    );
  }, [familyData, selectedBird, renderBirdCard]);

  const renderStats = useCallback(() => {
    return (
      <div className="space-y-6">
        <div className="text-center">
          <h3 className="text-lg font-semibold mb-2">Aile İstatistikleri</h3>
          <p className="text-sm text-muted-foreground">Soyağacı analizi</p>
        </div>
        
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <Card>
            <CardContent className="p-4 text-center">
              <Users className="w-8 h-8 mx-auto mb-2 text-blue-500" />
              <div className="text-2xl font-bold">{getBirdStats.total}</div>
              <div className="text-sm text-muted-foreground">Toplam Aile</div>
            </CardContent>
          </Card>
          
          <Card>
            <CardContent className="p-4 text-center">
              <Heart className="w-8 h-8 mx-auto mb-2 text-pink-500" />
              <div className="text-2xl font-bold">{familyData.children.length}</div>
              <div className="text-sm text-muted-foreground">Çocuk</div>
            </CardContent>
          </Card>
          
          <Card>
            <CardContent className="p-4 text-center">
              <Baby className="w-8 h-8 mx-auto mb-2 text-green-500" />
              <div className="text-2xl font-bold">{getBirdStats.ageStats.young}</div>
              <div className="text-sm text-muted-foreground">Genç</div>
            </CardContent>
          </Card>
          
          <Card>
            <CardContent className="p-4 text-center">
              <Calendar className="w-8 h-8 mx-auto mb-2 text-orange-500" />
              <div className="text-2xl font-bold">{generation}</div>
              <div className="text-sm text-muted-foreground">Nesil</div>
            </CardContent>
          </Card>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Cinsiyet Dağılımı</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-2">
                {Object.entries(getBirdStats.genderStats).map(([gender, count], index) => (
                  <div key={`gender-${index}-${gender}`} className="flex items-center justify-between">
                    <span className="text-sm">
                      {gender === 'male' ? '♂️ Erkek' : gender === 'female' ? '♀️ Dişi' : '❓ Bilinmiyor'}
                    </span>
                    <Badge variant="secondary">{count}</Badge>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-base">Yaş Dağılımı</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-sm">🐣 Genç</span>
                  <Badge variant="secondary">{getBirdStats.ageStats.young}</Badge>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm">🐦 Yetişkin</span>
                  <Badge variant="secondary">{getBirdStats.ageStats.adult}</Badge>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm">🦅 Yaşlı</span>
                  <Badge variant="secondary">{getBirdStats.ageStats.old}</Badge>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    );
  }, [getBirdStats, familyData.children.length, generation]);

  const renderDetailModal = () => {
    if (!selectedForDetail) return null;
    
    const age = getBirdAge(selectedForDetail);
    const isChick = 'hatchDate' in selectedForDetail;
    const birthDate = 'hatchDate' in selectedForDetail ? selectedForDetail.hatchDate : selectedForDetail.birthDate;
    
    return (
      <Dialog open={!!selectedForDetail} onOpenChange={() => setSelectedForDetail(null)}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-3">
              {selectedForDetail.photo ? (
                <img 
                  src={selectedForDetail.photo} 
                  alt={selectedForDetail.name}
                  className="w-12 h-12 rounded-full object-cover"
                />
              ) : (
                <div className="w-12 h-12 rounded-full bg-gradient-to-br from-blue-100 to-blue-200 flex items-center justify-center text-xl">
                  {selectedForDetail.gender === 'male' ? '♂️' : selectedForDetail.gender === 'female' ? '♀️' : '❓'}
                </div>
              )}
              <div>
                <div className="font-semibold">{selectedForDetail.name}</div>
                {selectedForDetail.ringNumber && (
                  <div className="text-sm text-muted-foreground">{selectedForDetail.ringNumber}</div>
                )}
              </div>
            </DialogTitle>
          </DialogHeader>
          
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-sm font-medium text-gray-600">Cinsiyet</label>
                <div className="flex items-center gap-2 py-2 px-3 bg-muted/30 rounded-lg mt-1">
                  <span className="text-lg">
                    {selectedForDetail.gender === 'male' ? '♂️' : selectedForDetail.gender === 'female' ? '♀️' : '❓'}
                  </span>
                  <span className="text-sm">
                    {selectedForDetail.gender === 'male' ? 'Erkek' : selectedForDetail.gender === 'female' ? 'Dişi' : 'Bilinmiyor'}
                  </span>
                </div>
              </div>
              
              {age && (
                <div>
                  <label className="text-sm font-medium text-gray-600">Yaş</label>
                  <div className="py-2 px-3 bg-muted/30 rounded-lg mt-1">
                    <p className="text-sm">{age}</p>
                  </div>
                </div>
              )}
            </div>
            
            {selectedForDetail.color && (
              <div>
                <label className="text-sm font-medium text-gray-600">Renk</label>
                <div className="flex items-center gap-3 py-2 px-3 bg-muted/30 rounded-lg mt-1">
                  <div 
                    className="w-6 h-6 rounded-full border-2 border-gray-300"
                    style={{ backgroundColor: selectedForDetail.color }}
                  />
                  <p className="text-sm">{selectedForDetail.color}</p>
                </div>
              </div>
            )}
            
            {birthDate && (
              <div>
                <label className="text-sm font-medium text-gray-600">
                  {isChick ? 'Çıkış Tarihi' : 'Doğum Tarihi'}
                </label>
                <div className="py-2 px-3 bg-muted/30 rounded-lg mt-1">
                  <p className="text-sm">
                    {format(new Date(birthDate), 'dd MMMM yyyy', { locale: tr })}
                  </p>
                </div>
              </div>
            )}
            
            {selectedForDetail.healthNotes && (
              <div>
                <label className="text-sm font-medium text-gray-600">Sağlık Notları</label>
                <div className="py-3 px-3 bg-muted/30 rounded-lg mt-1">
                  <p className="text-sm leading-relaxed">{selectedForDetail.healthNotes}</p>
                </div>
              </div>
            )}
          </div>
        </DialogContent>
      </Dialog>
    );
  };

  return (
    <div className="space-y-4 md:space-y-6">
      <Card className="enhanced-card">
        <CardHeader className="pb-4">
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
            <CardTitle className="text-base md:text-lg flex items-center gap-2">
              🌳 {selectedBird.name} - Gelişmiş Soyağacı
            </CardTitle>
            <div className="flex items-center gap-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setGeneration(Math.max(2, generation - 1))}
                disabled={generation <= 2}
                className="h-8 px-2"
              >
                <ChevronLeft className="w-3 h-3 md:w-4 md:h-4" />
              </Button>
              <Badge variant="secondary" className="text-xs md:text-sm px-2 py-1">
                {generation} Nesil
              </Badge>
              <Button
                variant="outline"
                size="sm"
                onClick={() => setGeneration(Math.min(4, generation + 1))}
                disabled={generation >= 4}
                className="h-8 px-2"
              >
                <ChevronRight className="w-3 h-3 md:w-4 md:h-4" />
              </Button>
            </div>
          </div>
        </CardHeader>
        <CardContent className="pt-0">
          <Tabs value={activeView} onValueChange={(value) => setActiveView(value as any)}>
            <TabsList className="grid w-full grid-cols-3 md:grid-cols-5 mb-4 md:mb-6 h-auto">
              <TabsTrigger value="tree" className="text-xs md:text-sm py-2">Ağaç</TabsTrigger>
              <TabsTrigger value="genetic" className="text-xs md:text-sm py-2">Genetik</TabsTrigger>
              <TabsTrigger value="export" className="text-xs md:text-sm py-2">Dışa Aktar</TabsTrigger>
              <TabsTrigger value="timeline" className="text-xs md:text-sm py-2">Zaman</TabsTrigger>
              <TabsTrigger value="stats" className="text-xs md:text-sm py-2">İstatistik</TabsTrigger>
            </TabsList>
            
            <TabsContent value="tree" className="space-y-4 md:space-y-6">
              {/* Grandparents */}
              {generation >= 3 && (
                <div className="text-center">
                  <h3 className="text-sm md:text-base font-semibold mb-3 md:mb-4">Büyükanne/Büyükbaba</h3>
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-2 md:gap-4">
                    {familyData.grandparents.paternalGrandfather && renderBirdCard(familyData.grandparents.paternalGrandfather, 'Büyükbaba (Baba)', 'sm')}
                    {familyData.grandparents.paternalGrandmother && renderBirdCard(familyData.grandparents.paternalGrandmother, 'Büyükanne (Baba)', 'sm')}
                    {familyData.grandparents.maternalGrandfather && renderBirdCard(familyData.grandparents.maternalGrandfather, 'Büyükbaba (Anne)', 'sm')}
                    {familyData.grandparents.maternalGrandmother && renderBirdCard(familyData.grandparents.maternalGrandmother, 'Büyükanne (Anne)', 'sm')}
                  </div>
                </div>
              )}

              {/* Parents */}
              <div className="text-center">
                <h3 className="text-sm md:text-base font-semibold mb-3 md:mb-4">Ebeveynler</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-3 md:gap-4 max-w-sm md:max-w-md mx-auto">
                  {familyData.father && renderBirdCard(familyData.father, 'Baba', 'md')}
                  {familyData.mother && renderBirdCard(familyData.mother, 'Anne', 'md')}
                </div>
              </div>

              {/* Selected Bird */}
              <div className="text-center">
                <h3 className="text-sm md:text-base font-semibold mb-3 md:mb-4">Seçili Kuş</h3>
                <div className="flex justify-center">
                  {renderBirdCard(selectedBird, 'Seçili Kuş', 'lg')}
                </div>
              </div>

              {/* Children */}
              {familyData.children.length > 0 && (
                <div className="text-center">
                  <h3 className="text-sm md:text-base font-semibold mb-3 md:mb-4">Çocuklar ({familyData.children.length})</h3>
                  <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-2 md:gap-4">
                    {familyData.children.map((child, index) => 
                      <div key={`child-${index}-${child.id}`}>
                        {renderBirdCard(child, `Çocuk ${index + 1}`, 'sm')}
                      </div>
                    )}
                  </div>
                </div>
              )}

              {/* Siblings */}
              {familyData.siblings.length > 0 && (
                <div className="text-center">
                  <h3 className="text-sm md:text-base font-semibold mb-3 md:mb-4">Kardeşler ({familyData.siblings.length})</h3>
                  <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-2 md:gap-4">
                    {familyData.siblings.map((sibling, index) => 
                      <div key={`sibling-${index}-${sibling.id}`}>
                        {renderBirdCard(sibling, `Kardeş ${index + 1}`, 'sm')}
                      </div>
                    )}
                  </div>
                </div>
              )}
            </TabsContent>
            

            
            <TabsContent value="genetic">
              <GeneticAnalysis
                familyData={familyData}
                selectedBird={selectedBird}
              />
            </TabsContent>
            
            <TabsContent value="export">
              <ExportTools
                familyData={familyData}
                selectedBird={selectedBird}
              />
            </TabsContent>
            
            <TabsContent value="timeline">
              {renderTimeline()}
            </TabsContent>
            
            <TabsContent value="stats">
              {renderStats()}
            </TabsContent>
          </Tabs>
        </CardContent>
      </Card>

      {renderDetailModal()}
    </div>
  );
};

export default AdvancedFamilyTree; 