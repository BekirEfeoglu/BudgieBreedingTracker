import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { Bell, AlertTriangle, Info, CheckCircle, XCircle, Clock, Users, Egg, Baby } from 'lucide-react';

interface AlertItem {
  id: string;
  type: 'warning' | 'error' | 'info' | 'success';
  title: string;
  description: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  category: 'breeding' | 'health' | 'performance' | 'maintenance';
  timestamp: Date;
  isRead: boolean;
  actionRequired?: boolean;
  suggestedAction?: string;
}

interface AlertSystemProps {
  alerts: AlertItem[];
  onMarkAsRead: (alertId: string) => void;
  onDismiss: (alertId: string) => void;
}

const AlertSystem: React.FC<AlertSystemProps> = ({
  alerts,
  onMarkAsRead,
  onDismiss
}) => {
  const getAlertIcon = (type: AlertItem['type']) => {
    switch (type) {
      case 'warning':
        return <AlertTriangle className="w-5 h-5 md:w-6 md:h-6" />;
      case 'error':
        return <XCircle className="w-5 h-5 md:w-6 md:h-6" />;
      case 'info':
        return <Info className="w-5 h-5 md:w-6 md:h-6" />;
      case 'success':
        return <CheckCircle className="w-5 h-5 md:w-6 md:h-6" />;
    }
  };

  const getSeverityColor = (severity: AlertItem['severity'], isRead: boolean) => {
    let base = '';
    switch (severity) {
      case 'low':
        base = 'bg-blue-50 border-blue-200 text-blue-800'; break;
      case 'medium':
        base = 'bg-yellow-50 border-yellow-200 text-yellow-800'; break;
      case 'high':
        base = 'bg-orange-50 border-orange-200 text-orange-800'; break;
      case 'critical':
        base = 'bg-red-50 border-red-200 text-red-800'; break;
    }
    // Okunmamışsa hafif gölge ve animasyon
    return base + (!isRead ? ' shadow-lg shadow-blue-100 animate-pulse' : '');
  };

  const getCategoryIcon = (category: AlertItem['category']) => {
    switch (category) {
      case 'breeding':
        return <Users className="w-4 h-4" />;
      case 'health':
        return <Baby className="w-4 h-4" />;
      case 'performance':
        return <Egg className="w-4 h-4" />;
      case 'maintenance':
        return <Clock className="w-4 h-4" />;
    }
  };

  const getCategoryColor = (category: AlertItem['category']) => {
    switch (category) {
      case 'breeding':
        return 'bg-pink-500 text-white';
      case 'health':
        return 'bg-green-500 text-white';
      case 'performance':
        return 'bg-blue-500 text-white';
      case 'maintenance':
        return 'bg-gray-500 text-white';
    }
  };

  const unreadAlerts = alerts.filter(alert => !alert.isRead);
  const criticalAlerts = alerts.filter(alert => alert.severity === 'critical');
  const highPriorityAlerts = alerts.filter(alert => alert.severity === 'high' || alert.severity === 'critical');

  const formatTimestamp = (timestamp: Date) => {
    const now = new Date();
    const diff = now.getTime() - timestamp.getTime();
    const hours = Math.floor(diff / (1000 * 60 * 60));
    const days = Math.floor(hours / 24);

    if (days > 0) {
      return `${days} gün önce`;
    } else if (hours > 0) {
      return `${hours} saat önce`;
    } else {
      return 'Az önce';
    }
  };

  return (
    <Card className="rounded-2xl shadow-md p-2 md:p-4">
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle className="flex items-center gap-2 text-lg md:text-xl">
            <Bell className="w-5 h-5 md:w-6 md:h-6" />
            Uyarı Sistemi
            {unreadAlerts.length > 0 && (
              <Badge variant="destructive" className="ml-2 animate-bounce">
                {unreadAlerts.length} yeni uyarı
              </Badge>
            )}
          </CardTitle>
          <div className="flex items-center gap-2">
            {criticalAlerts.length > 0 && (
              <Badge variant="destructive" className="text-xs">
                {criticalAlerts.length} kritik uyarı
              </Badge>
            )}
            {highPriorityAlerts.length > 0 && (
              <Badge variant="secondary" className="text-xs">
                {highPriorityAlerts.length} yüksek öncelik
              </Badge>
            )}
          </div>
        </div>
      </CardHeader>
      <CardContent>
        <div className="space-y-5 md:space-y-6">
          {alerts.length === 0 ? (
            <Alert>
              <CheckCircle className="h-5 w-5 md:h-6 md:w-6" />
              <AlertTitle>Harika!</AlertTitle>
              <AlertDescription>
                Şu anda herhangi bir uyarı yok. Tüm sistemler sorunsuz çalışıyor.
              </AlertDescription>
            </Alert>
          ) : (
            alerts.map((alert) => (
              <Alert
                key={alert.id}
                className={`transition-all duration-300 rounded-xl border-2 ${getSeverityColor(alert.severity, alert.isRead)} ${!alert.isRead ? 'ring-2 ring-blue-200' : ''} mb-2`}
                style={{ minHeight: 120 }}
              >
                <div className="flex items-start gap-4 w-full">
                  {getAlertIcon(alert.type)}
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <AlertTitle className="text-base md:text-lg font-semibold">
                        {alert.title}
                      </AlertTitle>
                      <Badge 
                        variant="outline" 
                        className={`text-xs px-2 py-1 rounded-full font-bold ${getCategoryColor(alert.category)}`}
                      >
                        <div className="flex items-center gap-1">
                          {getCategoryIcon(alert.category)}
                          {alert.category === 'breeding' && 'üreme'}
                          {alert.category === 'health' && 'sağlık'}
                          {alert.category === 'performance' && 'performans'}
                          {alert.category === 'maintenance' && 'bakım'}
                        </div>
                      </Badge>
                      {alert.severity === 'critical' && (
                        <Badge variant="destructive" className="text-xs">
                          Kritik
                        </Badge>
                      )}
                    </div>
                    <AlertDescription className="text-sm md:text-base">
                      {alert.description}
                    </AlertDescription>
                    {alert.suggestedAction && (
                      <div className="mt-2 p-2 bg-white/70 rounded text-xs md:text-sm border border-yellow-200">
                        <strong>Önerilen eylem:</strong> {alert.suggestedAction}
                      </div>
                    )}
                    <div className="flex items-center justify-between mt-3">
                      <span className="text-xs opacity-70">
                        {formatTimestamp(alert.timestamp)}
                      </span>
                      <div className="flex items-center gap-3">
                        {!alert.isRead && (
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => onMarkAsRead(alert.id)}
                            className="text-xs h-8 px-3"
                            aria-label="Okundu olarak işaretle"
                          >
                            Okundu olarak işaretle
                          </Button>
                        )}
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => onDismiss(alert.id)}
                          className="text-xs h-8 px-3 text-red-600 hover:text-red-700"
                          aria-label="Uyarıyı kapat"
                        >
                          <XCircle className="w-5 h-5" />
                        </Button>
                      </div>
                    </div>
                  </div>
                </div>
              </Alert>
            ))
          )}
        </div>

        {/* Özet İstatistikler */}
        {alerts.length > 0 && (
          <div className="mt-8 p-4 bg-gray-50 rounded-xl shadow-inner grid grid-cols-2 md:grid-cols-4 gap-4 text-center">
            <div>
              <div className="text-lg md:text-xl font-bold">{alerts.length}</div>
              <div className="text-xs text-gray-600">Toplam uyarı</div>
            </div>
            <div>
              <div className="text-lg md:text-xl font-bold text-red-600">{criticalAlerts.length}</div>
              <div className="text-xs text-gray-600">Kritik</div>
            </div>
            <div>
              <div className="text-lg md:text-xl font-bold text-orange-600">
                {alerts.filter(a => a.severity === 'high').length}
              </div>
              <div className="text-xs text-gray-600">Yüksek</div>
            </div>
            <div>
              <div className="text-lg md:text-xl font-bold text-blue-600">{unreadAlerts.length}</div>
              <div className="text-xs text-gray-600">Okunmamış</div>
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
};

export default AlertSystem; 