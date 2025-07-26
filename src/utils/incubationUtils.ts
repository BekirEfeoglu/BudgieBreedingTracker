import { differenceInDays, addDays } from 'date-fns';

export const INCUBATION_PERIOD_DAYS = 18;

export interface IncubationProgress {
  daysElapsed: number;
  daysRemaining: number;
  percentageComplete: number;
  isComplete: boolean;
  expectedHatchDate: Date;
}

export const calculateIncubationProgress = (startDate: Date): IncubationProgress => {
  const today = new Date();
  const daysElapsed = Math.max(0, differenceInDays(today, startDate));
  const daysRemaining = Math.max(0, INCUBATION_PERIOD_DAYS - daysElapsed);
  const percentageComplete = Math.min(100, (daysElapsed / INCUBATION_PERIOD_DAYS) * 100);
  const expectedHatchDate = addDays(startDate, INCUBATION_PERIOD_DAYS);
  
  return {
    daysElapsed,
    daysRemaining,
    percentageComplete,
    isComplete: daysElapsed >= INCUBATION_PERIOD_DAYS,
    expectedHatchDate
  };
};

export const formatIncubationStatus = (progress: IncubationProgress): string => {
  if (progress.isComplete) {
    return 'Kuluçka tamamlandı';
  }
  
  if (progress.daysRemaining === 0) {
    return 'Bugün çıkması bekleniyor';
  }
  
  return `%${Math.round(progress.percentageComplete)}`;
};
