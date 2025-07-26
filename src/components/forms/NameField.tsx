import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { FormControl, FormField, FormItem, FormLabel, FormMessage } from '@/components/ui/form';
import { Control } from 'react-hook-form';

interface NameFieldProps {
  control: Control<any>;
  onRandomName: () => void;
  onNameChange: (value: string) => void;
  gender?: 'male' | 'female' | 'unknown';
}

const birdNames = [
  // Klasik İsimler
  'Luna', 'Apollo', 'Zara', 'Max', 'Bella', 'Charlie', 'Mia', 'Leo', 'Nala', 'Simba',
  'Coco', 'Kiwi', 'Mango', 'Peach', 'Berry', 'Sunny', 'Cloud', 'Storm', 'Rain', 'Sky',
  
  // Yeni İsimler - Erkek
  'Atlas', 'Blaze', 'Cedar', 'Duke', 'Echo', 'Finn', 'Gunner', 'Hawk', 'Iris', 'Jasper',
  'Kai', 'Loki', 'Maverick', 'Nova', 'Orion', 'Phoenix', 'Quill', 'Rex', 'Shadow', 'Thunder',
  'Vega', 'Wolf', 'Xander', 'Zeus', 'Ace', 'Blitz', 'Cobalt', 'Diesel', 'Eagle', 'Falcon',
  
  // Yeni İsimler - Dişi
  'Aria', 'Blossom', 'Crystal', 'Dawn', 'Ember', 'Flora', 'Gem', 'Harmony', 'Ivy', 'Jade',
  'Kira', 'Lily', 'Misty', 'Nova', 'Opal', 'Pearl', 'Quinn', 'Rose', 'Sage', 'Terra',
  'Uma', 'Violet', 'Willow', 'Xena', 'Yara', 'Zara', 'Amber', 'Breeze', 'Coral', 'Dove',
  
  // Renk Temalı İsimler
  'Azure', 'Crimson', 'Emerald', 'Golden', 'Indigo', 'Jade', 'Lavender', 'Maroon', 'Onyx', 'Ruby',
  'Sapphire', 'Teal', 'Violet', 'White', 'Yellow', 'Amber', 'Bronze', 'Copper', 'Silver', 'Gold',
  
  // Doğa Temalı İsimler
  'Aspen', 'Birch', 'Cedar', 'Dawn', 'Echo', 'Flora', 'Grove', 'Haven', 'Iris', 'Juniper',
  'Kestrel', 'Lark', 'Meadow', 'Nest', 'Oak', 'Pine', 'Quail', 'Raven', 'Sparrow', 'Thrush',
  'Vireo', 'Wren', 'Yarrow', 'Zinnia', 'Aster', 'Bluebell', 'Clover', 'Daisy', 'Elder', 'Fern',
  
  // Mitolojik İsimler
  'Athena', 'Bacchus', 'Cupid', 'Diana', 'Eros', 'Flora', 'Gaia', 'Helios', 'Iris', 'Juno',
  'Kronos', 'Luna', 'Mars', 'Neptune', 'Orion', 'Perseus', 'Quirinus', 'Rhea', 'Selene', 'Thor',
  'Uranus', 'Venus', 'Zeus', 'Apollo', 'Artemis', 'Demeter', 'Hades', 'Hera', 'Hermes', 'Poseidon',
  
  // Modern İsimler
  'Aiden', 'Blake', 'Cameron', 'Dylan', 'Eden', 'Finley', 'Gray', 'Harper', 'Indigo', 'Jordan',
  'Kendall', 'Logan', 'Morgan', 'Nova', 'Ocean', 'Parker', 'Quinn', 'River', 'Sage', 'Taylor',
  'Unity', 'Vale', 'Winter', 'Xander', 'Yale', 'Zen', 'Avery', 'Blair', 'Casey', 'Drew',
  
  // Türkçe İsimler
  'Alp', 'Bora', 'Cem', 'Deniz', 'Ege', 'Fırat', 'Güneş', 'Hakan', 'Irmak', 'Jade',
  'Kaya', 'Leyla', 'Mert', 'Naz', 'Ozan', 'Pembe', 'Rüzgar', 'Selin', 'Toprak', 'Umut',
  'Veda', 'Yağmur', 'Zeynep', 'Aslan', 'Bülbül', 'Çiçek', 'Derya', 'Ece', 'Fidan', 'Gül'
];

const NameField = ({ control, onRandomName, onNameChange, gender }: NameFieldProps) => {
  const generateRandomName = () => {
    // Cinsiyete göre isim filtreleme
    let filteredNames = birdNames;
    
    if (gender === 'male') {
      // Erkek isimleri (güçlü, kısa, sert sesli)
      filteredNames = [
        'Apollo', 'Atlas', 'Blaze', 'Cedar', 'Duke', 'Echo', 'Finn', 'Gunner', 'Hawk',
        'Jasper', 'Kai', 'Loki', 'Maverick', 'Orion', 'Phoenix', 'Quill', 'Rex', 'Shadow',
        'Thunder', 'Vega', 'Wolf', 'Xander', 'Zeus', 'Ace', 'Blitz', 'Cobalt', 'Diesel',
        'Eagle', 'Falcon', 'Alp', 'Bora', 'Cem', 'Deniz', 'Ege', 'Fırat', 'Güneş', 'Hakan',
        'Kaya', 'Mert', 'Ozan', 'Toprak', 'Umut', 'Aslan'
      ];
    } else if (gender === 'female') {
      // Dişi isimleri (yumuşak, uzun, melodik)
      filteredNames = [
        'Luna', 'Aria', 'Blossom', 'Crystal', 'Dawn', 'Ember', 'Flora', 'Gem', 'Harmony',
        'Ivy', 'Jade', 'Kira', 'Lily', 'Misty', 'Opal', 'Pearl', 'Quinn', 'Rose', 'Sage',
        'Terra', 'Uma', 'Violet', 'Willow', 'Xena', 'Yara', 'Zara', 'Amber', 'Breeze',
        'Coral', 'Dove', 'Leyla', 'Naz', 'Pembe', 'Selin', 'Veda', 'Yağmur', 'Zeynep',
        'Bülbül', 'Çiçek', 'Derya', 'Ece', 'Fidan', 'Gül'
      ];
    }
    
    const randomIndex = Math.floor(Math.random() * filteredNames.length);
    const randomName = filteredNames[randomIndex];
    if (randomName) {
      onRandomName();
      onNameChange(randomName.toUpperCase());
    }
  };

  return (
    <FormField
      control={control}
      name="name"
      render={({ field }) => (
        <FormItem>
          <FormLabel className="flex items-center justify-between">
            İsim *
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={generateRandomName}
              className="ml-2"
              title={`${gender === 'male' ? 'Erkek' : gender === 'female' ? 'Dişi' : 'Tüm'} isimlerden rastgele seç`}
            >
              Rastgele İsim
            </Button>
          </FormLabel>
          <FormControl>
            <Input 
              {...field}
              onChange={(e) => onNameChange(e.target.value)}
              placeholder="Kuş ismini girin"
            />
          </FormControl>
          <FormMessage />
        </FormItem>
      )}
    />
  );
};

export default NameField;
