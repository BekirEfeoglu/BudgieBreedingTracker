import { useState, useMemo, useCallback } from 'react';
import { Bird, Chick } from '@/types';

interface OptimizedGenealogyData {
  birds: Bird[];
  chicks: Chick[];
  isLoading: boolean;
  searchTerm: string;
  setSearchTerm: (term: string) => void;
  filteredBirds: Bird[];
  filteredChicks: Chick[];
  totalCount: number;
}

const PAGINATION_SIZE = 50;

export const useOptimizedGenealogyData = (allBirds: Bird[], allChicks: Chick[]): OptimizedGenealogyData => {
  const [searchTerm, setSearchTerm] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  // Memoized search function for performance
  const { filteredBirds, filteredChicks } = useMemo(() => {
    if (!searchTerm.trim()) {
      return {
        filteredBirds: allBirds.slice(0, PAGINATION_SIZE),
        filteredChicks: allChicks.slice(0, PAGINATION_SIZE)
      };
    }

    const searchLower = searchTerm.toLowerCase();
    
    const birds = allBirds.filter(bird => 
      bird.name.toLowerCase().includes(searchLower) ||
      bird.ringNumber?.toLowerCase().includes(searchLower) ||
      bird.color?.toLowerCase().includes(searchLower)
    ).slice(0, PAGINATION_SIZE);

    const chicks = allChicks.filter(chick => 
      chick.name.toLowerCase().includes(searchLower) ||
      chick.ringNumber?.toLowerCase().includes(searchLower) ||
      chick.color?.toLowerCase().includes(searchLower)
    ).slice(0, PAGINATION_SIZE);

    return { filteredBirds: birds, filteredChicks: chicks };
  }, [allBirds, allChicks, searchTerm]);

  // Debounced search to prevent excessive filtering
  const debouncedSetSearchTerm = useCallback((term: string) => {
    setIsLoading(true);
    const timer = setTimeout(() => {
      setSearchTerm(term);
      setIsLoading(false);
    }, 300);

    return () => clearTimeout(timer);
  }, []);

  const totalCount = filteredBirds.length + filteredChicks.length;

  return {
    birds: allBirds,
    chicks: allChicks,
    isLoading,
    searchTerm,
    setSearchTerm: debouncedSetSearchTerm,
    filteredBirds,
    filteredChicks,
    totalCount
  };
};
