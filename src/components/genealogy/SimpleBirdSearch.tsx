import React, { useState, useCallback } from 'react';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Search, X } from 'lucide-react';
import { Bird, Chick } from '@/types';
import { useLanguage } from '@/contexts/LanguageContext';

interface SimpleBirdSearchProps {
  birds: Bird[];
  chicks: Chick[];
  onBirdSelect: (bird: Bird | Chick) => void;
  placeholder?: string;
}

const SimpleBirdSearch: React.FC<SimpleBirdSearchProps> = ({
  birds,
  chicks,
  onBirdSelect,
  placeholder
}) => {
  const { t } = useLanguage();
  const [searchTerm, setSearchTerm] = useState('');
  const [showResults, setShowResults] = useState(false);

  // Basit filtreleme - useMemo kullanmıyoruz
  const filteredResults = searchTerm.trim() === '' 
    ? []
    : [...birds, ...chicks]
        .filter(bird => 
          bird.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
          bird.ringNumber?.toLowerCase().includes(searchTerm.toLowerCase())
        )
        .slice(0, 10); // Sadece ilk 10 sonuç

  const handleSearchChange = useCallback((value: string) => {
    setSearchTerm(value);
    setShowResults(value.length > 0);
  }, []);

  const handleBirdSelect = useCallback((bird: Bird | Chick) => {
    onBirdSelect(bird);
    setSearchTerm(bird.name);
    setShowResults(false);
  }, [onBirdSelect]);

  const clearSearch = useCallback(() => {
    setSearchTerm('');
    setShowResults(false);
  }, []);

  return (
    <div className="relative">
      <div className="relative">
        <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground w-4 h-4" />
        <Input
          type="text"
          placeholder={placeholder || t('genealogy.searchPlaceholder')}
          value={searchTerm}
          onChange={(e) => handleSearchChange(e.target.value)}
          className="pl-10 pr-10"
          onFocus={() => setShowResults(searchTerm.length > 0)}
        />
        {searchTerm && (
          <Button
            variant="ghost"
            size="sm"
            className="absolute right-1 top-1/2 transform -translate-y-1/2 h-8 w-8 p-0"
            onClick={clearSearch}
          >
            <X className="w-4 h-4" />
          </Button>
        )}
      </div>

      {showResults && (
        <Card className="absolute top-full left-0 right-0 z-50 mt-1 max-h-60 overflow-y-auto">
          <CardContent className="p-2">
            {filteredResults.length === 0 ? (
              <div className="text-center py-4 text-sm text-muted-foreground">
                {t('birds.noSearchResults')}
              </div>
            ) : (
              <div className="space-y-1">
                {filteredResults.map((bird, index) => (
                  <Button
                    key={`search-result-${index}-${bird.id}`}
                    variant="ghost"
                    className="w-full justify-start h-auto p-2 text-left"
                    onClick={() => handleBirdSelect(bird)}
                  >
                    <div className="flex items-center gap-2 w-full">
                      <div className="w-8 h-8 rounded-full bg-muted flex items-center justify-center text-sm">
                        {bird.gender === 'male' ? '♂️' : bird.gender === 'female' ? '♀️' : '❓'}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="font-medium truncate">{bird.name}</div>
                        {bird.ringNumber && (
                          <div className="text-xs text-muted-foreground truncate">
                            {bird.ringNumber}
                          </div>
                        )}
                      </div>
                    </div>
                  </Button>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      )}
    </div>
  );
};

export default SimpleBirdSearch; 