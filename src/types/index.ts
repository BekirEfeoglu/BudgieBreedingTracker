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
  egg_id?: string; // Veritabanı alan adı
  incubationId?: string;
  incubation_id?: string; // Veritabanı alan adı
  incubationName?: string;
  eggNumber?: number;
  hatchDate: string;
  hatch_date?: string; // Veritabanı alan adı
  gender: 'male' | 'female' | 'unknown';
  color?: string;
  ringNumber?: string;
  ring_number?: string; // Veritabanı alan adı
  photo?: string;
  healthNotes?: string;
  health_notes?: string; // Veritabanı alan adı
  motherId?: string;
  mother_id?: string; // Veritabanı alan adı
  fatherId?: string;
  father_id?: string; // Veritabanı alan adı
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
