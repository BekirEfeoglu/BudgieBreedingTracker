import React, { useState, useCallback, useMemo } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Collapsible, CollapsibleContent, CollapsibleTrigger } from '@/components/ui/collapsible';
import { 
  ChevronDown, 
  ChevronUp, 
  Heart, 
  Clock, 
  Star,
  Users,
  Baby,
  Calendar
} from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';
import { Bird, Chick } from '@/types';
import { useBirdHistory } from '@/hooks/useBirdHistory';
import { useBirdFilters } from '@/hooks/useBirdFilters';
import { GenealogyFilters } from './GenealogySearch';

interface SimpleBirdListProps {
  birds: Bird[];
  chicks: Chick[];
  onBirdSelect: (bird: Bird | Chick) => void;
  searchTerm?: string;
  filters?: GenealogyFilters;
}

const SimpleBirdList: React.FC<SimpleBirdListProps> = ({
  birds,
  chicks,
  onBirdSelect,
  searchTerm = '',
  filters
}) => {
  const { t } = useLanguage();
  const [isExpanded, setIsExpanded] = useState(true); // Varsayılan olarak açık
  const [sortBy, setSortBy] = useState<'name' | 'recent' | 'favorites' | 'age'>('name');
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('asc');

  const { favorites, addToFavorites, removeFromFavorites } = useBirdHistory();
  const { applyFilters } = useBirdFilters();

  // Kuş yaşını hesapla
  const getBirdAge = useCallback((bird: Bird | Chick) => {
    const birthDate = 'hatchDate' in bird ? bird.hatchDate : bird.birthDate;
    if (!birthDate) return null;
    
    const age = Math.floor((new Date().getTime() - new Date(birthDate).getTime()) / (1000 * 60 * 60 * 24));
    if (age < 30) return `${age} gün`;
    if (age < 365) return `${Math.floor(age / 30)} ay`;
    return `${Math.floor(age / 365)} yıl`;
  }, []);

  // Kuşun çocuğu var mı?
  const hasChildren = useCallback((bird: Bird | Chick) => {
    return [...birds, ...chicks].some(b => 
      b.motherId === bird.id || b.fatherId === bird.id
    );
  }, [birds, chicks]);

  // Kuşun ebeveyni var mı?
  const hasParents = useCallback((bird: Bird | Chick) => {
    return !!(bird.motherId || bird.fatherId);
  }, []);

  // Kuşun neslini hesapla
  const getGeneration = useCallback((bird: Bird | Chick): number => {
    let generation = 1;
    let currentBird = bird;
    
    while (currentBird.motherId || currentBird.fatherId) {
      const parent = birds.find(b => b.id === currentBird.motherId || b.id === currentBird.fatherId);
      if (!parent) break;
      generation++;
      currentBird = parent;
    }
    
    return generation;
  }, [birds]);

  // Filtreleme fonksiyonu
  const applyGenealogyFilters = useCallback((bird: Bird | Chick) => {
    if (!filters) return true;

    // Cinsiyet filtresi
    if (filters.gender !== 'all' && bird.gender !== filters.gender) {
      return false;
    }

    // Yaş grubu filtresi
    if (filters.ageGroup !== 'all') {
      const age = getBirdAge(bird);
      if (age) {
        if (age.includes('gün') || age.includes('ay')) {
          if (filters.ageGroup !== 'young') return false;
        } else if (parseInt(age) < 5) {
          if (filters.ageGroup !== 'adult') return false;
        } else {
          if (filters.ageGroup !== 'old') return false;
        }
      }
    }

    // Çocuk filtresi
    if (filters.hasChildren !== null) {
      const hasKids = hasChildren(bird);
      if (hasKids !== filters.hasChildren) {
        return false;
      }
    }

    // Ebeveyn filtresi
    if (filters.hasParents !== null) {
      const hasParentsBool = hasParents(bird);
      if (hasParentsBool !== filters.hasParents) {
        return false;
      }
    }

    // Nesil filtresi
    if (filters.generation !== 'all') {
      const generation = getGeneration(bird);
      if (generation.toString() !== filters.generation) {
        return false;
      }
    }

    // Renk filtresi
    if (filters.color && bird.color !== filters.color) {
      return false;
    }

    // Halka numarası filtresi
    if (filters.ringNumber && bird.ringNumber && !bird.ringNumber.includes(filters.ringNumber)) {
      return false;
    }

    return true;
  }, [filters, getBirdAge, hasChildren, hasParents, getGeneration]);

  // Filtrelenmiş ve sıralanmış kuşlar
  const filteredAndSortedBirds = useMemo(() => {
    const allBirds = [...birds, ...chicks];
    
    // Önce arama ve filtreleme
    const filtered = allBirds.filter(bird => {
      // Arama terimi
      const matchesSearch = !searchTerm || 
        bird.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        bird.ringNumber?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        bird.color?.toLowerCase().includes(searchTerm.toLowerCase());

      if (!matchesSearch) return false;

      // Genealogy filtreleri
      return applyGenealogyFilters(bird);
    });

    // Sonra sıralama
    filtered.sort((a, b) => {
      let comparison = 0;

      switch (sortBy) {
        case 'name':
          comparison = a.name.localeCompare(b.name);
          break;
        case 'recent':
          const aDate = 'hatchDate' in a ? a.hatchDate : a.birthDate;
          const bDate = 'hatchDate' in b ? b.hatchDate : b.birthDate;
          if (aDate && bDate) {
            comparison = new Date(bDate).getTime() - new Date(aDate).getTime();
          }
          break;
        case 'favorites':
          const aFav = favorites.includes(a.id);
          const bFav = favorites.includes(b.id);
          comparison = aFav === bFav ? 0 : aFav ? -1 : 1;
          break;
        case 'age':
          const aAge = getBirdAge(a);
          const bAge = getBirdAge(b);
          if (aAge && bAge) {
            const aDays = aAge.includes('gün') ? parseInt(aAge) : 
                         aAge.includes('ay') ? parseInt(aAge) * 30 : 
                         parseInt(aAge) * 365;
            const bDays = bAge.includes('gün') ? parseInt(bAge) : 
                         bAge.includes('ay') ? parseInt(bAge) * 30 : 
                         parseInt(bAge) * 365;
            comparison = aDays - bDays;
          }
          break;
      }

      return sortOrder === 'asc' ? comparison : -comparison;
    });

    return filtered;
  }, [birds, chicks, searchTerm, filters, sortBy, sortOrder, favorites, applyGenealogyFilters, getBirdAge]);

  const handleSortChange = useCallback((newSortBy: typeof sortBy) => {
    if (sortBy === newSortBy) {
      setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc');
    } else {
      setSortBy(newSortBy);
      setSortOrder('asc');
    }
  }, [sortBy, sortOrder]);

  const toggleFavorite = useCallback((birdId: string, event: React.MouseEvent) => {
    event.stopPropagation();
    if (favorites.includes(birdId)) {
      removeFromFavorites(birdId);
    } else {
      addToFavorites(birdId);
    }
  }, [favorites, addToFavorites, removeFromFavorites]);

  const renderBirdCard = useCallback((bird: Bird | Chick) => {
    const age = getBirdAge(bird);
    const isFavorite = favorites.includes(bird.id);
    const hasKids = hasChildren(bird);
    const hasParentsBool = hasParents(bird);
    const generation = getGeneration(bird);

    const handleBirdClick = () => {
      onBirdSelect(bird);
      setIsExpanded(false); // Kuş seçildiğinde listeyi kapat
    };

    return (
      <Card 
        key={bird.id}
        className="enhanced-card cursor-pointer hover:shadow-md transition-all duration-200 hover:scale-105"
        onClick={handleBirdClick}
      >
        <CardContent className="p-3 md:p-4">
          <div className="flex items-center gap-2 md:gap-3">
            {/* Fotoğraf */}
            {bird.photo ? (
              <img 
                src={bird.photo} 
                alt={bird.name}
                className="w-10 h-10 md:w-12 md:h-12 rounded-full object-cover border-2 border-white shadow-md"
              />
            ) : (
              <div className="w-10 h-10 md:w-12 md:h-12 rounded-full bg-gradient-to-br from-blue-100 to-blue-200 flex items-center justify-center border-2 border-white shadow-md">
                {bird.gender === 'male' ? '♂️' : bird.gender === 'female' ? '♀️' : '❓'}
              </div>
            )}

            {/* Bilgiler */}
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2 mb-1">
                <h4 className="font-semibold truncate text-xs md:text-sm">
                  {bird.name}
                </h4>
                <Button
                  variant="ghost"
                  size="sm"
                  className="h-6 w-6 p-0 ml-auto"
                  onClick={(e) => toggleFavorite(bird.id, e)}
                >
                  <Heart 
                    className={`w-3 h-3 md:w-4 md:h-4 ${isFavorite ? 'fill-red-500 text-red-500' : 'text-gray-400'}`} 
                  />
                </Button>
              </div>

              <div className="flex flex-wrap gap-1 mb-2">
                {bird.ringNumber && (
                  <Badge variant="outline" className="text-xs font-mono px-1 py-0.5">
                    {bird.ringNumber}
                  </Badge>
                )}
                {bird.color && (
                  <Badge variant="outline" className="text-xs px-1 py-0.5">
                    <div 
                      className="w-2 h-2 rounded-full mr-1"
                      style={{ backgroundColor: bird.color }}
                    />
                    <span className="hidden md:inline">{bird.color}</span>
                  </Badge>
                )}
                {age && (
                  <Badge variant="secondary" className="text-xs px-1 py-0.5">
                    {age}
                  </Badge>
                )}
              </div>

              <div className="flex items-center gap-1 md:gap-2 text-xs text-muted-foreground">
                {hasKids && (
                  <div className="flex items-center gap-1">
                    <Baby className="w-3 h-3" />
                    <span className="hidden md:inline">Çocuklu</span>
                    <span className="md:hidden">Çocuk</span>
                  </div>
                )}
                {hasParentsBool && (
                  <div className="flex items-center gap-1">
                    <Users className="w-3 h-3" />
                    <span className="hidden md:inline">Ebeveynli</span>
                    <span className="md:hidden">Ebeveyn</span>
                  </div>
                )}
                <div className="flex items-center gap-1">
                  <Calendar className="w-3 h-3" />
                  <span>{generation}. Nesil</span>
                </div>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    );
  }, [favorites, getBirdAge, hasChildren, hasParents, getGeneration, onBirdSelect, toggleFavorite, setIsExpanded]);

  return (
    <Card className="enhanced-card">
      <Collapsible open={isExpanded} onOpenChange={setIsExpanded}>
        <CollapsibleTrigger asChild>
          <CardHeader className="cursor-pointer hover:bg-muted/50 transition-colors pb-3">
            <div className="flex items-center justify-between">
              <CardTitle className="text-sm md:text-base flex items-center gap-2">
                <Users className="w-4 h-4" />
                {t('genealogy.birdList')} ({filteredAndSortedBirds.length})
              </CardTitle>
              <div className="flex items-center gap-2">
                <Badge variant="secondary" className="text-xs px-2 py-1">
                  {isExpanded ? 'Gizle' : 'Göster'}
                </Badge>
                {isExpanded ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
              </div>
            </div>
            <p className="text-xs md:text-sm text-muted-foreground mt-1">
              {isExpanded ? 'Kuş listesini gizlemek için tıklayın' : 'Kuş listesini görmek için tıklayın'}
            </p>
          </CardHeader>
        </CollapsibleTrigger>
        
        <CollapsibleContent>
          <CardContent className="space-y-3 md:space-y-4">
            {/* Sıralama Seçenekleri */}
            <div className="grid grid-cols-2 md:flex md:flex-wrap gap-1 md:gap-2">
              <Button
                variant={sortBy === 'name' ? 'default' : 'outline'}
                size="sm"
                onClick={() => handleSortChange('name')}
                className="text-xs h-8 md:h-9"
              >
                {t('genealogy.sortByName')}
                {sortBy === 'name' && (sortOrder === 'asc' ? ' ↑' : ' ↓')}
              </Button>
              
              <Button
                variant={sortBy === 'recent' ? 'default' : 'outline'}
                size="sm"
                onClick={() => handleSortChange('recent')}
                className="text-xs h-8 md:h-9"
              >
                <Clock className="w-3 h-3 mr-1" />
                <span className="hidden md:inline">{t('genealogy.sortByRecent')}</span>
                <span className="md:hidden">Son</span>
                {sortBy === 'recent' && (sortOrder === 'asc' ? ' ↑' : ' ↓')}
              </Button>
              
              <Button
                variant={sortBy === 'favorites' ? 'default' : 'outline'}
                size="sm"
                onClick={() => handleSortChange('favorites')}
                className="text-xs h-8 md:h-9"
              >
                <Heart className="w-3 h-3 mr-1" />
                <span className="hidden md:inline">{t('genealogy.sortByFavorites')}</span>
                <span className="md:hidden">Favori</span>
                {sortBy === 'favorites' && (sortOrder === 'asc' ? ' ↑' : ' ↓')}
              </Button>
              
              <Button
                variant={sortBy === 'age' ? 'default' : 'outline'}
                size="sm"
                onClick={() => handleSortChange('age')}
                className="text-xs h-8 md:h-9"
              >
                <Calendar className="w-3 h-3 mr-1" />
                <span className="hidden md:inline">{t('genealogy.sortByAge')}</span>
                <span className="md:hidden">Yaş</span>
                {sortBy === 'age' && (sortOrder === 'asc' ? ' ↑' : ' ↓')}
              </Button>
            </div>

            {/* Kuş Listesi */}
            <div className="space-y-3 max-h-96 overflow-y-auto">
              {filteredAndSortedBirds.length > 0 ? (
                filteredAndSortedBirds.map(renderBirdCard)
              ) : (
                <div className="text-center py-8 enhanced-text-secondary">
                  <span className="text-2xl mb-2 block" aria-hidden="true">🔍</span>
                  <p className="text-sm">
                    {searchTerm || filters ? t('genealogy.noResults') : t('genealogy.noBirds')}
                  </p>
                  {searchTerm && (
                    <p className="text-xs mt-1">
                      "{searchTerm}" {t('genealogy.searchNoResults')}
                    </p>
                  )}
                </div>
              )}
            </div>
          </CardContent>
        </CollapsibleContent>
      </Collapsible>
    </Card>
  );
};

export default SimpleBirdList; 