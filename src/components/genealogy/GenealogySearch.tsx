import React, { useState, useCallback, useMemo } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Checkbox } from '@/components/ui/checkbox';
import { Collapsible, CollapsibleContent, CollapsibleTrigger } from '@/components/ui/collapsible';
import { 
  Search, 
  Filter, 
  X, 
  ChevronDown, 
  ChevronUp,
  Users,
  Baby,
  Tag
} from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';
import { Bird, Chick } from '@/types';

interface GenealogySearchProps {
  birds: Bird[];
  chicks: Chick[];
  onSearchChange: (searchTerm: string) => void;
  onFilterChange: (filters: GenealogyFilters) => void;
  searchTerm: string;
  filters: GenealogyFilters;
}

export interface GenealogyFilters {
  gender: 'all' | 'male' | 'female' | 'unknown';
  ageGroup: 'all' | 'young' | 'adult' | 'old';
  hasChildren: boolean | null;
  hasParents: boolean | null;
  generation: 'all' | '1' | '2' | '3' | '4';
  color?: string;
  ringNumber?: string;
}

const GenealogySearch: React.FC<GenealogySearchProps> = ({
  birds,
  chicks,
  onSearchChange,
  onFilterChange,
  searchTerm,
  filters
}) => {
  const { t } = useLanguage();
  const [isExpanded, setIsExpanded] = useState(false);

  // Mevcut renkler
  const availableColors = useMemo(() => {
    const colors = new Set<string>();
    [...birds, ...chicks].forEach(bird => {
      if (bird.color) colors.add(bird.color);
    });
    return Array.from(colors).sort();
  }, [birds, chicks]);

  // Kuş yaşını hesapla
  const getBirdAge = useCallback((bird: Bird | Chick) => {
    const birthDate = 'hatchDate' in bird ? bird.hatchDate : bird.birthDate;
    if (!birthDate) return null;
    
    const age = Math.floor((new Date().getTime() - new Date(birthDate).getTime()) / (1000 * 60 * 60 * 24));
    if (age < 30) return 'young';
    if (age < 365) return 'young';
    if (age < 1825) return 'adult'; // 5 yıl
    return 'old';
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
  const applyFilters = useCallback((bird: Bird | Chick) => {
    // Cinsiyet filtresi
    if (filters.gender !== 'all' && bird.gender !== filters.gender) {
      return false;
    }

    // Yaş grubu filtresi
    if (filters.ageGroup !== 'all') {
      const age = getBirdAge(bird);
      if (age !== filters.ageGroup) {
        return false;
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

  // Filtrelenmiş sonuçlar
  const filteredResults = useMemo(() => {
    const allBirds = [...birds, ...chicks];
    return allBirds.filter(bird => {
      // Önce arama terimi
      const matchesSearch = !searchTerm || 
        bird.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        bird.ringNumber?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        bird.color?.toLowerCase().includes(searchTerm.toLowerCase());

      if (!matchesSearch) return false;

      // Sonra filtreler
      return applyFilters(bird);
    });
  }, [birds, chicks, searchTerm, applyFilters]);

  // İstatistikler
  const stats = useMemo(() => {
    const allBirds = [...birds, ...chicks];
    const total = allBirds.length;
    const filtered = filteredResults.length;
    
    const genderStats = allBirds.reduce((acc, bird) => {
      acc[bird.gender] = (acc[bird.gender] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);

    const ageStats = allBirds.reduce((acc, bird) => {
      const age = getBirdAge(bird);
      if (age) acc[age] = (acc[age] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);

    const childrenStats = allBirds.reduce((acc, bird) => {
      const hasKids = hasChildren(bird);
      acc[hasKids ? 'withChildren' : 'withoutChildren'] = 
        (acc[hasKids ? 'withChildren' : 'withoutChildren'] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);

    return {
      total,
      filtered,
      genderStats,
      ageStats,
      childrenStats
    };
  }, [birds, chicks, filteredResults, getBirdAge, hasChildren]);

  const handleFilterChange = useCallback((key: keyof GenealogyFilters, value: any) => {
    onFilterChange({
      ...filters,
      [key]: value
    });
  }, [filters, onFilterChange]);

  const clearFilters = useCallback(() => {
    onFilterChange({
      gender: 'all',
      ageGroup: 'all',
      hasChildren: null,
      hasParents: null,
      generation: 'all',
      color: 'all',
      ringNumber: ''
    });
  }, [onFilterChange]);

  const hasActiveFilters = Object.values(filters).some(value => 
    value !== 'all' && value !== null && value !== ''
  );

  return (
    <Card className="enhanced-card">
      <CardHeader className="pb-3">
        <CardTitle className="text-sm md:text-base flex items-center gap-2">
          <Search className="w-4 h-4" />
          {t('genealogy.searchAndFilter')}
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-3 md:space-y-4">
        {/* Arama */}
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground w-4 h-4" />
          <Input
            placeholder={t('genealogy.searchPlaceholder')}
            value={searchTerm}
            onChange={(e) => onSearchChange(e.target.value)}
            className="pl-10 pr-4 h-9 md:h-10"
          />
          {searchTerm && (
            <Button
              variant="ghost"
              size="sm"
              className="absolute right-1 top-1/2 transform -translate-y-1/2 h-6 w-6 p-0"
              onClick={() => onSearchChange('')}
            >
              <X className="w-3 h-3" />
            </Button>
          )}
        </div>

        {/* Sonuç sayısı */}
        <div className="flex items-center justify-between text-xs md:text-sm">
          <span className="enhanced-text-secondary">
            {filteredResults.length} / {stats.total} {t('genealogy.birdsFound')}
          </span>
          {hasActiveFilters && (
            <Button
              variant="ghost"
              size="sm"
              onClick={clearFilters}
              className="text-xs h-6 px-2"
            >
              <X className="w-3 h-3 mr-1" />
              {t('common.clearFilters')}
            </Button>
          )}
        </div>

        {/* Filtreler */}
        <Collapsible open={isExpanded} onOpenChange={setIsExpanded}>
          <CollapsibleTrigger asChild>
            <Button variant="outline" size="sm" className="w-full justify-between h-9 md:h-10">
              <span className="flex items-center gap-2">
                <Filter className="w-4 h-4" />
                <span className="text-xs md:text-sm">{t('genealogy.filters')}</span>
                {hasActiveFilters && (
                  <Badge variant="secondary" className="text-xs px-1 py-0.5">
                    {Object.values(filters).filter(v => v !== 'all' && v !== null && v !== '').length}
                  </Badge>
                )}
              </span>
              {isExpanded ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
            </Button>
          </CollapsibleTrigger>
          <CollapsibleContent className="space-y-3 md:space-y-4 pt-3 md:pt-4">
            {/* Cinsiyet */}
            <div>
              <label className="text-xs md:text-sm font-medium mb-1 md:mb-2 block">{t('genealogy.gender')}</label>
              <Select value={filters.gender} onValueChange={(value) => handleFilterChange('gender', value)}>
                <SelectTrigger className="h-8 md:h-10">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">{t('common.all')}</SelectItem>
                  <SelectItem value="male">♂️ {t('genealogy.male')}</SelectItem>
                  <SelectItem value="female">♀️ {t('genealogy.female')}</SelectItem>
                  <SelectItem value="unknown">❓ {t('genealogy.unknown')}</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {/* Yaş Grubu */}
            <div>
              <label className="text-xs md:text-sm font-medium mb-1 md:mb-2 block">{t('genealogy.ageGroup')}</label>
              <Select value={filters.ageGroup} onValueChange={(value) => handleFilterChange('ageGroup', value)}>
                <SelectTrigger className="h-8 md:h-10">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">{t('common.all')}</SelectItem>
                  <SelectItem value="young">🐣 {t('genealogy.young')}</SelectItem>
                  <SelectItem value="adult">🐦 {t('genealogy.adult')}</SelectItem>
                  <SelectItem value="old">🦅 {t('genealogy.old')}</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {/* Nesil */}
            <div>
              <label className="text-xs md:text-sm font-medium mb-1 md:mb-2 block">{t('genealogy.generation')}</label>
              <Select value={filters.generation} onValueChange={(value) => handleFilterChange('generation', value)}>
                <SelectTrigger className="h-8 md:h-10">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">{t('common.all')}</SelectItem>
                  <SelectItem value="1">1. {t('genealogy.generation')}</SelectItem>
                  <SelectItem value="2">2. {t('genealogy.generation')}</SelectItem>
                  <SelectItem value="3">3. {t('genealogy.generation')}</SelectItem>
                  <SelectItem value="4">4. {t('genealogy.generation')}</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {/* Renk */}
            {availableColors.length > 0 && (
              <div>
                <label className="text-xs md:text-sm font-medium mb-1 md:mb-2 block">{t('genealogy.color')}</label>
                <Select value={filters.color || 'all'} onValueChange={(value) => handleFilterChange('color', value === 'all' ? undefined : value)}>
                  <SelectTrigger className="h-8 md:h-10">
                    <SelectValue placeholder={t('genealogy.selectColor')} />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">{t('common.all')}</SelectItem>
                    {availableColors.map((color, index) => (
                      <SelectItem key={`color-${index}-${color}`} value={color}>
                        <div className="flex items-center gap-2">
                          <div 
                            className="w-3 h-3 rounded-full border border-gray-300"
                            style={{ backgroundColor: color }}
                          />
                          <span className="text-xs md:text-sm">{color}</span>
                        </div>
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            )}

            {/* Halka Numarası */}
            <div>
              <label className="text-xs md:text-sm font-medium mb-1 md:mb-2 block">{t('genealogy.ringNumber')}</label>
              <Input
                placeholder={t('genealogy.ringNumberPlaceholder')}
                value={filters.ringNumber || ''}
                onChange={(e) => handleFilterChange('ringNumber', e.target.value || undefined)}
                className="h-8 md:h-10"
              />
            </div>

            {/* Checkbox'lar */}
            <div className="space-y-2 md:space-y-3">
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="hasChildren"
                  checked={filters.hasChildren === true}
                  onCheckedChange={(checked) => handleFilterChange('hasChildren', checked ? true : null)}
                />
                <label htmlFor="hasChildren" className="text-xs md:text-sm flex items-center gap-2">
                  <Baby className="w-4 h-4" />
                  {t('genealogy.hasChildren')}
                </label>
              </div>

              <div className="flex items-center space-x-2">
                <Checkbox
                  id="hasParents"
                  checked={filters.hasParents === true}
                  onCheckedChange={(checked) => handleFilterChange('hasParents', checked ? true : null)}
                />
                <label htmlFor="hasParents" className="text-xs md:text-sm flex items-center gap-2">
                  <Users className="w-4 h-4" />
                  {t('genealogy.hasParents')}
                </label>
              </div>
            </div>
          </CollapsibleContent>
        </Collapsible>

        {/* İstatistikler */}
        {isExpanded && (
          <div className="pt-4 border-t">
            <h4 className="text-sm font-medium mb-3">{t('genealogy.statistics')}</h4>
            <div className="grid grid-cols-2 gap-4 text-xs">
              <div>
                <div className="font-medium mb-1">{t('genealogy.genderDistribution')}</div>
                <div className="space-y-1">
                  <div className="flex justify-between">
                    <span>♂️ {t('genealogy.male')}</span>
                    <span>{stats.genderStats.male || 0}</span>
                  </div>
                  <div className="flex justify-between">
                    <span>♀️ {t('genealogy.female')}</span>
                    <span>{stats.genderStats.female || 0}</span>
                  </div>
                  <div className="flex justify-between">
                    <span>❓ {t('genealogy.unknown')}</span>
                    <span>{stats.genderStats.unknown || 0}</span>
                  </div>
                </div>
              </div>
              <div>
                <div className="font-medium mb-1">{t('genealogy.ageDistribution')}</div>
                <div className="space-y-1">
                  <div className="flex justify-between">
                    <span>🐣 {t('genealogy.young')}</span>
                    <span>{stats.ageStats.young || 0}</span>
                  </div>
                  <div className="flex justify-between">
                    <span>🐦 {t('genealogy.adult')}</span>
                    <span>{stats.ageStats.adult || 0}</span>
                  </div>
                  <div className="flex justify-between">
                    <span>🦅 {t('genealogy.old')}</span>
                    <span>{stats.ageStats.old || 0}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
};

export default GenealogySearch;
