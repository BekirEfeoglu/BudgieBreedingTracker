
import React from 'react';
import { Bird, Chick } from '@/types';

interface GenealogyFiltersProps {
  birds: Bird[];
  chicks: Chick[];
  searchTerm: string;
  genderFilter: string;
  typeFilter: string;
}

export const useGenealogyFilters = ({
  birds,
  chicks,
  searchTerm,
  genderFilter,
  typeFilter
}: GenealogyFiltersProps) => {
  const filteredBirds = React.useMemo(() => {
    return birds.filter(bird => {
      const matchesSearch = searchTerm === '' || 
        bird.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        (bird.ringNumber && bird.ringNumber.toLowerCase().includes(searchTerm.toLowerCase()));
      
      const matchesGender = genderFilter === 'all' || bird.gender === genderFilter;
      const matchesType = typeFilter === 'all' || typeFilter === 'adult';
      
      return matchesSearch && matchesGender && matchesType;
    });
  }, [birds, searchTerm, genderFilter, typeFilter]);

  const filteredChicks = React.useMemo(() => {
    return chicks.filter(chick => {
      const matchesSearch = searchTerm === '' || 
        chick.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        (chick.ringNumber && chick.ringNumber.toLowerCase().includes(searchTerm.toLowerCase()));
      
      const matchesGender = genderFilter === 'all' || chick.gender === genderFilter;
      const matchesType = typeFilter === 'all' || typeFilter === 'chick';
      
      return matchesSearch && matchesGender && matchesType;
    });
  }, [chicks, searchTerm, genderFilter, typeFilter]);

  return { filteredBirds, filteredChicks };
};
