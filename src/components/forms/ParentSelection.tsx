import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { FormControl, FormField, FormItem, FormLabel } from '@/components/ui/form';
import { Control } from 'react-hook-form';

interface ParentSelectionProps {
  control: Control<any>;
  existingBirds: Array<{ id: string; name: string; gender: 'male' | 'female' | 'unknown' }>;
}

const ParentSelection = ({ control, existingBirds }: ParentSelectionProps) => {
  const motherOptions = existingBirds.filter(bird => bird.gender === 'female');
  const fatherOptions = existingBirds.filter(bird => bird.gender === 'male');

  return (
    <>
      {/* Anne */}
      <FormField
        control={control}
        name="motherId"
        render={({ field }) => (
          <FormItem>
            <FormLabel>Anne</FormLabel>
            <FormControl>
              <Select value={field.value || undefined} onValueChange={field.onChange}>
                <SelectTrigger>
                  <SelectValue placeholder="Anne seçin" />
                </SelectTrigger>
                <SelectContent>
                  {motherOptions.map((bird) => (
                    <SelectItem key={bird.id} value={bird.id}>
                      {bird.name} ♀️
                    </SelectItem>
                  ))}
                  {motherOptions.length === 0 && (
                    <div className="px-2 py-1.5 text-sm text-muted-foreground">
                      Dişi kuş bulunamadı
                    </div>
                  )}
                </SelectContent>
              </Select>
            </FormControl>
          </FormItem>
        )}
      />

      {/* Baba */}
      <FormField
        control={control}
        name="fatherId"
        render={({ field }) => (
          <FormItem>
            <FormLabel>Baba</FormLabel>
            <FormControl>
              <Select value={field.value || undefined} onValueChange={field.onChange}>
                <SelectTrigger>
                  <SelectValue placeholder="Baba seçin" />
                </SelectTrigger>
                <SelectContent>
                  {fatherOptions.map((bird) => (
                    <SelectItem key={bird.id} value={bird.id}>
                      {bird.name} ♂️
                    </SelectItem>
                  ))}
                  {fatherOptions.length === 0 && (
                    <div className="px-2 py-1.5 text-sm text-muted-foreground">
                      Erkek kuş bulunamadı
                    </div>
                  )}
                </SelectContent>
              </Select>
            </FormControl>
          </FormItem>
        )}
      />
    </>
  );
};

export default ParentSelection;
