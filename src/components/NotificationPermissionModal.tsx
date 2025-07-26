
import React from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Bell, Shield, Clock, AlertCircle } from 'lucide-react';

interface NotificationPermissionModalProps {
  isOpen: boolean;
  onClose: () => void;
  onRequestPermission: () => void;
}

export const NotificationPermissionModal: React.FC<NotificationPermissionModalProps> = ({
  isOpen,
  onClose,
  onRequestPermission
}) => {
  const handleAllow = () => {
    onRequestPermission();
    onClose();
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-md" aria-describedby="notification-permission-description">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Bell className="w-5 h-5 text-blue-500" />
            Bildirim İzni
          </DialogTitle>
          <div id="notification-permission-description" className="sr-only">
            Bildirim izni hakkında açıklama
          </div>
        </DialogHeader>

        <div className="space-y-4">
          <div className="text-center">
            <div className="mx-auto w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mb-4">
              <Bell className="w-8 h-8 text-blue-500" />
            </div>
            <h3 className="font-semibold text-lg mb-2">
              Önemli Bildirimleri Kaçırmayın
            </h3>
            <p className="text-muted-foreground text-sm">
              Bildirim izni verirseniz, önemli gelişmelerden haberdar olabilirsiniz.
            </p>
          </div>

          <div className="space-y-3">
            <div className="flex items-start gap-3">
              <Clock className="w-5 h-5 text-green-500 mt-0.5" />
              <div>
                <p className="font-medium text-sm">Kuluçka Hatırlatmaları</p>
                <p className="text-muted-foreground text-xs">
                  Yumurta çıkış zamanları yaklaştığında bildirim
                </p>
              </div>
            </div>

            <div className="flex items-start gap-3">
              <AlertCircle className="w-5 h-5 text-orange-500 mt-0.5" />
              <div>
                <p className="font-medium text-sm">Önemli Güncellemeler</p>
                <p className="text-muted-foreground text-xs">
                  Sistem bildirimleri ve kritik uyarılar
                </p>
              </div>
            </div>

            <div className="flex items-start gap-3">
              <Shield className="w-5 h-5 text-blue-500 mt-0.5" />
              <div>
                <p className="font-medium text-sm">Güvenlik & Gizlilik</p>
                <p className="text-muted-foreground text-xs">
                  Verileriniz güvende, istenmeyen bildirim göndermiyoruz
                </p>
              </div>
            </div>
          </div>

          <div className="bg-gray-50 p-3 rounded-lg">
            <p className="text-xs text-muted-foreground text-center">
              İstediğiniz zaman tarayıcı ayarlarından bildirimleri kapatabilirsiniz
            </p>
          </div>

          <div className="flex gap-2 pt-2">
            <Button 
              variant="outline" 
              onClick={onClose}
              className="flex-1"
            >
              Şimdi Değil
            </Button>
            <Button 
              onClick={handleAllow}
              className="flex-1"
            >
              İzin Ver
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
};
