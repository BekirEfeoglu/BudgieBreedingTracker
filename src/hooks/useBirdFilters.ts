import { useState, useCallback } from 'react';
import { Bird, Chick } from '@/types';

export type SortOption = 'name' | 'birthDate' | 'gender' | 'color';
export type GenderFilter = 'all' | 'male' | 'female' | 'unknown';
export type AgeFilter = 'all' | 'young' | 'adult' | 'old';

interface FilterOptions {
  gender: GenderFilter;
  age: AgeFilter;
  sortBy: SortOption;
  sortOrder: 'asc' | 'desc';
}

export const useBirdFilters = () => {
  const [filters, setFilters] = useState<FilterOptions>({
    gender: 'all',
    age: 'all',
    sortBy: 'name',
    sortOrder: 'asc'
  });

  const updateFilter = useCallback((key: keyof FilterOptions, value: any) => {
    setFilters(prev => ({ ...prev, [key]: value }));
  }, []);

  const applyFilters = useCallback((birds: (Bird | Chick)[]) => {
    return getFilteredAndSortedBirds(birds);
  }, []);

  const getFilteredAndSortedBirds = useCallback((birds: (Bird | Chick)[]) => {
    let filtered = [...birds];

    // Gender filter
    if (filters.gender !== 'all') {
      filtered = filtered.filter(bird => bird.gender === filters.gender);
    }

    // Age filter
    if (filters.age !== 'all') {
      filtered = filtered.filter(bird => {
        const birthDate = 'hatchDate' in bird ? bird.hatchDate : bird.birthDate;
        if (!birthDate) return false;
        
        const age = Math.floor((new Date().getTime() - new Date(birthDate).getTime()) / (1000 * 60 * 60 * 24));
        
        switch (filters.age) {
          case 'young':
            return age < 365; // 1 yaşından küçük
          case 'adult':
            return age >= 365 && age < 1825; // 1-5 yaş arası
          case 'old':
            return age >= 1825; // 5 yaşından büyük
          default:
            return true;
        }
      });
    }

    // Sort
    filtered.sort((a, b) => {
      let aValue: any, bValue: any;

      switch (filters.sortBy) {
        case 'name':
          aValue = a.name.toLowerCase();
          bValue = b.name.toLowerCase();
          break;
        case 'birthDate':
          aValue = 'hatchDate' in a ? a.hatchDate : a.birthDate;
          bValue = 'hatchDate' in b ? b.hatchDate : b.birthDate;
          break;
        case 'gender':
          aValue = a.gender;
          bValue = b.gender;
          break;
        case 'color':
          aValue = a.color || '';
          bValue = b.color || '';
          break;
        default:
          aValue = a.name.toLowerCase();
          bValue = b.name.toLowerCase();
      }

      if (aValue < bValue) return filters.sortOrder === 'asc' ? -1 : 1;
      if (aValue > bValue) return filters.sortOrder === 'asc' ? 1 : -1;
      return 0;
    });

    return filtered;
  }, [filters]);

  const getAgeLabel = useCallback((bird: Bird | Chick) => {
    const birthDate = 'hatchDate' in bird ? bird.hatchDate : bird.birthDate;
    if (!birthDate) return 'Bilinmiyor';
    
    const age = Math.floor((new Date().getTime() - new Date(birthDate).getTime()) / (1000 * 60 * 60 * 24));
    
    if (age < 365) return 'Genç';
    if (age < 1825) return 'Yetişkin';
    return 'Yaşlı';
  }, []);

  const getGenderLabel = useCallback((gender: string) => {
    switch (gender) {
      case 'male': return 'Erkek';
      case 'female': return 'Dişi';
      default: return 'Bilinmiyor';
    }
  }, []);

  const getSortLabel = useCallback((sortBy: SortOption) => {
    switch (sortBy) {
      case 'name': return 'İsim';
      case 'birthDate': return 'Doğum Tarihi';
      case 'gender': return 'Cinsiyet';
      case 'color': return 'Renk';
      default: return 'İsim';
    }
  }, []);

  return {
    filters,
    updateFilter,
    applyFilters,
    getFilteredAndSortedBirds,
    getAgeLabel,
    getGenderLabel,
    getSortLabel
  };
}; 