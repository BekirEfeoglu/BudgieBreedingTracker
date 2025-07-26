
export const validateBirdData = (birdData: { name?: string }) => {
  if (!birdData.name || birdData.name.trim() === '') {
    return {
      isValid: false,
      error: 'Kuş adı boş olamaz.'
    };
  }
  
  return {
    isValid: true,
    error: null
  };
};

export const prepareBirdForDatabase = (bird: any) => {
  return {
    id: bird.id,
    name: bird.name.trim(),
    gender: bird.gender,
    color: bird.color || null,
    birth_date: bird.birthDate || null,
    ring_number: bird.ringNumber || null,
    photo_url: bird.photo || null,
    health_notes: bird.healthNotes || null,
    mother_id: bird.motherId || null,
    father_id: bird.fatherId || null
  };
};
