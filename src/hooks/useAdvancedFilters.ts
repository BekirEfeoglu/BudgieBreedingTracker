import { useState, useCallback, useMemo, useEffect } from 'react';
import { useAuth } from '@/hooks/useAuth';

export interface FilterState {
  // Text search
  searchQuery: string;
  
  // Basic filters
  gender: string[];
  colors: string[];
  
  // Age filters
  ageRange: [number, number];
  ageUnit: 'days' | 'months' | 'years';
  
  // Date filters  
  dateRange: {
    start: string | null;
    end: string | null;
  };
  
  // Health & status
  hasPhoto: boolean | null;
  hasRingNumber: boolean | null;
  hasParents: boolean | null;
  hasHealthNotes: boolean | null;
  
  // Breeding status (for adults)
  isActiveBreeder: boolean | null;
  hasOffspring: boolean | null;
  
  // Custom tags
  customTags: string[];
}

export interface FilterPreset {
  id: string;
  name: string;
  description: string;
  filters: FilterState;
  icon: string;
  createdAt: Date;
}

const defaultFilters: FilterState = {
  searchQuery: '',
  gender: [],
  colors: [],
  ageRange: [0, 10],
  ageUnit: 'years',
  dateRange: { start: null, end: null },
  hasPhoto: null,
  hasRingNumber: null,
  hasParents: null,
  hasHealthNotes: null,
  isActiveBreeder: null,
  hasOffspring: null,
  customTags: []
};

