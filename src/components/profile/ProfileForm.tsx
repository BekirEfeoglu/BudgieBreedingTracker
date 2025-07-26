import { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Save, CheckCircle, AlertCircle } from 'lucide-react';
import { toast } from '@/components/ui/use-toast';
import { useAuth } from '@/hooks/useAuth';
import { validateName } from '@/utils/inputSanitization';

interface ProfileFormProps {
  initialFirstName: string | null | undefined;
  initialLastName: string | null | undefined;
}

const ProfileForm = ({ initialFirstName, initialLastName }: ProfileFormProps) => {
  const { loading, updateProfile } = useAuth();
  
  const [firstName, setFirstName] = useState<string>(initialFirstName || '');
  const [lastName, setLastName] = useState<string>(initialLastName || '');
  const [firstNameError, setFirstNameError] = useState('');
  const [lastNameError, setLastNameError] = useState('');
  const [isChanged, setIsChanged] = useState(false);

  // Prop'lar değiştiğinde state'leri güncelle
  useEffect(() => {
    const newFirstName = initialFirstName ?? '';
    const newLastName = initialLastName ?? '';
    
    // Sadece gerçek değişiklik varsa güncelle
    if (firstName !== newFirstName || lastName !== newLastName) {
      console.log('🔄 ProfileForm props değişti:', { initialFirstName, initialLastName });
      console.log('📝 Form state güncelleniyor:', { newFirstName, newLastName });
      
      setFirstName(newFirstName || '');
      setLastName(newLastName || '');
      setIsChanged(false);
      setFirstNameError('');
      setLastNameError('');
    }
  }, [initialFirstName, initialLastName]);

  // Değişiklikleri takip et
  useEffect(() => {
    const hasChanged = firstName !== (initialFirstName || '') || lastName !== (initialLastName || '');
    setIsChanged(hasChanged);
  }, [firstName, lastName, initialFirstName, initialLastName]);

  const validateForm = () => {
    let isValid = true;

    // Ad validasyonu
    const firstNameValidation = validateName(firstName);
    if (!firstNameValidation.isValid) {
      setFirstNameError(firstNameValidation.errors[0]);
      isValid = false;
    } else {
      setFirstNameError('');
    }

    // Soyad validasyonu
    const lastNameValidation = validateName(lastName);
    if (!lastNameValidation.isValid) {
      setLastNameError(lastNameValidation.errors[0]);
      isValid = false;
    } else {
      setLastNameError('');
    }

    return isValid;
  };

  const handleSave = async () => {
    if (!validateForm()) {
      toast({
        title: 'Validasyon Hatası',
        description: 'Lütfen form alanlarını kontrol edin.',
        variant: 'destructive',
      });
      return;
    }

    try {
      console.log('🔄 Profil güncelleniyor...', {
        first_name: firstName.trim(),
        last_name: lastName.trim()
      });

      const { error } = await updateProfile({
        first_name: firstName.trim(),
        last_name: lastName.trim(),
      });

      if (error) {
        console.error('❌ Profil güncelleme hatası:', error);
        toast({
          title: 'Güncelleme Hatası',
          description: error.message || 'Profil güncellenirken bir hata oluştu.',
          variant: 'destructive',
        });
      } else {
        console.log('✅ Profil başarıyla güncellendi');
        toast({
          title: 'Başarılı!',
          description: 'Profiliniz başarıyla güncellendi.',
        });
        
        // Form state'ini güncelle
        const trimmedFirstName = firstName.trim();
        const trimmedLastName = lastName.trim();
        
        console.log('🔄 Form state güncelleniyor:', { trimmedFirstName, trimmedLastName });
        
        setFirstName(trimmedFirstName);
        setLastName(trimmedLastName);
        setIsChanged(false);
        setFirstNameError('');
        setLastNameError('');
        
        // 2 saniye sonra state'i kontrol et
        setTimeout(() => {
          console.log('🔍 Form state kontrolü:', { 
            firstName: trimmedFirstName, 
            lastName: trimmedLastName,
            isChanged: false 
          });
        }, 2000);
      }
    } catch (error) {
      console.error('❌ Profil güncelleme exception:', error);
      toast({
        title: 'Hata',
        description: 'Bir hata oluştu. Lütfen tekrar deneyin.',
        variant: 'destructive',
      });
    }
  };

  const handleFirstNameChange = (value: string) => {
    setFirstName(value);
    if (firstNameError) {
      const validation = validateName(value);
      if (validation.isValid) {
        setFirstNameError('');
      }
    }
  };

  const handleLastNameChange = (value: string) => {
    setLastName(value);
    if (lastNameError) {
      const validation = validateName(value);
      if (validation.isValid) {
        setLastNameError('');
      }
    }
  };

  return (
    <div className="space-y-6">
      {/* Form Alanları */}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
        <div className="space-y-3">
          <Label htmlFor="firstName" className="text-sm font-semibold text-gray-700">
            Ad <span className="text-red-500">*</span>
          </Label>
          <div className="relative">
          <Input
            id="firstName"
            value={firstName}
              onChange={(e) => handleFirstNameChange(e.target.value)}
            placeholder="Adınız"
              className={`pr-12 h-12 text-base border-2 transition-all duration-300 ${
                firstNameError 
                  ? 'border-red-300 focus:border-red-500 bg-red-50' 
                  : 'border-gray-200 focus:border-green-500 focus:bg-green-50'
              }`}
              maxLength={50}
            />
            {firstNameError && (
              <AlertCircle className="w-5 h-5 text-red-500 absolute right-3 top-1/2 -translate-y-1/2" />
            )}
            {!firstNameError && firstName && (
              <CheckCircle className="w-5 h-5 text-green-500 absolute right-3 top-1/2 -translate-y-1/2" />
            )}
          </div>
          {firstNameError && (
            <p className="text-xs text-red-500 flex items-center gap-1">
              <AlertCircle className="w-3 h-3" />
              {firstNameError}
            </p>
          )}
        </div>

        <div className="space-y-3">
          <Label htmlFor="lastName" className="text-sm font-semibold text-gray-700">
            Soyad <span className="text-red-500">*</span>
          </Label>
          <div className="relative">
          <Input
            id="lastName"
            value={lastName}
              onChange={(e) => handleLastNameChange(e.target.value)}
            placeholder="Soyadınız"
              className={`pr-12 h-12 text-base border-2 transition-all duration-300 ${
                lastNameError 
                  ? 'border-red-300 focus:border-red-500 bg-red-50' 
                  : 'border-gray-200 focus:border-green-500 focus:bg-green-50'
              }`}
              maxLength={50}
            />
            {lastNameError && (
              <AlertCircle className="w-5 h-5 text-red-500 absolute right-3 top-1/2 -translate-y-1/2" />
            )}
            {!lastNameError && lastName && (
              <CheckCircle className="w-5 h-5 text-green-500 absolute right-3 top-1/2 -translate-y-1/2" />
            )}
          </div>
          {lastNameError && (
            <p className="text-xs text-red-500 flex items-center gap-1">
              <AlertCircle className="w-3 h-3" />
              {lastNameError}
            </p>
          )}
        </div>
      </div>

      {/* Önizleme */}
      {firstName || lastName ? (
        <div className="p-4 bg-gradient-to-r from-green-50 to-emerald-50 rounded-xl border border-green-200">
          <p className="text-sm text-green-700 font-medium mb-1">✨ Önizleme:</p>
          <p className="font-semibold text-green-800 text-lg">
            {firstName || 'Ad'} {lastName || 'Soyad'}
          </p>
        </div>
      ) : null}

      {/* Kaydet Butonu */}
      <Button 
        onClick={handleSave} 
        className="w-full h-12 bg-gradient-to-r from-green-500 to-emerald-600 hover:from-green-600 hover:to-emerald-700 text-white shadow-lg hover:shadow-xl transition-all duration-300 font-semibold" 
        disabled={loading || !isChanged || !firstName.trim() || !lastName.trim()}
      >
        <Save className="w-5 h-5 mr-2" />
        {loading ? 'Kaydediliyor...' : isChanged ? 'Değişiklikleri Kaydet' : 'Güncel'}
      </Button>

      {/* Bilgi Notu */}
      <div className="bg-gray-50 rounded-lg p-4 border border-gray-200">
        <p className="text-xs text-gray-600 font-medium mb-2">📝 Bilgi:</p>
        <div className="space-y-1 text-xs text-gray-600">
          <p>• Ad ve soyad alanları zorunludur</p>
          <p>• Maksimum 50 karakter kullanabilirsiniz</p>
          <p>• Sadece harf, boşluk ve Türkçe karakterler kabul edilir</p>
        </div>
      </div>
    </div>
  );
};

export default ProfileForm;
