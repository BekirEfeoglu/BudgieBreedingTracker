

export const sampleBirds = [
  {
    id: '1',
    name: 'Luna',
    gender: 'female' as const,
    color: 'Sarı-Yeşil',
    birthDate: '2023-03-15',
    ringNumber: 'LN001',
    healthNotes: 'Sağlıklı, aktif kuş. Düzenli kontroller yapılıyor.',
    status: 'alive',
  },
  {
    id: '2',
    name: 'Apollo',
    gender: 'male' as const,
    color: 'Mavi-Beyaz',
    birthDate: '2023-02-10',
    ringNumber: 'AP002',
    healthNotes: 'Çok konuşkan ve sosyal.',
    status: 'dead',
  },
  {
    id: '3',
    name: 'Zara',
    gender: 'female' as const,
    color: 'Yeşil-Sarı',
    birthDate: '2023-04-20',
    ringNumber: 'ZR003',
    status: 'sold',
  }
];

export const sampleBreeding = [
  {
    id: '1',
    nestName: 'Yuva 1',
    maleBird: 'Apollo',
    femaleBird: 'Luna',
    startDate: '2024-06-15',
    eggs: [
      { id: '1', number: 1, status: 'fertile' as const, dateAdded: '2024-06-16', motherId: '1', fatherId: '2' },
      { id: '2', number: 2, status: 'fertile' as const, dateAdded: '2024-06-18', motherId: '1', fatherId: '2' },
      { id: '3', number: 3, status: 'unknown' as const, dateAdded: '2024-06-20', motherId: '1', fatherId: '2' },
      { id: '4', number: 4, status: 'hatched' as const, dateAdded: '2024-06-22', motherId: '1', fatherId: '2' }
    ]
  }
];

export const sampleChicks = [
  {
    id: '1',
    name: 'Pıtırcık',
    birthDate: '2024-06-25',
    motherId: '1',
    fatherId: '2',
    breedingId: '1',
    gender: 'unknown' as const,
    color: 'Sarı-Yeşil',
    ringNumber: '',
    photo: '',
    healthNotes: 'Sağlıklı gelişiyor, tüyleri çıkmaya başladı.'
  },
  {
    id: '2',
    name: 'Minnoş',
    birthDate: '2024-06-20',
    motherId: '3',
    fatherId: '2',
    breedingId: '1',
    gender: 'female' as const,
    color: 'Yeşil-Sarı',
    ringNumber: '',
    photo: '',
    healthNotes: 'Sağlıklı büyüyor.'
  }
];

