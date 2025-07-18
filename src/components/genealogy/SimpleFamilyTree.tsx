import React, { useState, useCallback } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { useLanguage } from '@/contexts/LanguageContext';
import { Bird, Chick } from '@/types';
import { useIsMobile } from '@/hooks/useMediaQuery';
import { format } from 'date-fns';
import { tr } from 'date-fns/locale';

interface FamilyData {
  father: Bird | Chick | null;
  mother: Bird | Chick | null;
  children: (Bird | Chick)[];
}

interface SimpleFamilyTreeProps {
  selectedBird: Bird | Chick;
  familyData: FamilyData;
}

const SimpleFamilyTree: React.FC<SimpleFamilyTreeProps> = ({ selectedBird, familyData }) => {
  const { t } = useLanguage();
  const isMobile = useIsMobile();
  const [selectedForDetail, setSelectedForDetail] = useState<Bird | Chick | null>(null);

  const handleBirdClick = useCallback((bird: Bird | Chick) => {
    setSelectedForDetail(bird);
  }, []);

  const getBirdAge = useCallback((bird: Bird | Chick) => {
    const birthDate = 'hatchDate' in bird ? bird.hatchDate : bird.birthDate;
    if (!birthDate) return null;
    
    const age = Math.floor((new Date().getTime() - new Date(birthDate).getTime()) / (1000 * 60 * 60 * 24));
    if (age < 30) return `${age} gün`;
    if (age < 365) return `${Math.floor(age / 30)} ay`;
    return `${Math.floor(age / 365)} yıl`;
  }, []);

  const renderBirdCard = useCallback((bird: Bird | Chick, title: string) => {
    if (!bird) return null;
    
    const age = getBirdAge(bird);
    const birthDate = 'hatchDate' in bird ? bird.hatchDate : bird.birthDate;
    
    return (
      <Card className="enhanced-card cursor-pointer hover:shadow-md transition-shadow" onClick={() => handleBirdClick(bird)}>
        <CardContent className="p-4">
          <div className="flex items-center gap-3">
            {bird.photo ? (
              <img 
                src={bird.photo} 
                alt={bird.name}
                className="w-12 h-12 rounded-full object-cover"
              />
            ) : (
              <div className="w-12 h-12 rounded-full bg-gradient-to-br from-blue-100 to-blue-200 flex items-center justify-center text-xl">
                {bird.gender === 'male' ? '♂️' : bird.gender === 'female' ? '♀️' : '❓'}
              </div>
            )}
            <div className="flex-1 min-w-0">
              <h4 className="font-semibold text-sm truncate">{bird.name}</h4>
              <p className="text-xs text-muted-foreground truncate">{title}</p>
              {bird.ringNumber && (
                <p className="text-xs text-muted-foreground font-mono">{bird.ringNumber}</p>
              )}
              {age && (
                <p className="text-xs text-muted-foreground">{age}</p>
              )}
            </div>
          </div>
        </CardContent>
      </Card>
    );
  }, [getBirdAge, handleBirdClick]);

  const renderDetailModal = () => {
    if (!selectedForDetail) return null;
    
    const age = getBirdAge(selectedForDetail);
    const isChick = 'hatchDate' in selectedForDetail;
    const birthDate = 'hatchDate' in selectedForDetail ? selectedForDetail.hatchDate : selectedForDetail.birthDate;
    
    return (
      <Dialog open={!!selectedForDetail} onOpenChange={() => setSelectedForDetail(null)}>
        <DialogContent className={`${isMobile ? 'max-w-[95vw] max-h-[95vh] w-full' : 'max-w-md'} mobile-modal`}>
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
    <div className="space-y-6">
      <Card className="enhanced-card">
        <CardHeader>
          <CardTitle className="text-lg flex items-center gap-2">
            🌳 {selectedBird.name} - {t('genealogy.familyTree')}
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-6">
          {/* Ebeveynler */}
          <div>
            <h3 className="font-semibold mb-3 text-sm">{t('genealogy.parents')}</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              {familyData.father && renderBirdCard(familyData.father, t('genealogy.father'))}
              {familyData.mother && renderBirdCard(familyData.mother, t('genealogy.mother'))}
            </div>
          </div>

          {/* Çocuklar */}
          {familyData.children.length > 0 && (
            <div>
              <h3 className="font-semibold mb-3 text-sm">{t('genealogy.children')}</h3>
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
                {familyData.children.slice(0, 6).map((child) => (
                  <div key={child.id}>
                    {renderBirdCard(child, t('genealogy.child'))}
                  </div>
                ))}
              </div>
              {familyData.children.length > 6 && (
                <p className="text-sm text-muted-foreground mt-2">
                  +{familyData.children.length - 6} {t('genealogy.moreChildren')}
                </p>
              )}
            </div>
          )}

          {/* Ebeveyn yoksa bilgi mesajı */}
          {!familyData.father && !familyData.mother && familyData.children.length === 0 && (
            <div className="text-center py-8 text-muted-foreground">
              <p className="text-sm">Bu kuş için henüz aile bilgisi girilmemiş.</p>
            </div>
          )}
        </CardContent>
      </Card>

      {renderDetailModal()}
    </div>
  );
};

export default SimpleFamilyTree;