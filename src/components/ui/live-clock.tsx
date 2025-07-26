import React from 'react';
import { useDateTimeUpdater } from '@/hooks/useDateTimeUpdater';
import { Card } from '@/components/ui/card';
import { Clock, Calendar } from 'lucide-react';

interface LiveClockProps {
  variant?: 'compact' | 'full';
  showDate?: boolean;
  showSeconds?: boolean;
  updateInterval?: number;
}

export const LiveClock: React.FC<LiveClockProps> = ({
  variant = 'compact',
  showDate = true,
  showSeconds = true,
  updateInterval = 1000
}) => {
  const { formattedDate, formattedTime } = useDateTimeUpdater(updateInterval);

  if (variant === 'compact') {
    return (
      <div className="flex items-center gap-2 text-sm text-muted-foreground">
        <Clock className="w-4 h-4" />
        <span>{showSeconds ? formattedTime : formattedTime.substring(0, 5)}</span>
        {showDate && (
          <>
            <Calendar className="w-4 h-4" />
            <span>{formattedDate}</span>
          </>
        )}
      </div>
    );
  }

  return (
    <Card className="p-4">
      <div className="space-y-2">
        <div className="flex items-center gap-2">
          <Clock className="w-5 h-5 text-primary" />
          <span className="text-lg font-mono font-bold">
            {showSeconds ? formattedTime : formattedTime.substring(0, 5)}
          </span>
        </div>
        {showDate && (
          <div className="flex items-center gap-2">
            <Calendar className="w-5 h-5 text-primary" />
            <span className="text-sm text-muted-foreground">{formattedDate}</span>
          </div>
        )}
      </div>
    </Card>
  );
};