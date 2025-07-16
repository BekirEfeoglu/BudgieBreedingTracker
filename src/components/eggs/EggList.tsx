import React from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { EggWithClutch } from '@/types/egg';
import EggListHeader from './list/EggListHeader';
import EggListEmpty from './list/EggListEmpty';
import EggListItem from './list/EggListItem';

interface EggListProps {
  eggs: EggWithClutch[];
  loading: boolean;
  onAddEgg: () => void;
  onEditEgg: (egg: EggWithClutch) => void;
  onDeleteEgg: (eggId: string, eggNumber: number) => void;
}

const EggList: React.FC<EggListProps> = ({
  eggs,
  loading,
  onAddEgg,
  onEditEgg,
  onDeleteEgg
}) => {
  const eggCount = eggs.length;
  
  if (loading && eggCount === 0) {
    return (
      <div className="space-y-4">
        <EggListHeader eggCount={0} onAddEgg={onAddEgg} disabled />
        <div className="grid gap-4">
          {[1, 2, 3].map((i) => (
            <Card key={i} className="animate-pulse">
              <CardContent className="p-4">
                <div className="h-4 bg-gray-200 rounded w-1/4 mb-2"></div>
                <div className="h-3 bg-gray-200 rounded w-1/2 mb-2"></div>
                <div className="h-3 bg-gray-200 rounded w-1/3"></div>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <EggListHeader eggCount={eggCount} onAddEgg={onAddEgg} />
      
      {eggCount === 0 ? (
        <EggListEmpty onAddEgg={onAddEgg} />
      ) : (
        <div className="grid gap-4">
          {eggs.map((egg) => (
            <EggListItem
              key={egg.id}
              egg={egg}
              onEditEgg={onEditEgg}
              onDeleteEgg={onDeleteEgg}
            />
          ))}
        </div>
      )}
    </div>
  );
};

export default EggList;
