import { useState, useEffect, useCallback } from 'react';
import { Bird, Chick } from '@/types';

interface BirdHistory {
  favorites: string[]; // bird IDs
  recent: string[]; // bird IDs, max 10
}

const STORAGE_KEY = 'bird-genealogy-history';
const MAX_RECENT = 10;
const MAX_FAVORITES = 20;

export const useBirdHistory = () => {
  const [history, setHistory] = useState<BirdHistory>({
    favorites: [],
    recent: []
  });

  // Load from localStorage on mount
  useEffect(() => {
    try {
      const stored = localStorage.getItem(STORAGE_KEY);
      if (stored) {
        const parsed = JSON.parse(stored);
        setHistory({
          favorites: parsed.favorites || [],
          recent: parsed.recent || []
        });
      }
    } catch (error) {
      console.warn('Failed to load bird history:', error);
    }
  }, []);

  // Save to localStorage
  const saveHistory = useCallback((newHistory: BirdHistory) => {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(newHistory));
      setHistory(newHistory);
    } catch (error) {
      console.warn('Failed to save bird history:', error);
    }
  }, []);

  // Add to recent selections
  const addToRecent = useCallback((birdId: string) => {
    setHistory(prev => {
      const newRecent = [birdId, ...prev.recent.filter(id => id !== birdId)].slice(0, MAX_RECENT);
      const newHistory = { ...prev, recent: newRecent };
      saveHistory(newHistory);
      return newHistory;
    });
  }, [saveHistory]);

  // Toggle favorite
  const toggleFavorite = useCallback((birdId: string) => {
    setHistory(prev => {
      const isFavorite = prev.favorites.includes(birdId);
      let newFavorites: string[];
      
      if (isFavorite) {
        newFavorites = prev.favorites.filter(id => id !== birdId);
      } else {
        newFavorites = [birdId, ...prev.favorites].slice(0, MAX_FAVORITES);
      }
      
      const newHistory = { ...prev, favorites: newFavorites };
      saveHistory(newHistory);
      return newHistory;
    });
  }, [saveHistory]);

  // Add to favorites
  const addToFavorites = useCallback((birdId: string) => {
    setHistory(prev => {
      if (!prev.favorites.includes(birdId)) {
        const newFavorites = [birdId, ...prev.favorites].slice(0, MAX_FAVORITES);
        const newHistory = { ...prev, favorites: newFavorites };
        saveHistory(newHistory);
        return newHistory;
      }
      return prev;
    });
  }, [saveHistory]);

  // Remove from favorites
  const removeFromFavorites = useCallback((birdId: string) => {
    setHistory(prev => {
      const newFavorites = prev.favorites.filter(id => id !== birdId);
      const newHistory = { ...prev, favorites: newFavorites };
      saveHistory(newHistory);
      return newHistory;
    });
  }, [saveHistory]);

  // Check if bird is favorite
  const isFavorite = useCallback((birdId: string) => {
    return history.favorites.includes(birdId);
  }, [history.favorites]);

  // Get sorted birds with favorites and recent priority
  const getSortedBirds = useCallback((birds: (Bird | Chick)[]) => {
    return birds.sort((a, b) => {
      const aIsFavorite = history.favorites.includes(a.id);
      const bIsFavorite = history.favorites.includes(b.id);
      const aIsRecent = history.recent.includes(a.id);
      const bIsRecent = history.recent.includes(b.id);

      // Favorites first
      if (aIsFavorite && !bIsFavorite) return -1;
      if (!aIsFavorite && bIsFavorite) return 1;

      // Then recent
      if (aIsRecent && !bIsRecent) return -1;
      if (!aIsRecent && bIsRecent) return 1;

      // Then by name
      return a.name.localeCompare(b.name);
    });
  }, [history.favorites, history.recent]);

  // Clear history
  const clearHistory = useCallback(() => {
    const newHistory = { favorites: [], recent: [] };
    saveHistory(newHistory);
  }, [saveHistory]);

  return {
    history,
    favorites: history.favorites,
    addToRecent,
    toggleFavorite,
    addToFavorites,
    removeFromFavorites,
    isFavorite,
    getSortedBirds,
    clearHistory
  };
}; 