import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Switch } from '@/components/ui/switch';
import { toast } from '@/hooks/use-toast';
import { useTheme } from '@/contexts/ThemeContext';
import { Palette, Moon, Sun } from 'lucide-react';

const AppearanceSettings = () => {
  const { theme, toggleTheme } = useTheme();

  const handleDarkModeToggle = (checked: boolean) => {
    toggleTheme();
    toast({
      title: checked ? 'Karanlık Mod Etkinleştirildi' : 'Açık Mod Etkinleştirildi',
      description: 'Tema başarıyla değiştirildi',
    });
  };

  return (
    <Card className="enhanced-card">
      <CardHeader className="pb-4">
        <CardTitle className="flex items-center gap-2 text-lg mobile-text-lg enhanced-text-primary">
          <Palette className="w-5 h-5" />
          Görünüm
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-6">
        <div className="flex items-center justify-between py-3">
          <div className="flex items-center gap-4">
            {theme === 'dark' ? 
              <Moon className="w-6 h-6 text-blue-500" /> : 
              <Sun className="w-6 h-6 text-yellow-500" />
            }
            <div className="flex-1">
              <p className="font-semibold text-base mobile-text-base enhanced-text-primary">
                Karanlık Mod
              </p>
              <p className="text-sm mobile-text-sm enhanced-text-secondary">
                Koyu renk temasını etkinleştir
              </p>
            </div>
          </div>
          <Switch
            checked={theme === 'dark'}
            onCheckedChange={handleDarkModeToggle}
            className="mobile-switch"
          />
        </div>
      </CardContent>
    </Card>
  );
};

export default AppearanceSettings;
