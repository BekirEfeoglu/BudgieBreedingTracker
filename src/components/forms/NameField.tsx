import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { FormControl, FormField, FormItem, FormLabel, FormMessage } from '@/components/ui/form';
import { Control } from 'react-hook-form';

interface NameFieldProps {
  control: Control<any>;
  onRandomName: () => void;
  onNameChange: (value: string) => void;
}

const birdNames = [
  'Luna', 'Apollo', 'Zara', 'Max', 'Bella', 'Charlie', 'Mia', 'Leo', 'Nala', 'Simba',
  'Coco', 'Kiwi', 'Mango', 'Peach', 'Berry', 'Sunny', 'Cloud', 'Storm', 'Rain', 'Sky'
];

const NameField = ({ control, onRandomName, onNameChange }: NameFieldProps) => {
  const generateRandomName = () => {
    const randomName = birdNames[Math.floor(Math.random() * birdNames.length)];
    onRandomName();
    onNameChange(randomName.toUpperCase());
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
