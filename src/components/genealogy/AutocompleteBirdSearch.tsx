import React, { useState } from 'react';
import { Check, ChevronDown, Search } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { Command, CommandEmpty, CommandGroup, CommandInput, CommandItem, CommandList } from '@/components/ui/command';
import { useLanguage } from '@/contexts/LanguageContext';
import { Bird, Chick } from '@/types';

interface AutocompleteBirdSearchProps {
  birds: Bird[];
  chicks: Chick[];
  selectedBird: Bird | Chick | null;
  onBirdSelect: (bird: Bird | Chick) => void;
  placeholder?: string;
}

const AutocompleteBirdSearch = ({ 
  birds, 
  chicks, 
  selectedBird, 
  onBirdSelect,
  placeholder 
}: AutocompleteBirdSearchProps) => {
  const { t } = useLanguage();
  const [open, setOpen] = useState(false);

  const getGenderIcon = (gender: string, isChick: boolean) => {
    if (isChick) return '🐣';
    switch (gender) {
      case 'male': return '🦜';
      case 'female': return '🐦';
      default: return '🐤';
    }
  };

  const handleSelect = (bird: Bird | Chick) => {
    onBirdSelect(bird);
    setOpen(false);
  };

  const handleKeyDown = (event: React.KeyboardEvent) => {
    if (event.key === 'Escape') {
      setOpen(false);
    }
  };

  return (
    <div className="w-full">
      <Popover open={open} onOpenChange={setOpen}>
        <PopoverTrigger asChild>
          <Button
            variant="outline"
            role="combobox"
            aria-expanded={open}
            aria-label={t('genealogy.selectBirdOrChick')}
            aria-haspopup="listbox"
            className="w-full justify-between h-12 px-3"
            onKeyDown={handleKeyDown}
          >
            <div className="flex items-center gap-2 flex-1 min-w-0">
              {selectedBird ? (
                <>
                  <span className="text-lg" aria-hidden="true">
                    {getGenderIcon(selectedBird.gender, 'hatchDate' in selectedBird)}
                  </span>
                  <div className="flex flex-col items-start min-w-0 flex-1">
                    <span className="font-medium truncate max-w-full">
                      {selectedBird.name}
                    </span>
                    <span className="text-xs text-muted-foreground">
                      {'hatchDate' in selectedBird ? t('genealogy.chick') : t('genealogy.adult')}
                      {selectedBird.ringNumber && ` • ${selectedBird.ringNumber}`}
                    </span>
                  </div>
                </>
              ) : (
                <>
                  <Search className="w-4 h-4 text-muted-foreground" aria-hidden="true" />
                  <span className="text-muted-foreground">{placeholder || t('genealogy.searchPlaceholder')}</span>
                </>
              )}
            </div>
            <ChevronDown className="ml-2 h-4 w-4 shrink-0 opacity-50" aria-hidden="true" />
          </Button>
        </PopoverTrigger>
        <PopoverContent className="w-full p-0" align="start">
          <Command>
            <CommandInput 
              placeholder={t('genealogy.searchPlaceholder')} 
              aria-label={t('genealogy.searchPlaceholder')}
            />
            <CommandList>
              <CommandEmpty>{t('genealogy.noBirdsFound')}</CommandEmpty>
              
              <CommandGroup heading={t('genealogy.adultBirds')}>
                {birds.map((bird) => (
                  <CommandItem
                    key={`adult-${bird.id}`}
                    value={`${bird.name} ${bird.ringNumber || ''}`}
                    onSelect={() => handleSelect(bird)}
                    className="flex items-center gap-2 px-3 py-2"
                    aria-label={`${bird.name}, ${bird.gender === 'male' ? t('genealogy.male') : bird.gender === 'female' ? t('genealogy.female') : t('genealogy.unknown')}${bird.ringNumber ? `, ${bird.ringNumber}` : ''}`}
                  >
                    <span className="text-lg" aria-hidden="true">
                      {getGenderIcon(bird.gender, false)}
                    </span>
                    <div className="flex flex-col flex-1 min-w-0">
                      <span className="font-medium truncate">
                        {bird.name}
                      </span>
                      <div className="flex items-center gap-2 text-xs text-muted-foreground">
                        <span>
                          {bird.gender === 'male' ? t('genealogy.male') : bird.gender === 'female' ? t('genealogy.female') : t('genealogy.unknown')}
                        </span>
                        {bird.ringNumber && (
                          <span>• {bird.ringNumber}</span>
                        )}
                      </div>
                    </div>
                    <Check
                      className={`ml-auto h-4 w-4 ${
                        selectedBird?.id === bird.id ? "opacity-100" : "opacity-0"
                      }`}
                      aria-hidden="true"
                    />
                  </CommandItem>
                ))}
              </CommandGroup>

              {chicks.length > 0 && (
                <CommandGroup heading={t('genealogy.chicks')}>
                  {chicks.map((chick) => (
                    <CommandItem
                      key={`chick-${chick.id}`}
                      value={`${chick.name} ${chick.ringNumber || ''}`}
                      onSelect={() => handleSelect(chick)}
                      className="flex items-center gap-2 px-3 py-2"
                      aria-label={`${chick.name}, ${t('genealogy.chick')}${chick.hatchDate ? `, ${new Date(chick.hatchDate).toLocaleDateString('tr-TR')}` : ''}${chick.ringNumber ? `, ${chick.ringNumber}` : ''}`}
                    >
                      <span className="text-lg" aria-hidden="true">🐣</span>
                      <div className="flex flex-col flex-1 min-w-0">
                        <span className="font-medium truncate">
                          {chick.name}
                        </span>
                        <div className="flex items-center gap-2 text-xs text-muted-foreground">
                          <span>{t('genealogy.chick')}</span>
                          {chick.hatchDate && (
                            <span>• {new Date(chick.hatchDate).toLocaleDateString('tr-TR')}</span>
                          )}
                          {chick.ringNumber && (
                            <span>• {chick.ringNumber}</span>
                          )}
                        </div>
                      </div>
                      <Check
                        className={`ml-auto h-4 w-4 ${
                          selectedBird?.id === chick.id ? "opacity-100" : "opacity-0"
                        }`}
                        aria-hidden="true"
                      />
                    </CommandItem>
                  ))}
                </CommandGroup>
              )}
            </CommandList>
          </Command>
        </PopoverContent>
      </Popover>
    </div>
  );
};

AutocompleteBirdSearch.displayName = 'AutocompleteBirdSearch';

export default AutocompleteBirdSearch;