export const useAdvancedFilters = <T extends Record<string, any>>(
  items: T[],
  filterType: 'birds' | 'chicks' | 'all' = 'all'
) => {
  const { user } = useAuth();
  const [filters, setFilters] = useState<FilterState>(defaultFilters);
  const [savedPresets, setSavedPresets] = useState<FilterPreset[]>([]);
  const [activePresetId, setActivePresetId] = useState<string | null>(null);

  // Load saved presets from localStorage
  useEffect(() => {
    if (!user) return;
    
    try {
      const saved = localStorage.getItem(`filter_presets_${user.id}`);
      if (saved) {
        const presets = JSON.parse(saved).map((preset: any) => ({
          ...preset,
          createdAt: new Date(preset.createdAt)
        }));
        setSavedPresets(presets);
      }
    } catch (error) {
      console.error('Error loading filter presets:', error);
    }
  }, [user]);

  // Save presets to localStorage
  const savePresets = useCallback((presets: FilterPreset[]) => {
    if (!user) return;
    
    try {
      localStorage.setItem(`filter_presets_${user.id}`, JSON.stringify(presets));
    } catch (error) {
      console.error('Error saving filter presets:', error);
    }
  }, [user]);

  // Calculate age in specified unit
  const calculateAge = useCallback((dateString: string, unit: 'days' | 'months' | 'years') => {
    const date = new Date(dateString);
    const now = new Date();
    const diffTime = now.getTime() - date.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    
    switch (unit) {
      case 'days':
        return diffDays;
      case 'months':
        return Math.floor(diffDays / 30);
      case 'years':
        return Math.floor(diffDays / 365);
      default:
        return diffDays;
    }
  }, []);

  // Get all unique colors from items
  const availableColors = useMemo(() => {
    const colors = items
      .filter(item => item.color)
      .map(item => item.color.toLowerCase().trim())
      .filter((color, index, array) => array.indexOf(color) === index)
      .sort();
    return colors;
  }, [items]);

  // Apply filters to items
  const filteredItems = useMemo(() => {
    if (!items.length) return [];
    
    return items.filter(item => {
      // Text search
      if (filters.searchQuery) {
        const query = filters.searchQuery.toLowerCase();
        const searchableFields = [
          item.name,
          item.ringNumber,
          item.color,
          item.healthNotes,
          item.notes
        ].filter(Boolean).join(' ').toLowerCase();
        
        if (!searchableFields.includes(query)) {
          return false;
        }
      }

      // Gender filter
      if (filters.gender.length > 0 && !filters.gender.includes(item.gender)) {
        return false;
      }

      // Color filter
      if (filters.colors.length > 0) {
        if (!item.color || !filters.colors.some(color => 
          item.color.toLowerCase().includes(color.toLowerCase())
        )) {
          return false;
        }
      }

      // Age range filter
      const birthDateField = item.birthDate || item.hatchDate;
      if (birthDateField && (filters.ageRange[0] > 0 || filters.ageRange[1] < 10)) {
        const age = calculateAge(birthDateField, filters.ageUnit);
        if (age < filters.ageRange[0] || age > filters.ageRange[1]) {
          return false;
        }
      }

      // Date range filter
      if (filters.dateRange.start || filters.dateRange.end) {
        const itemDate = new Date(birthDateField || item.createdAt || Date.now());
        const startDate = filters.dateRange.start ? new Date(filters.dateRange.start) : null;
        const endDate = filters.dateRange.end ? new Date(filters.dateRange.end) : null;
        
        if (startDate && itemDate < startDate) return false;
        if (endDate && itemDate > endDate) return false;
      }

      // Boolean filters
      if (filters.hasPhoto !== null) {
        const hasPhoto = Boolean(item.photo);
        if (hasPhoto !== filters.hasPhoto) return false;
      }

      if (filters.hasRingNumber !== null) {
        const hasRingNumber = Boolean(item.ringNumber);
        if (hasRingNumber !== filters.hasRingNumber) return false;
      }

      if (filters.hasParents !== null) {
        const hasParents = Boolean(item.motherId || item.fatherId);
        if (hasParents !== filters.hasParents) return false;
      }

      if (filters.hasHealthNotes !== null) {
        const hasHealthNotes = Boolean(item.healthNotes);
        if (hasHealthNotes !== filters.hasHealthNotes) return false;
      }

      // Breeding status filters (for adult birds)
      if (filters.isActiveBreeder !== null && filterType === 'birds') {
        // This would require additional data about breeding history
        // For now, we'll use a simple heuristic based on age and gender
        const age = birthDateField ? calculateAge(birthDateField, 'years') : 0;
        const isBreedingAge = age >= 1 && age <= 8;
        const isBreeder = isBreedingAge && (item.gender === 'male' || item.gender === 'female');
        if (isBreeder !== filters.isActiveBreeder) return false;
      }

      return true;
    });
  }, [items, filters, calculateAge, filterType]);

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

  // Update filters
  const updateFilters = useCallback((newFilters: Partial<FilterState>) => {
    setFilters(prev => ({ ...prev, ...newFilters }));
    setActivePresetId(null); // Clear active preset when manually changing filters
  }, []);

  // Reset filters
  const resetFilters = useCallback(() => {
    setFilters(defaultFilters);
    setActivePresetId(null);
  }, []);

  // Apply preset
  const applyPreset = useCallback((preset: FilterPreset) => {
    setFilters(preset.filters);
    setActivePresetId(preset.id);
  }, []);

  // Save current filters as preset
  const saveAsPreset = useCallback((name: string, description?: string, icon?: string) => {
    if (!user) return null;
    
    const newPreset: FilterPreset = {
      id: Date.now().toString(),
      name,
      description: description || 'Özel filtre',
      icon: icon || '⭐',
      filters: { ...filters },
      createdAt: new Date()
    };
    
    const updatedPresets = [...savedPresets, newPreset];
    setSavedPresets(updatedPresets);
    savePresets(updatedPresets);
    
    return newPreset;
  }, [user, filters, savedPresets, savePresets]);

  // Delete preset
  const deletePreset = useCallback((presetId: string) => {
    const updatedPresets = savedPresets.filter(preset => preset.id !== presetId);
    setSavedPresets(updatedPresets);
    savePresets(updatedPresets);
    
    if (activePresetId === presetId) {
      setActivePresetId(null);
    }
  }, [savedPresets, savePresets, activePresetId]);

  // Get filter summary
  const filterSummary = useMemo(() => {
    const total = items.length;
    const filtered = filteredItems.length;
    const percentage = total > 0 ? Math.round((filtered / total) * 100) : 0;
    
    return {
      total,
      filtered,
      percentage,
      hidden: total - filtered
    };
  }, [items.length, filteredItems.length]);

  // Get quick filter suggestions based on current data
  const quickFilterSuggestions = useMemo(() => {
    const suggestions = [];
    
    // Gender-based suggestions
    const maleCount = items.filter(item => item.gender === 'male').length;
    const femaleCount = items.filter(item => item.gender === 'female').length;
    const unknownCount = items.filter(item => item.gender === 'unknown').length;
    
    if (maleCount > 0) suggestions.push({ label: `Erkek (${maleCount})`, filter: { gender: ['male'] } });
    if (femaleCount > 0) suggestions.push({ label: `Dişi (${femaleCount})`, filter: { gender: ['female'] } });
    if (unknownCount > 0) suggestions.push({ label: `Bilinmiyor (${unknownCount})`, filter: { gender: ['unknown'] } });
    
    // Photo-based suggestions
    const withPhotos = items.filter(item => item.photo).length;
    const withoutPhotos = items.filter(item => !item.photo).length;
    
    if (withPhotos > 0) suggestions.push({ label: `Fotoğraflı (${withPhotos})`, filter: { hasPhoto: true } });
    if (withoutPhotos > 0) suggestions.push({ label: `Fotoğrafsız (${withoutPhotos})`, filter: { hasPhoto: false } });
    
    // Ring number suggestions
    const withRings = items.filter(item => item.ringNumber).length;
    const withoutRings = items.filter(item => !item.ringNumber).length;
    
    if (withRings > 0) suggestions.push({ label: `Halkalı (${withRings})`, filter: { hasRingNumber: true } });
    if (withoutRings > 0) suggestions.push({ label: `Halkasız (${withoutRings})`, filter: { hasRingNumber: false } });
    
    return suggestions;
  }, [items]);

  return {
    // Current state
    filters,
    filteredItems,
    activeFilterCount,
    availableColors,
    filterSummary,
    
    // Presets
    savedPresets,
    activePresetId,
    
    // Actions
    updateFilters,
    resetFilters,
    applyPreset,
    saveAsPreset,
    deletePreset,
    
    // Utilities
    quickFilterSuggestions,
    calculateAge
  };
}; 