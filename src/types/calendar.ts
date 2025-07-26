export interface Event {
  id: number;
  date: string;
  title: string;
  description?: string;
  type: 'breeding' | 'health' | 'hatching' | 'mating' | 'feeding' | 'cleaning' | 'egg' | 'chick' | 'custom' | 'backup';
  icon: string;
  color: string;
  birdName?: string;
  time?: string;
  location?: string;
  status?: string;
  eggNumber?: number;
  parentNames?: string;
}