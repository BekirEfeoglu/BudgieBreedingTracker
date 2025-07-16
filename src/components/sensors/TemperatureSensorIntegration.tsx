import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { 
  Thermometer, 
  Droplets, 
  Wifi, 
  WifiOff, 
  AlertTriangle, 
  CheckCircle,
  Activity,
  Settings
} from 'lucide-react';
import { NotificationScheduler } from '@/services/notification/NotificationScheduler';
import { useToast } from '@/hooks/use-toast';

interface SensorData {
  temperature: number;
  humidity: number;
  timestamp: Date;
  connected: boolean;
}

const TemperatureSensorIntegration = () => {
  const [sensorData, setSensorData] = useState<SensorData | null>(null);
  const [isConnected, setIsConnected] = useState(false);
  const [autoAlerts, setAutoAlerts] = useState(true);
  const [sensorUrl, setSensorUrl] = useState('ws://192.168.1.100:8080');
  const [connection, setConnection] = useState<WebSocket | null>(null);
  const { toast } = useToast();

  const scheduler = NotificationScheduler.getInstance();

  const connectToSensor = () => {
    try {
      const ws = new WebSocket(sensorUrl);
      
      ws.onopen = () => {
        setIsConnected(true);
        setConnection(ws);
        toast({
          title: 'Bağlantı Başarılı',
          description: 'Sıcaklık sensörüne bağlanıldı.',
        });
      };

      ws.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data);
          const newSensorData: SensorData = {
            temperature: data.temperature,
            humidity: data.humidity,
            timestamp: new Date(),
            connected: true
          };
          
          setSensorData(newSensorData);
          
          // Otomatik uyarı kontrolü
          if (autoAlerts) {
            checkTemperatureAlerts(data.temperature);
          }
        } catch (error) {
          console.error('Sensor data parse error:', error);
        }
      };

      ws.onclose = () => {
        setIsConnected(false);
        setConnection(null);
        toast({
          title: 'Bağlantı Kesildi',
          description: 'Sıcaklık sensörü bağlantısı kesildi.',
          variant: 'destructive'
        });
      };

      ws.onerror = (error) => {
        console.error('WebSocket error:', error);
        toast({
          title: 'Bağlantı Hatası',
          description: 'Sensöre bağlanılamadı.',
          variant: 'destructive'
        });
      };

    } catch (error) {
      console.error('Connection error:', error);
      toast({
        title: 'Hata',
        description: 'Geçersiz WebSocket URL.',
        variant: 'destructive'
      });
    }
  };

  const disconnectFromSensor = () => {
    if (connection) {
      connection.close();
      setConnection(null);
      setIsConnected(false);
    }
  };

  const checkTemperatureAlerts = async (temperature: number) => {
    const settings = scheduler.getSettings();
    if (settings?.temperatureAlertsEnabled) {
      await scheduler.sendTemperatureAlert(
        temperature,
        settings.temperatureMin,
        settings.temperatureMax
      );
    }
  };

  // Bağlantı kesilme kontrolü
  useEffect(() => {
    const interval = setInterval(() => {
      if (sensorData && isConnected) {
        const timeDiff = Date.now() - sensorData.timestamp.getTime();
        if (timeDiff > 30000) { // 30 saniye
          setSensorData(prev => prev ? { ...prev, connected: false } : null);
        }
      }
    }, 5000);

    return () => clearInterval(interval);
  }, [sensorData, isConnected]);

  return (
    <div className="space-y-6">
      {/* Bağlantı Ayarları */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Settings className="h-5 w-5" />
            Sensör Bağlantısı
          </CardTitle>
          <CardDescription>
            Sıcaklık ve nem sensörünüzü WebSocket üzerinden bağlayın
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-2">
            <Label>WebSocket URL</Label>
            <Input
              value={sensorUrl}
              onChange={(e) => setSensorUrl(e.target.value)}
              placeholder="ws://192.168.1.100:8080"
              disabled={isConnected}
            />
          </div>

          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span>Durum:</span>
              <Badge variant={isConnected ? 'default' : 'destructive'} className="flex items-center gap-1">
                {isConnected ? <Wifi className="h-3 w-3" /> : <WifiOff className="h-3 w-3" />}
                {isConnected ? 'Bağlı' : 'Bağlı Değil'}
              </Badge>
            </div>
            
            <Button
              onClick={isConnected ? disconnectFromSensor : connectToSensor}
              variant={isConnected ? 'destructive' : 'default'}
            >
              {isConnected ? 'Bağlantıyı Kes' : 'Bağlan'}
            </Button>
          </div>

          <div className="flex items-center justify-between">
            <div className="space-y-0.5">
              <Label>Otomatik Uyarılar</Label>
              <p className="text-sm text-muted-foreground">Sıcaklık eşik değer aşımında bildirim</p>
            </div>
            <Switch
              checked={autoAlerts}
              onCheckedChange={setAutoAlerts}
            />
          </div>
        </CardContent>
      </Card>

      {/* Gerçek Zamanlı Veriler */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Activity className="h-5 w-5" />
            Gerçek Zamanlı Veriler
          </CardTitle>
        </CardHeader>
        <CardContent>
          {!sensorData ? (
            <Alert>
              <AlertTriangle className="h-4 w-4" />
              <AlertDescription>
                Sensör verisi alınmıyor. Bağlantıyı kontrol edin.
              </AlertDescription>
            </Alert>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* Sıcaklık */}
              <div className="space-y-2">
                <div className="flex items-center gap-2">
                  <Thermometer className="h-5 w-5 text-red-500" />
                  <span className="font-medium">Sıcaklık</span>
                  {sensorData.connected ? (
                    <CheckCircle className="h-4 w-4 text-green-500" />
                  ) : (
                    <AlertTriangle className="h-4 w-4 text-orange-500" />
                  )}
                </div>
                <div className="text-3xl font-bold text-red-600">
                  {sensorData.temperature.toFixed(1)}°C
                </div>
                <p className="text-sm text-muted-foreground">
                  Son güncelleme: {sensorData.timestamp.toLocaleTimeString('tr-TR')}
                </p>
              </div>

              {/* Nem */}
              <div className="space-y-2">
                <div className="flex items-center gap-2">
                  <Droplets className="h-5 w-5 text-blue-500" />
                  <span className="font-medium">Nem</span>
                  {sensorData.connected ? (
                    <CheckCircle className="h-4 w-4 text-green-500" />
                  ) : (
                    <AlertTriangle className="h-4 w-4 text-orange-500" />
                  )}
                </div>
                <div className="text-3xl font-bold text-blue-600">
                  {sensorData.humidity.toFixed(1)}%
                </div>
                <p className="text-sm text-muted-foreground">
                  Son güncelleme: {sensorData.timestamp.toLocaleTimeString('tr-TR')}
                </p>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Kurulum Talimatları */}
      <Card>
        <CardHeader>
          <CardTitle>📋 Sensör Kurulum Talimatları</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="bg-muted p-4 rounded-lg">
            <h4 className="font-medium mb-2">Arduino/ESP32 Örnek Kod:</h4>
            <pre className="text-sm overflow-x-auto">
{`#include <WebSocketsServer.h>
#include <DHT.h>

DHT dht(2, DHT22);
WebSocketsServer webSocket = WebSocketsServer(8080);

void setup() {
  Serial.begin(115200);
  dht.begin();
  
  // WiFi bağlantısı...
  webSocket.begin();
}

void loop() {
  webSocket.loop();
  
  float temp = dht.readTemperature();
  float hum = dht.readHumidity();
  
  String data = "{\\"temperature\\":" + String(temp) + 
                ",\\"humidity\\":" + String(hum) + "}";
  
  webSocket.broadcastTXT(data);
  delay(5000);
}`}
            </pre>
          </div>

          <Alert>
            <AlertTriangle className="h-4 w-4" />
            <AlertDescription>
              <strong>Not:</strong> Sensörünüzün IP adresini ve portunu doğru girdiğinizden emin olun. 
              Hem cihazınız hem de sensör aynı WiFi ağında olmalıdır.
            </AlertDescription>
          </Alert>
        </CardContent>
      </Card>
    </div>
  );
};

export default TemperatureSensorIntegration;