
export interface EggFormData {
  id?: string;
  clutchId: string; // Required field for incubation ID
  eggNumber: number;
  startDate: Date;
  status: 'laid' | 'fertile' | 'hatched' | 'infertile';
  notes?: string;
}

export interface EggWithClutch extends EggFormData {
  id: string;
  layDate: string;
  hatchDate?: string;
  createdAt: string;
  updatedAt: string;
}
