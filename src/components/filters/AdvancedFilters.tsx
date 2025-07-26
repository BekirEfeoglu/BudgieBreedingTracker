import React, { useState, useCallback, useMemo } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Checkbox } from '@/components/ui/checkbox';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { Calendar } from '@/components/ui/calendar';
import { Separator } from '@/components/ui/separator';
import { 
  Filter, 
  X, 
  Search, 
  Calendar as CalendarIcon,
  Tag,
  Save,
  Loader2
} from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';
import { cn } from '@/lib/utils';
import { format } from 'date-fns';
import { tr } from 'date-fns/locale';

interface FilterState {
  searchQuery: string;
  gender: string[];
  colors: string[];
  ageRange: [number, number];
  ageUnit: 'days' | 'weeks' | 'months' | 'years';
  dateRange: { start: Date | null; end: Date | null };
  hasPhoto: boolean | null;
  hasRingNumber: boolean | null;
  hasParents: boolean | null;
  hasHealthNotes: boolean | null;
  isActiveBreeder: boolean | null;
  hasOffspring: boolean | null;
  customTags: string[];
}

interface FilterPreset {
  id: string;
  name: string;
  filters: FilterState;
  createdAt: Date;
}

interface AdvancedFiltersProps {
  filters: FilterState;
  onFiltersChange: (filters: FilterState) => void;
  onReset: () => void;
  onSavePreset?: (preset: FilterPreset) => void;
  onLoadPreset?: (preset: FilterPreset) => void;
  savedPresets?: FilterPreset[];
  isLoading?: boolean;
}

