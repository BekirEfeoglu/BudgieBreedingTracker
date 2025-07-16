
import { useState, useEffect } from 'react';
import { calculateIncubationProgress, IncubationProgress } from '@/utils/incubationUtils';

export const useIncubationTimer = (startDate: Date) => {
  const [progress, setProgress] = useState<IncubationProgress>(() => 
    calculateIncubationProgress(startDate)
  );

  useEffect(() => {
    // Initial calculation
    setProgress(calculateIncubationProgress(startDate));

    // Calculate time until next midnight
    const now = new Date();
    const tomorrow = new Date(now);
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(0, 0, 0, 0);
    const msUntilMidnight = tomorrow.getTime() - now.getTime();

    // Set initial timeout for midnight
    const midnightTimeout = setTimeout(() => {
      setProgress(calculateIncubationProgress(startDate));
      
      // Set up daily interval after first midnight update
      const dailyInterval = setInterval(() => {
        setProgress(calculateIncubationProgress(startDate));
      }, 24 * 60 * 60 * 1000); // 24 hours

      return () => clearInterval(dailyInterval);
    }, msUntilMidnight);

    return () => clearTimeout(midnightTimeout);
  }, [startDate]);

  return progress;
};
