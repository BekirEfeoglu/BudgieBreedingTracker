
interface Bird {
  id: string;
  name: string;
  gender: 'male' | 'female' | 'unknown';
}

export interface BirdPair {
  id: string;
  maleBird: Bird;
  femaleBird: Bird;
  displayName: string;
  maleName: string;
  femaleName: string;
}

export const createBirdPairs = (birds: Bird[]): BirdPair[] => {
  const maleBirds = birds.filter(bird => bird.gender === 'male');
  const femaleBirds = birds.filter(bird => bird.gender === 'female');
  
  const pairs: BirdPair[] = [];
  maleBirds.forEach(male => {
    femaleBirds.forEach(female => {
      pairs.push({
        id: `${male.id}-${female.id}`,
        maleBird: male,
        femaleBird: female,
        displayName: `${male.name} ♂ × ${female.name} ♀`,
        maleName: male.name,
        femaleName: female.name
      });
    });
  });
  
  return pairs;
};
