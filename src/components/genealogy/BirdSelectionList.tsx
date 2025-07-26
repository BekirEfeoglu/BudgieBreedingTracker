
import React, { useState, useMemo } from 'react';
import { FixedSizeList as List } from 'react-window';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Collapsible, CollapsibleContent, CollapsibleTrigger } from '@/components/ui/collapsible';
import { ChevronDown, Users, Baby } from 'lucide-react';
import BirdListItem from './BirdListItem';
import GenealogySearch from './GenealogySearch';
import { useGenealogyFilters } from './GenealogyFilters';
import { Bird, Chick } from '@/types';

interface BirdSelectionListProps {
  birds: Bird[];
  chicks: Chick[];
  selectedBird: Bird | Chick | null;
  onBirdSelect: (bird: Bird | Chick) => void;
}

const BirdItem = ({ index, style, data }: { index: number, style: any, data: any }) => {
  const { items, selectedBird, onBirdSelect, type } = data;
  const bird = items[index];
  
  return (
    <div style={style}>
      <div className="px-2 py-1">
        <BirdListItem 
          key={`${type}-${bird.id}`} 
          bird={bird} 
          type={type} 
          isSelected={selectedBird?.id === bird.id}
          onSelect={onBirdSelect}
        />
      </div>
    </div>
  );
};

const BirdSelectionList = ({ birds, chicks, selectedBird, onBirdSelect }: BirdSelectionListProps) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [genderFilter, setGenderFilter] = useState('all');
  const [typeFilter, setTypeFilter] = useState('all');
  const [isBirdsListOpen, setIsBirdsListOpen] = useState(true);
  const [isChicksListOpen, setIsChicksListOpen] = useState(true);

  const { filteredBirds, filteredChicks } = useGenealogyFilters({
    birds,
    chicks,
    searchTerm,
    genderFilter,
    typeFilter
  });

  const birdItemData = useMemo(() => ({
    items: filteredBirds,
    selectedBird,
    onBirdSelect,
    type: 'adult'
  }), [filteredBirds, selectedBird, onBirdSelect]);

  const chickItemData = useMemo(() => ({
    items: filteredChicks,
    selectedBird,
    onBirdSelect,
    type: 'chick'
  }), [filteredChicks, selectedBird, onBirdSelect]);

  return (
    <div className="w-full lg:w-1/3 space-y-4">
      <div className="text-center lg:text-left">
        <h2 className="text-xl md:text-2xl font-bold mb-2 enhanced-text-primary flex items-center justify-center lg:justify-start gap-2">
          <span className="text-xl">🌳</span>
          Soy Ağacı
        </h2>
        <p className="enhanced-text-secondary text-sm">
          Bir kuş veya yavru seçerek soy ağacını görüntüleyin
        </p>
      </div>

      {/* Arama ve Filtreler */}
      <GenealogySearch
        searchTerm={searchTerm}
        onSearchChange={setSearchTerm}
        genderFilter={genderFilter}
        onGenderFilterChange={setGenderFilter}
        typeFilter={typeFilter}
        onTypeFilterChange={setTypeFilter}
      />

      {/* Sonuç Sayısı */}
      <div className="text-sm enhanced-text-secondary text-center lg:text-left">
        {filteredBirds.length + filteredChicks.length} sonuç bulundu
      </div>

      {/* Kuş ve Yavru Listesi */}
      <Card className="enhanced-card">
        <CardHeader className="pb-2">
          <CardTitle className="text-base enhanced-text-primary">
            Kuş ve Yavru Seç
          </CardTitle>
        </CardHeader>
        <CardContent className="pt-0 space-y-3">
          
          {/* Yetişkin Kuşlar */}
          {(typeFilter === 'all' || typeFilter === 'adult') && (
            <Collapsible open={isBirdsListOpen} onOpenChange={setIsBirdsListOpen}>
              <CollapsibleTrigger className="flex items-center justify-between w-full p-2 rounded-lg hover:bg-accent/50 transition-colors touch-button">
                <div className="flex items-center gap-2">
                  <Users className="w-4 h-4 text-primary" />
                  <span className="font-medium text-sm enhanced-text-primary">
                    Yetişkin Kuşlar ({filteredBirds.length})
                  </span>
                </div>
                <ChevronDown className={`w-4 h-4 transition-transform duration-200 ${isBirdsListOpen ? 'rotate-180' : ''}`} />
              </CollapsibleTrigger>
              <CollapsibleContent>
                <div className="mt-2">
                  {filteredBirds.length === 0 ? (
                    <div className="text-center py-4 enhanced-text-secondary">
                      <p className="text-sm">Kuş bulunamadı</p>
                    </div>
                  ) : (
                    <List
                      height={Math.min(filteredBirds.length * 80, 240)}
                      itemCount={filteredBirds.length}
                      itemSize={80}
                      itemData={birdItemData}
                      width="100%"
                      className="mobile-scroll-container"
                    >
                      {BirdItem}
                    </List>
                  )}
                </div>
              </CollapsibleContent>
            </Collapsible>
          )}

          {/* Yavrular */}
          {(typeFilter === 'all' || typeFilter === 'chick') && (
            <Collapsible open={isChicksListOpen} onOpenChange={setIsChicksListOpen}>
              <CollapsibleTrigger className="flex items-center justify-between w-full p-2 rounded-lg hover:bg-accent/50 transition-colors touch-button">
                <div className="flex items-center gap-2">
                  <Baby className="w-4 h-4 text-orange-500" />
                  <span className="font-medium text-sm enhanced-text-primary">
                    Yavrular ({filteredChicks.length})
                  </span>
                </div>
                <ChevronDown className={`w-4 h-4 transition-transform duration-200 ${isChicksListOpen ? 'rotate-180' : ''}`} />
              </CollapsibleTrigger>
              <CollapsibleContent>
                <div className="mt-2">
                  {filteredChicks.length === 0 ? (
                    <div className="text-center py-4 enhanced-text-secondary">
                      <p className="text-sm">Yavru bulunamadı</p>
                    </div>
                  ) : (
                    <List
                      height={Math.min(filteredChicks.length * 80, 240)}
                      itemCount={filteredChicks.length}
                      itemSize={80}
                      itemData={chickItemData}
                      width="100%"
                      className="mobile-scroll-container"
                    >
                      {BirdItem}
                    </List>
                  )}
                </div>
              </CollapsibleContent>
            </Collapsible>
          )}
        </CardContent>
      </Card>
    </div>
  );
};

export default BirdSelectionList;
