import { useState, useEffect } from 'react';

interface DateTimeState {
  currentDate: Date;
  formattedDate: string;
  formattedTime: string;
  relativeTime: string;
}

export const useDateTimeUpdater = (updateInterval: number = 60000) => {
  const [dateTime, setDateTime] = useState<DateTimeState>(() => {
    const now = new Date();
    return {
      currentDate: now,
      formattedDate: now.toLocaleDateString('tr-TR', {
        weekday: 'long',
        year: 'numeric',
        month: 'long',
        day: 'numeric'
      }),
      formattedTime: now.toLocaleTimeString('tr-TR', {
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
      }),
      relativeTime: 'şimdi'
    };
  });

  useEffect(() => {
    const updateDateTime = () => {
      const now = new Date();
      setDateTime({
        currentDate: now,
        formattedDate: now.toLocaleDateString('tr-TR', {
          weekday: 'long',
          year: 'numeric',
          month: 'long',
          day: 'numeric'
        }),
        formattedTime: now.toLocaleTimeString('tr-TR', {
          hour: '2-digit',
          minute: '2-digit',
          second: '2-digit'
        }),
        relativeTime: getRelativeTime(now)
      });
    };

    // Update immediately
    updateDateTime();

    // Set up interval for regular updates
    const interval = setInterval(updateDateTime, updateInterval);

    return () => clearInterval(interval);
  }, [updateInterval]);

  return dateTime;
};

const getRelativeTime = (date: Date): string => {
  const now = new Date();
  const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);

  if (diffInSeconds < 60) {
    return 'şimdi';
  } else if (diffInSeconds < 3600) {
    const minutes = Math.floor(diffInSeconds / 60);
    return `${minutes} dakika önce`;
  } else if (diffInSeconds < 86400) {
    const hours = Math.floor(diffInSeconds / 3600);
    return `${hours} saat önce`;
  } else {
    const days = Math.floor(diffInSeconds / 86400);
    return `${days} gün önce`;
  }
};