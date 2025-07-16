import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Save } from 'lucide-react';
import { toast } from '@/components/ui/use-toast';
import { useAuth } from '@/hooks/useAuth';

interface ProfileFormProps {
  initialFirstName: string;
  initialLastName: string;
}

const ProfileForm = ({ initialFirstName, initialLastName }: ProfileFormProps) => {
  const { loading, updateProfile } = useAuth();
  const [firstName, setFirstName] = useState(initialFirstName);
  const [lastName, setLastName] = useState(initialLastName);

  const handleSave = async () => {
    try {
      const { error } = await updateProfile({
        first_name: firstName,
        last_name: lastName,
      });

      if (error) {
        toast({
          title: 'Hata',
          description: 'Profil güncellenirken bir hata oluştu.',
          variant: 'destructive',
        });
      } else {
        toast({
          title: 'Başarılı!',
          description: 'Profiliniz güncellendi.',
        });
      }
    } catch (error) {
      toast({
        title: 'Hata',
        description: 'Bir hata oluştu. Lütfen tekrar deneyin.',
        variant: 'destructive',
      });
    }
  };

  return (
    <>
      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <Label htmlFor="firstName">Ad</Label>
          <Input
            id="firstName"
            value={firstName}
            onChange={(e) => setFirstName(e.target.value)}
            placeholder="Adınız"
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="lastName">Soyad</Label>
          <Input
            id="lastName"
            value={lastName}
            onChange={(e) => setLastName(e.target.value)}
            placeholder="Soyadınız"
          />
        </div>
      </div>

      <Button 
        onClick={handleSave} 
        className="w-full budgie-button" 
        disabled={loading}
      >
        <Save className="w-4 h-4 mr-2" />
        {loading ? 'Kaydediliyor...' : 'Profili Güncelle'}
      </Button>
    </>
  );
};

export default ProfileForm;