const AdvancedFilters: React.FC<AdvancedFiltersProps> = ({
  filters,
  onFiltersChange,
  onReset,
  onSavePreset,
  onLoadPreset,
  savedPresets = [],
  isLoading = false
}) => {
  const { t } = useLanguage();
  const [isOpen, setIsOpen] = useState(false);
  const [presetName, setPresetName] = useState('');

  // Available options
  const genderOptions = [
    { value: 'male', label: t('birds.gender.male') },
    { value: 'female', label: t('birds.gender.female') },
    { value: 'unknown', label: t('birds.gender.unknown') }
  ];

  const colorOptions = [
    'Mavi', 'Yeşil', 'Sarı', 'Beyaz', 'Gri', 'Kahverengi', 'Mor', 'Turuncu'
  ];

  const ageUnitOptions = [
    { value: 'days', label: t('common.days') },
    { value: 'weeks', label: t('common.weeks') },
    { value: 'months', label: t('common.months') },
    { value: 'years', label: t('common.years') }
  ];

  const booleanOptions = [
    { value: 'true', label: t('common.yes') },
    { value: 'false', label: t('common.no') },
    { value: 'null', label: t('common.any') }
  ];

  // Update filter value
  const updateFilter = useCallback((key: keyof FilterState, value: unknown) => {
    onFiltersChange({
      ...filters,
      [key]: value
    });
  }, [filters, onFiltersChange]);

  // Handle array filter updates
  const updateArrayFilter = useCallback((key: keyof FilterState, value: string, checked: boolean) => {
    const currentArray = filters[key] as string[];
    const newArray = checked 
      ? [...currentArray, value]
      : currentArray.filter(item => item !== value);
    
    updateFilter(key, newArray);
  }, [filters, updateFilter]);

  // Handle boolean filter updates
  const updateBooleanFilter = useCallback((key: keyof FilterState, value: string) => {
    const booleanValue = value === 'true' ? true : value === 'false' ? false : null;
    updateFilter(key, booleanValue);
  }, [updateFilter]);

  // Save current filters as preset
  const handleSavePreset = useCallback(() => {
    if (!presetName.trim() || !onSavePreset) return;
    
    const preset: FilterPreset = {
      id: Date.now().toString(),
      name: presetName.trim(),
      filters: { ...filters },
      createdAt: new Date()
    };
    
    onSavePreset(preset);
    setPresetName('');
  }, [presetName, filters, onSavePreset]);

  // Load a preset
  const handleLoadPreset = useCallback((preset: FilterPreset) => {
    if (onLoadPreset) {
      onLoadPreset(preset);
    }
  }, [onLoadPreset]);

  // Reset all filters
  const handleReset = useCallback(() => {
    onReset();
    setIsOpen(false);
  }, [onReset]);

  // Count active filters
  const activeFilterCount = useMemo(() => {
    let count = 0;
    if (filters.searchQuery) count++;
    if (filters.gender.length > 0) count++;
    if (filters.colors.length > 0) count++;
    if (filters.ageRange[0] > 0 || filters.ageRange[1] < 10) count++;
    if (filters.dateRange.start || filters.dateRange.end) count++;
    if (filters.hasPhoto !== null) count++;
    if (filters.hasRingNumber !== null) count++;
    if (filters.hasParents !== null) count++;
    if (filters.hasHealthNotes !== null) count++;
    if (filters.isActiveBreeder !== null) count++;
    if (filters.hasOffspring !== null) count++;
    if (filters.customTags.length > 0) count++;
    return count;
  }, [filters]);

  return (
    <div className="space-y-4">
      {/* Filter Toggle Button */}
      <div className="flex items-center gap-2">
        <Popover open={isOpen} onOpenChange={setIsOpen}>
          <PopoverTrigger asChild>
            <Button 
              variant="outline" 
              size="sm"
              className="gap-2"
              disabled={isLoading}
            >
              <Filter className="w-4 h-4" />
              {t('filters.advanced')}
              {activeFilterCount > 0 && (
                <Badge variant="secondary" className="ml-1">
                  {activeFilterCount}
                </Badge>
              )}
            </Button>
          </PopoverTrigger>
          
          <PopoverContent className="w-80 p-4" align="start">
            <div className="space-y-4">
              {/* Header */}
              <div className="flex items-center justify-between">
                <h3 className="font-medium">{t('filters.advanced')}</h3>
                <Button 
                  variant="ghost" 
                  size="sm" 
                  onClick={handleReset}
                  className="h-6 px-2"
                >
                  <X className="w-3 h-3" />
                </Button>
              </div>

              <Separator />

              {/* Search */}
              <div className="space-y-2">
                <Label className="text-sm font-medium">
                  <Search className="w-3 h-3 inline mr-1" />
                  {t('filters.search')}
                </Label>
                <Input
                  placeholder={t('filters.searchPlaceholder')}
                  value={filters.searchQuery}
                  onChange={(e) => updateFilter('searchQuery', e.target.value)}
                />
              </div>

              {/* Gender Filter */}
              <div className="space-y-2">
                <Label className="text-sm font-medium">
                  {t('birds.gender.label')}
                </Label>
                <div className="space-y-2">
                  {genderOptions.map(option => (
                    <div key={option.value} className="flex items-center space-x-2">
                      <Checkbox
                        id={`gender-${option.value}`}
                        checked={filters.gender.includes(option.value)}
                        onCheckedChange={(checked) => 
                          updateArrayFilter('gender', option.value, checked as boolean)
                        }
                      />
                      <Label htmlFor={`gender-${option.value}`} className="text-sm">
                        {option.label}
                      </Label>
                    </div>
                  ))}
                </div>
              </div>

              {/* Color Filter */}
              <div className="space-y-2">
                <Label className="text-sm font-medium">
                  {t('birds.color.label')}
                </Label>
                <div className="grid grid-cols-2 gap-2">
                  {colorOptions.map(color => (
                    <div key={color} className="flex items-center space-x-2">
                      <Checkbox
                        id={`color-${color}`}
                        checked={filters.colors.includes(color)}
                        onCheckedChange={(checked) => 
                          updateArrayFilter('colors', color, checked as boolean)
                        }
                      />
                      <Label htmlFor={`color-${color}`} className="text-sm">
                        {color}
                      </Label>
                    </div>
                  ))}
                </div>
              </div>

              {/* Age Range */}
              <div className="space-y-2">
                <Label className="text-sm font-medium">
                  {t('filters.ageRange')}
                </Label>
                <div className="flex items-center gap-2">
                  <Input
                    type="number"
                    placeholder="0"
                    value={filters.ageRange[0]}
                    onChange={(e) => updateFilter('ageRange', [Number(e.target.value), filters.ageRange[1]])}
                    className="w-20"
                  />
                  <span className="text-sm">-</span>
                  <Input
                    type="number"
                    placeholder="10"
                    value={filters.ageRange[1]}
                    onChange={(e) => updateFilter('ageRange', [filters.ageRange[0], Number(e.target.value)])}
                    className="w-20"
                  />
                  <Select
                    value={filters.ageUnit}
                    onValueChange={(value) => updateFilter('ageUnit', value as FilterState['ageUnit'])}
                  >
                    <SelectTrigger className="w-24">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {ageUnitOptions.map(option => (
                        <SelectItem key={option.value} value={option.value}>
                          {option.label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>

              {/* Date Range */}
              <div className="space-y-2">
                <Label className="text-sm font-medium">
                  {t('filters.dateRange')}
                </Label>
                <div className="grid grid-cols-2 gap-2">
                  <Popover>
                    <PopoverTrigger asChild>
                      <Button
                        variant="outline"
                        className={cn(
                          "justify-start text-left font-normal",
                          !filters.dateRange.start && "text-muted-foreground"
                        )}
                      >
                        <CalendarIcon className="mr-2 h-4 w-4" />
                        {filters.dateRange.start ? format(filters.dateRange.start, "PPP", { locale: tr }) : t('filters.startDate')}
                      </Button>
                    </PopoverTrigger>
                    <PopoverContent className="w-auto p-0">
                      <Calendar
                        mode="single"
                        selected={filters.dateRange.start ?? undefined}
                        onSelect={(date) => updateFilter('dateRange', { ...filters.dateRange, start: date })}
                        initialFocus
                      />
                    </PopoverContent>
                  </Popover>
                  
                  <Popover>
                    <PopoverTrigger asChild>
                      <Button
                        variant="outline"
                        className={cn(
                          "justify-start text-left font-normal",
                          !filters.dateRange.end && "text-muted-foreground"
                        )}
                      >
                        <CalendarIcon className="mr-2 h-4 w-4" />
                        {filters.dateRange.end ? format(filters.dateRange.end, "PPP", { locale: tr }) : t('filters.endDate')}
                      </Button>
                    </PopoverTrigger>
                    <PopoverContent className="w-auto p-0">
                      <Calendar
                        mode="single"
                        selected={filters.dateRange.end ?? undefined}
                        onSelect={(date) => updateFilter('dateRange', { ...filters.dateRange, end: date })}
                        initialFocus
                      />
                    </PopoverContent>
                  </Popover>
                </div>
              </div>

              {/* Boolean Filters */}
              <div className="space-y-2">
                <Label className="text-sm font-medium">
                  {t('filters.attributes')}
                </Label>
                <div className="space-y-2">
                  {[
                    { key: 'hasPhoto', label: t('filters.hasPhoto') },
                    { key: 'hasRingNumber', label: t('filters.hasRingNumber') },
                    { key: 'hasParents', label: t('filters.hasParents') },
                    { key: 'hasHealthNotes', label: t('filters.hasHealthNotes') },
                    { key: 'isActiveBreeder', label: t('filters.isActiveBreeder') },
                    { key: 'hasOffspring', label: t('filters.hasOffspring') }
                  ].map(filter => (
                    <div key={filter.key} className="flex items-center justify-between">
                      <Label className="text-sm">{filter.label}</Label>
                      <Select
                        value={String(filters[filter.key as keyof FilterState])}
                        onValueChange={(value) => updateBooleanFilter(filter.key as keyof FilterState, value)}
                      >
                        <SelectTrigger className="w-20">
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                          {booleanOptions.map(option => (
                            <SelectItem key={option.value} value={option.value}>
                              {option.label}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>
                  ))}
                </div>
              </div>

              {/* Presets */}
              {onSavePreset && (
                <div className="space-y-2">
                  <Label className="text-sm font-medium">
                    <Save className="w-3 h-3 inline mr-1" />
                    {t('filters.presets')}
                  </Label>
                  <div className="flex gap-2">
                    <Input
                      placeholder={t('filters.presetName')}
                      value={presetName}
                      onChange={(e) => setPresetName(e.target.value)}
                      className="flex-1"
                    />
                    <Button 
                      size="sm" 
                      onClick={handleSavePreset}
                      disabled={!presetName.trim()}
                    >
                      {t('filters.save')}
                    </Button>
                  </div>
                  
                  {savedPresets.length > 0 && (
                    <div className="space-y-1">
                      {savedPresets.map(preset => (
                        <div 
                          key={preset.id} 
                          className="flex items-center justify-between p-2 text-sm border rounded cursor-pointer hover:bg-muted"
                          onClick={() => handleLoadPreset(preset)}
                        >
                          <span>{preset.name}</span>
                          <Tag className="w-3 h-3" />
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              )}
            </div>
          </PopoverContent>
        </Popover>

        {isLoading && <Loader2 className="w-4 h-4 animate-spin" />}
      </div>
    </div>
  );
};

export default AdvancedFilters; 