import React from 'react';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Bell, Settings, Info } from 'lucide-react';

interface NotificationPermissionModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onRequestPermission: () => Promise<boolean>;
}

export const NotificationPermissionModal: React.FC<NotificationPermissionModalProps> = ({
  open,
  onOpenChange,
  onRequestPermission
}) => {
  const handleRequestPermission = async () => {
    const granted = await onRequestPermission();
    if (granted) {
      onOpenChange(false);
    }
  };

  const handleOpenSettings = () => {
    // Tarayıcı ayarlarını açmaya çalış
    if (navigator.userAgent.includes('Chrome')) {
      window.open('chrome://settings/content/notifications', '_blank');
    } else if (navigator.userAgent.includes('Firefox')) {
      window.open('about:preferences#privacy', '_blank');
    } else if (navigator.userAgent.includes('Safari')) {
      window.open('x-apple.systempreferences:com.apple.preference.notifications', '_blank');
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md" aria-describedby="notification-permission-description">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Bell className="h-5 w-5 text-primary" />
            Bildirim İzni Gerekli
          </DialogTitle>
          <div id="notification-permission-description" className="sr-only">
            Bildirim izni hakkında açıklama.
          </div>
          <DialogDescription>
            Hatırlatıcılarınızın düzgün çalışması için bildirim iznine ihtiyacımız var.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          <div className="bg-muted/50 rounded-lg p-4">
            <div className="flex items-start gap-3">
              <Info className="h-5 w-5 text-muted-foreground mt-0.5" />
              <div className="space-y-2">
                <h4 className="font-medium text-sm">Bildirimler şunlar için kullanılır:</h4>
                <ul className="text-sm text-muted-foreground space-y-1">
                  <li>• 🥚 Kuluçka sıcaklık ve nem kontrolleri</li>
                  <li>• 🍽️ Yavru ve kuş beslenme zamanları</li>
                  <li>• 🏥 Veteriner randevu hatırlatıcıları</li>
                  <li>• ❤️ Üreme döngüsü takibi</li>
                  <li>• 📅 Yarışma ve sergi tarihleri</li>
                </ul>
              </div>
            </div>
          </div>

          <div className="bg-blue-50 dark:bg-blue-950/20 rounded-lg p-4">
            <div className="flex items-start gap-3">
              <Settings className="h-5 w-5 text-blue-600 dark:text-blue-400 mt-0.5" />
              <div>
                <h4 className="font-medium text-sm text-blue-900 dark:text-blue-100 mb-1">
                  İzin reddedildi mi?
                </h4>
                <p className="text-sm text-blue-700 dark:text-blue-300">
                  Tarayıcı ayarlarından manuel olarak izin verebilirsiniz.
                </p>
              </div>
            </div>
          </div>
        </div>

        <DialogFooter className="flex flex-col sm:flex-row gap-2">
          <Button
            variant="outline"
            onClick={handleOpenSettings}
            className="w-full sm:w-auto"
          >
            <Settings className="h-4 w-4 mr-2" />
            Ayarları Aç
          </Button>
          <Button
            onClick={handleRequestPermission}
            className="w-full sm:w-auto"
          >
            <Bell className="h-4 w-4 mr-2" />
            İzin Ver
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};