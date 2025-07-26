
export interface EggFormData {
  id?: string;
  clutchId: string; // Required field for incubation ID
  eggNumber: number;
  startDate: Date;
  status: 'laid' | 'fertile' | 'hatched' | 'infertile';
  notes?: string;
}

export interface Clutch {
  id: string;
  name: string;
  startDate: string;
  femaleBirdId: string;
  maleBirdId: string;
  notes?: string;
}

export interface EggWithClutch {
  id: string;
  clutchId: string; // incubation_id
  eggNumber: number;
  startDate: string;
  status: string;
  notes?: string;
  createdAt: string;
  updatedAt: string;
  clutch?: Clutch | null;
}
