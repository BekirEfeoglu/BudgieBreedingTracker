import React, { useState, useCallback } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { useLanguage } from '@/contexts/LanguageContext';
import { Bird, Chick } from '@/types';
import ComponentErrorBoundary from '@/components/errors/ComponentErrorBoundary';
import SimpleBirdList from './genealogy/SimpleBirdList';
import AdvancedFamilyTree from './genealogy/AdvancedFamilyTree';
import GenealogySearch, { GenealogyFilters } from './genealogy/GenealogySearch';

interface GenealogyViewProps {
  birds: Bird[];
  chicks?: Chick[];
  onBirdSelect: (bird: Bird | Chick) => void;
  isLoading?: boolean;
}

const GenealogyView: React.FC<GenealogyViewProps> = ({ 
  birds, 
  chicks = [], 
  onBirdSelect, 
  isLoading = false 
}) => {
  const { t } = useLanguage();
  const [selectedBird, setSelectedBird] = useState<Bird | Chick | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [filters, setFilters] = useState<GenealogyFilters>({
    gender: 'all',
    ageGroup: 'all',
    hasChildren: null,
    hasParents: null,
    generation: 'all'
  });

  // Gelişmiş aile verisi hesaplama
  const getFamilyData = useCallback((bird: Bird | Chick) => {
    const allBirds = [...birds, ...chicks];
    
    // Temel aile üyeleri - hem bird hem chick için doğru alanları kullan
    const father = allBirds.find(b => b.id === (bird.fatherId || (bird as any).father_id)) || null;
    const mother = allBirds.find(b => b.id === (bird.motherId || (bird as any).mother_id)) || null;
    const children = allBirds.filter(b => 
      (b.motherId || (b as any).mother_id) === bird.id || 
      (b.fatherId || (b as any).father_id) === bird.id
    ).slice(0, 8); // İlk 8 çocuk

    // Büyükanne/büyükbaba
    const grandparents = {
      paternalGrandfather: father ? allBirds.find(b => b.id === (father.fatherId || (father as any).father_id)) || null : null,
      paternalGrandmother: father ? allBirds.find(b => b.id === (father.motherId || (father as any).mother_id)) || null : null,
      maternalGrandfather: mother ? allBirds.find(b => b.id === (mother.fatherId || (mother as any).father_id)) || null : null,
      maternalGrandmother: mother ? allBirds.find(b => b.id === (mother.motherId || (mother as any).mother_id)) || null : null,
    };

    // Kardeşler (aynı anne-baba)
    const siblings = allBirds.filter(b => 
      b.id !== bird.id && 
      (((b.motherId || (b as any).mother_id) === (bird.motherId || (bird as any).mother_id) && (bird.motherId || (bird as any).mother_id)) || 
       ((b.fatherId || (b as any).father_id) === (bird.fatherId || (bird as any).father_id) && (bird.fatherId || (bird as any).father_id)))
    ).slice(0, 6);

    // Kuzenler (büyükanne/büyükbaba ortak)
    const cousins = allBirds.filter(b => {
      if (b.id === bird.id) return false;
      
      // Baba tarafı kuzenler
      const paternalCousins = father && (b.fatherId || (b as any).father_id) && (b.fatherId || (b as any).father_id) !== (bird.fatherId || (bird as any).father_id) && 
        (allBirds.find(p => p.id === (b.fatherId || (b as any).father_id))?.fatherId === (father.fatherId || (father as any).father_id) ||
         allBirds.find(p => p.id === (b.fatherId || (b as any).father_id))?.motherId === (father.motherId || (father as any).mother_id));
      
      // Anne tarafı kuzenler
      const maternalCousins = mother && (b.motherId || (b as any).mother_id) && (b.motherId || (b as any).mother_id) !== (bird.motherId || (bird as any).mother_id) &&
        (allBirds.find(p => p.id === (b.motherId || (b as any).mother_id))?.fatherId === (mother.fatherId || (mother as any).father_id) ||
         allBirds.find(p => p.id === (b.motherId || (b as any).mother_id))?.motherId === (mother.motherId || (mother as any).mother_id));
      
      return paternalCousins || maternalCousins;
    }).slice(0, 4);

    return {
      father,
      mother,
      children,
      grandparents,
      siblings,
      cousins
    };
  }, [birds, chicks]);

  const handleBirdSelect = useCallback((bird: Bird | Chick) => {
    setSelectedBird(bird);
    onBirdSelect?.(bird);
  }, [onBirdSelect]);

  // Loading durumu
  if (isLoading) {
    return (
      <div className="w-full h-80 border-2 border-border rounded-lg overflow-hidden bg-muted/20 flex items-center justify-center">
        <div className="text-center space-y-3">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto" aria-hidden="true"></div>
          <p className="text-sm enhanced-text-secondary">{t('common.loading')}</p>
        </div>
      </div>
    );
  }

  return (
    <ComponentErrorBoundary>
      <div className="space-y-4 pb-20 md:pb-4 px-2 md:px-0">
        {/* Header */}
        <div className="text-center px-2 sm:px-0">
          <h2 className="text-xl sm:text-2xl mb-2 enhanced-text-primary flex items-center justify-center gap-2">
            <span className="text-xl" aria-hidden="true">🌳</span>
            {t('genealogy.title')}
          </h2>
          <p className="enhanced-text-secondary text-sm">
            {t('genealogy.treeDescription')}
          </p>
        </div>

        {/* Arama ve Filtreleme */}
        <GenealogySearch
          birds={birds}
          chicks={chicks}
          searchTerm={searchTerm}
          filters={filters}
          onSearchChange={setSearchTerm}
          onFilterChange={setFilters}
        />

        {/* Kuş Listesi */}
        <SimpleBirdList
          birds={birds}
          chicks={chicks}
          onBirdSelect={handleBirdSelect}
          searchTerm={searchTerm}
          filters={filters}
        />

        {/* Gelişmiş Aile Ağacı */}
        <div className="w-full">
          {selectedBird ? (
            <AdvancedFamilyTree 
              selectedBird={selectedBird} 
              familyData={getFamilyData(selectedBird)}
              allBirds={[...birds, ...chicks]}
              onBirdSelect={handleBirdSelect}
            />
          ) : (
            <Card className="enhanced-card">
              <CardContent className="py-8">
                <div className="text-center enhanced-text-secondary py-8 px-4" role="status" aria-live="polite">
                  <span className="text-4xl mb-4 block" aria-hidden="true">🌳</span>
                  <h3 className="font-semibold mb-2 enhanced-text-primary text-sm sm:text-base">
                    {t('genealogy.selectBirdToView')}
                  </h3>
                  <p className="text-xs sm:text-sm max-w-xs mx-auto">
                    {t('genealogy.selectBirdDescription')}
                  </p>
                </div>
              </CardContent>
            </Card>
          )}
        </div>
      </div>
    </ComponentErrorBoundary>
  );
};

GenealogyView.displayName = 'GenealogyView';

export default GenealogyView;
