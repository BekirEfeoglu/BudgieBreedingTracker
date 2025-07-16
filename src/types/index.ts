export type EggStatus = 'unknown' | 'laid' | 'fertile' | 'infertile' | 'hatched';

export interface Bird {
  id: string;
  name: string;
  gender: 'male' | 'female' | 'unknown';
  color?: string;
  birthDate?: string;
  ringNumber?: string;
  photo?: string;
  healthNotes?: string;
  status?: 'alive' | 'dead' | 'sold';
  deathDate?: string;
  soldDate?: string;
  motherId?: string;
  fatherId?: string;
}

export interface Nest {
  id: string;
  name: string;
  pairId?: string;
  maleBirdId?: string;
  femaleBirdId?: string;
  createdAt: string;
  userId: string;
}

export interface Chick {
  id: string;
  name: string;
  breedingId: string;
  eggId?: string;
  hatchDate: string;
  gender: 'male' | 'female' | 'unknown';
  color?: string;
  ringNumber?: string;
  photo?: string;
  healthNotes?: string;
  motherId?: string;
  fatherId?: string;
}

export interface Egg {
  id: string;
  breedingId: string;
  nestId?: string;
  layDate: string;
  status: EggStatus;
  hatchDate?: string;
  notes?: string;
  chickId?: string;
  number: number;
  motherId?: string;
  fatherId?: string;
  dateAdded?: string;
}

export interface Breeding {
  id: string;
  maleBirdId: string;
  femaleBirdId: string;
  pairDate: string;
  expectedHatchDate?: string;
  notes?: string;
  eggs?: Egg[];
  maleBird?: string;
  femaleBird?: string;
  nestName?: string;
  nestId?: string;
}

export interface BreedingRecord {
  id: string;
  nestName: string;
  maleBird: string;
  femaleBird: string;
  startDate: string;
  eggs: Egg[];
  type?: 'incubation' | 'breeding';
  incubationData?: any;
}
