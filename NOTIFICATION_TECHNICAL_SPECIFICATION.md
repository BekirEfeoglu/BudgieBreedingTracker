# Muhabbet Kuşu Kuluçka Takip Uygulaması - Bildirimler Teknik Spesifikasyonu

## 📱 Genel Mimari

### Platform Desteği
- **Android**: API Level 23+ (Android 6.0+)
- **iOS**: iOS 12.0+
- **Framework**: Capacitor 6.x + React + TypeScript
- **Backend**: Supabase (PostgreSQL + Edge Functions)

### Bildirim Türleri
1. **Local Notifications**: Cihazda çalışan zamanlanmış bildirimler
2. **Push Notifications**: Server-side tetiklenen anlık bildirimler
3. **Background Tasks**: Arka planda çalışan monitöring sistemleri

---

## 🥚 1. Yumurta Çevirme Hatırlatmaları

### Teknik Gereksinimler
```typescript
interface EggTurningConfig {
  incubationId: string;
  startDate: Date;
  interval: number; // dakika (varsayılan: 240 = 4 saat)
  endDate: Date; // otomatik hesaplanan (18 gün)
  isManualOverride: boolean;
  customSchedule?: Date[]; // manuel zamanlama
}
```

### Implementasyon Detayları
- **Zamanlama Motoru**: Capacitor Local Notifications
- **Periyot Hesaplama**: JavaScript Date arithmetic
- **Persistence**: SQLite (local) + Supabase (sync)
- **Tolerans**: ±15 dakika (pil optimizasyonu için)

### Bildirim Akışı
1. Kuluçka başladığında otomatik schedule
2. Her çevirme zamanında local notification
3. Kullanıcı "Tamamlandı" butonuna basana kadar tekrarlı bildirim (5dk aralık)
4. Completion tracking ve istatistik toplama

```sql
-- Veritabanı Şeması
CREATE TABLE egg_turning_logs (
  id UUID PRIMARY KEY,
  incubation_id UUID REFERENCES incubations(id),
  scheduled_at TIMESTAMP,
  completed_at TIMESTAMP,
  is_manual_completion BOOLEAN DEFAULT FALSE,
  user_id UUID REFERENCES auth.users(id)
);
```

---

## 🌡️ 2. Sıcaklık ve Nem Uyarıları

### Sensör Entegrasyon Mimarisi
```typescript
interface SensorConfig {
  bluetoothDeviceId?: string;
  wifiEndpoint?: string;
  pollingInterval: number; // saniye
  alertThresholds: {
    temperature: { min: number; max: number; tolerance: number };
    humidity: { min: number; max: number; tolerance: number };
  };
}
```

### Real-time Monitoring
- **Bluetooth**: Capacitor Bluetooth LE plugin
- **Wi-Fi**: HTTP polling veya WebSocket bağlantısı
- **Fallback**: Manuel giriş arayüzü
- **Edge Function**: Supabase ile kritik uyarı gönderimi

### Alert Logic
```typescript
class EnvironmentMonitor {
  async checkThresholds(reading: SensorReading) {
    const { temperature, humidity } = reading;
    const config = await this.getUserConfig();
    
    // Tolerance band kontrolü
    const tempAlert = this.isOutOfTolerance(
      temperature, 
      config.temperature.min, 
      config.temperature.max, 
      config.temperature.tolerance
    );
    
    if (tempAlert && !this.isInCooldown('temperature')) {
      await this.sendCriticalAlert('temperature', reading);
      this.setCooldown('temperature', 300); // 5 dakika cooldown
    }
  }
}
```

### Progressive Alert System
1. **İlk uyarı**: Anında bildirim
2. **Devam eden problem**: 15 dakika sonra tekrar
3. **Kritik seviye**: 1 dakika aralıklarla
4. **Çözüldü**: "Normal seviyeye döndü" bildirimi

---

## 📅 3. Kuluçka ve Kuluçka Sonu Bildirimleri

### Milestone Tracking
```typescript
interface IncubationMilestone {
  day: number;
  title: string;
  description: string;
  actionRequired: boolean;
  notificationTime: 'morning' | 'evening' | 'custom';
}

const INCUBATION_MILESTONES: IncubationMilestone[] = [
  { day: 1, title: "Kuluçka Başladı", description: "İlk gün kontrolü", actionRequired: true, notificationTime: 'morning' },
  { day: 7, title: "1. Hafta Tamamlandı", description: "Candling zamanı", actionRequired: true, notificationTime: 'evening' },
  { day: 14, title: "2. Hafta Tamamlandı", description: "Son candling", actionRequired: true, notificationTime: 'evening' },
  { day: 17, title: "Çevirmeyi Durdurun", description: "Artık yumurta çevirmeyin", actionRequired: true, notificationTime: 'morning' },
  { day: 18, title: "Çıkış Günü!", description: "Yavrular çıkmaya başlayabilir", actionRequired: false, notificationTime: 'morning' },
  { day: 21, title: "Geç Çıkış Kontrolü", description: "Hala çıkmayan yumurtalar için kontrol", actionRequired: true, notificationTime: 'morning' }
];
```

### Smart Timing
- **Kullanıcı timezone**: Otomatik detection
- **Optimal hours**: Makine öğrenmesi ile belirlenen en uygun saatler
- **Do Not Disturb**: Kullanıcı tanımlı sessiz saatler

---

## 🐤 4. Yavru Bakım Planı Hatırlatmaları

### Dinamik Bakım Takvimi
```typescript
interface ChickCareSchedule {
  chickId: string;
  hatchDate: Date;
  ageInDays: number;
  carePhase: 'newborn' | 'juvenile' | 'adolescent';
  tasks: CareTask[];
}

interface CareTask {
  type: 'feeding' | 'water_check' | 'temperature_check' | 'cleaning' | 'health_check';
  frequency: number; // saat
  duration: number; // kaç gün devam edecek
  priority: 'low' | 'medium' | 'high' | 'critical';
  instructions: string;
}
```

### Yaş Tabanlı Bakım Planları
```typescript
const CARE_SCHEDULES = {
  newborn: { // 0-7 gün
    feeding: { frequency: 2, duration: 7, priority: 'critical' },
    water_check: { frequency: 4, duration: 7, priority: 'high' },
    temperature_check: { frequency: 6, duration: 7, priority: 'high' }
  },
  juvenile: { // 8-30 gün  
    feeding: { frequency: 4, duration: 23, priority: 'high' },
    cleaning: { frequency: 24, duration: 23, priority: 'medium' },
    health_check: { frequency: 168, duration: 23, priority: 'medium' } // haftalık
  }
};
```

### Takvim Senkronizasyonu
- **Native Calendar**: iOS Calendar / Android Calendar entegrasyonu
- **Google Calendar**: API entegrasyonu
- **Export/Import**: ICS format desteği

---

## ☁️ 5. Bulut Senkronizasyon ve Cihazlar Arası Uyarılar

### Multi-Device Architecture
```sql
-- FCM Token Management
CREATE TABLE user_notification_tokens (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  token TEXT UNIQUE,
  platform TEXT CHECK (platform IN ('ios', 'android', 'web')),
  device_info JSONB,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Cross-Device Sync
CREATE TABLE notification_sync_queue (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  notification_type TEXT,
  payload JSONB,
  target_devices TEXT[], -- specific device targeting
  sent_at TIMESTAMP,
  failed_devices TEXT[]
);
```

### Conflict Resolution
```typescript
interface SyncConflict {
  conflictType: 'notification_setting' | 'schedule_overlap' | 'device_timezone';
  localValue: any;
  serverValue: any;
  resolutionStrategy: 'prefer_local' | 'prefer_server' | 'user_choice' | 'merge';
}

class ConflictResolver {
  async resolveNotificationConflicts(conflicts: SyncConflict[]): Promise<ResolvedConflict[]> {
    return conflicts.map(conflict => {
      switch (conflict.conflictType) {
        case 'notification_setting':
          return { ...conflict, resolution: this.resolveSettingConflict(conflict) };
        case 'schedule_overlap':
          return { ...conflict, resolution: this.mergeSchedules(conflict) };
        default:
          return { ...conflict, resolution: conflict.serverValue }; // Server wins by default
      }
    });
  }
}
```

---

## 🤖 6. Manuel ve Akıllı Bildirim Modları

### AI-Powered Optimization
```typescript
interface UserBehaviorAnalytics {
  userId: string;
  optimalNotificationHours: number[]; // 0-23
  responseRate: number; // 0-1
  preferredNotificationTypes: string[];
  avgResponseTime: number; // seconds
  deviceUsagePatterns: {
    morning: number; // 0-1 activity score
    afternoon: number;
    evening: number;
    night: number;
  };
}

class IntelligentScheduler {
  async optimizeSchedule(userId: string): Promise<OptimizedSchedule> {
    const analytics = await this.getUserAnalytics(userId);
    const mlModel = await this.loadPersonalizationModel();
    
    return mlModel.predict({
      userBehavior: analytics,
      historicalData: await this.getHistoricalInteractions(userId),
      contextualFactors: await this.getContextualFactors()
    });
  }
}
```

### Adaptive Do Not Disturb
```typescript
interface SmartDNDConfig {
  learningEnabled: boolean;
  autoDetectSleepPattern: boolean;
  emergencyOverride: boolean; // Kritik uyarılar için
  contextAwareness: {
    calendarIntegration: boolean;
    locationBased: boolean; // Ev/iş lokasyonu
    activityDetection: boolean; // Hareket sensörü
  };
}
```

---

## 📊 7. Bildirim Geçmişi ve Yönetimi

### Notification Management System
```typescript
interface NotificationHistoryEntry {
  id: string;
  userId: string;
  type: NotificationType;
  title: string;
  body: string;
  sentAt: Date;
  deliveredAt?: Date;
  readAt?: Date;
  actionTaken?: string;
  effectiveness: number; // ML-calculated score
  metadata: {
    incubationId?: string;
    chickId?: string;
    sensorReading?: SensorReading;
    userLocation?: string;
  };
}
```

### Advanced Filtering & Search
```typescript
interface NotificationFilter {
  dateRange: { start: Date; end: Date };
  types: NotificationType[];
  readStatus: 'all' | 'read' | 'unread';
  priority: 'all' | 'low' | 'normal' | 'high' | 'critical';
  relatedEntity?: { type: 'incubation' | 'chick'; id: string };
  textSearch?: string;
}

class NotificationManager {
  async exportHistory(userId: string, format: 'csv' | 'pdf' | 'json'): Promise<Blob> {
    const history = await this.getFilteredHistory(userId, {});
    
    switch (format) {
      case 'csv':
        return this.generateCSV(history);
      case 'pdf':
        return this.generatePDFReport(history);
      case 'json':
        return this.generateJSON(history);
    }
  }
}
```

---

## 🌍 8. Çoklu Dil ve Lokalizasyon

### Internationalization Strategy
```typescript
interface LocalizedNotification {
  key: string;
  translations: {
    [locale: string]: {
      title: string;
      body: string;
      actionLabels?: string[];
    };
  };
  placeholders?: string[]; // Dynamic content insertion
}

const NOTIFICATION_TEMPLATES: LocalizedNotification[] = [
  {
    key: 'egg_turning_reminder',
    translations: {
      'tr-TR': {
        title: 'Yumurta Çevirme Zamanı! 🥚',
        body: 'Kuluçka makinesindeki yumurtaları çevirme zamanı geldi.',
        actionLabels: ['Tamamlandı', 'Ertele (15dk)', 'İptal']
      },
      'en-US': {
        title: 'Time to Turn Eggs! 🥚',
        body: 'It\'s time to turn the eggs in the incubator.',
        actionLabels: ['Completed', 'Snooze (15min)', 'Cancel']
      }
    },
    placeholders: ['incubationName', 'eggCount']
  }
];
```

### Regional Preferences
```typescript
interface RegionalConfig {
  locale: string;
  timezone: string;
  dateFormat: 'DD/MM/YYYY' | 'MM/DD/YYYY' | 'YYYY-MM-DD';
  timeFormat: '12h' | '24h';
  temperatureUnit: 'celsius' | 'fahrenheit';
  firstDayOfWeek: 'monday' | 'sunday';
  culturalConsiderations: {
    quietHours: { start: string; end: string };
    weekendBehavior: 'same' | 'reduced' | 'off';
    religiousObservances?: string[]; // Automatically adjust for prayer times, etc.
  };
}
```

---

## 🔒 9. İzin ve Gizlilik

### Progressive Permission Strategy
```typescript
class PermissionManager {
  async requestPermissionsProgressively(): Promise<PermissionStatus> {
    // 1. Temel Local Notifications
    const localPerms = await this.requestLocalNotifications();
    
    // 2. Push Notifications (kullanıcı değer gördükten sonra)
    if (localPerms.granted && this.shouldRequestPush()) {
      const pushPerms = await this.requestPushNotifications();
    }
    
    // 3. Location (IoT sensor features için)
    if (this.featureRequiresLocation()) {
      const locationPerms = await this.requestLocation();
    }
    
    // 4. Calendar (sync özelliği için)
    if (this.userWantsCalendarSync()) {
      const calendarPerms = await this.requestCalendar();
    }
    
    return this.aggregatePermissionStatus();
  }
}
```

### Privacy-First Architecture
```sql
-- User Consent Tracking
CREATE TABLE user_privacy_consents (
  user_id UUID REFERENCES auth.users(id),
  consent_type TEXT, -- 'notifications', 'analytics', 'location', etc.
  granted_at TIMESTAMP,
  revoked_at TIMESTAMP,
  consent_version TEXT,
  explicit_consent BOOLEAN DEFAULT TRUE
);

-- Data Minimization
CREATE TABLE notification_analytics (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  event_type TEXT,
  timestamp TIMESTAMP,
  -- Sadece istatistik için gerekli minimum data
  aggregated_data JSONB, -- No PII
  retention_until TIMESTAMP -- Automatic cleanup
);
```

### GDPR/KVKK Compliance
- **Data Portability**: Tüm bildirim verilerini export
- **Right to be Forgotten**: Cascade delete mekanizması
- **Consent Management**: Granular permission controls
- **Data Minimization**: Sadece gerekli datayı toplama

---

## 🧪 10. Test ve Hata Ayıklama

### Testing Framework
```typescript
interface NotificationTestSuite {
  unitTests: {
    schedulingLogic: TestCase[];
    localizationEngine: TestCase[];
    permissionHandling: TestCase[];
  };
  integrationTests: {
    pushNotificationDelivery: TestCase[];
    crossDeviceSync: TestCase[];
    backgroundTaskExecution: TestCase[];
  };
  e2eTests: {
    fullUserJourney: TestCase[];
    errorRecoveryScenarios: TestCase[];
  };
}

class NotificationTester {
  async runTestNotification(type: NotificationType, targetTime: Date): Promise<TestResult> {
    const testId = `test_${type}_${Date.now()}`;
    
    // Özel test notification gönder
    await LocalNotifications.schedule({
      notifications: [{
        id: testId,
        title: `[TEST] ${type}`,
        body: `Test bildirimi - ${new Date().toLocaleString()}`,
        schedule: { at: targetTime },
        extra: { isTest: true, testId }
      }]
    });
    
    return this.trackTestDelivery(testId);
  }
}
```

### Error Reporting & Analytics
```typescript
interface NotificationError {
  errorType: 'permission_denied' | 'delivery_failed' | 'schedule_conflict' | 'sync_error';
  errorCode: string;
  userAgent: string;
  deviceInfo: {
    platform: string;
    version: string;
    model?: string;
  };
  stackTrace?: string;
  userImpact: 'low' | 'medium' | 'high' | 'critical';
  contextData: any;
}

class ErrorReporter {
  async reportNotificationError(error: NotificationError): Promise<void> {
    // Supabase Edge Function'a error gönder
    await supabase.functions.invoke('report-notification-error', {
      body: {
        ...error,
        timestamp: new Date().toISOString(),
        userId: await this.getCurrentUserId(),
        sessionId: this.getSessionId()
      }
    });
    
    // Local fallback logging
    await this.logErrorLocally(error);
  }
}
```

### Performance Monitoring
```typescript
interface NotificationMetrics {
  deliveryLatency: number; // ms
  batteryImpact: number; // estimated mAh
  memoryUsage: number; // bytes
  cpuUsage: number; // percentage
  networkRequests: number;
  userEngagement: {
    openRate: number;
    actionRate: number;
    dismissRate: number;
  };
}

class PerformanceMonitor {
  async collectMetrics(): Promise<NotificationMetrics> {
    return {
      deliveryLatency: await this.measureDeliveryLatency(),
      batteryImpact: await this.estimateBatteryUsage(),
      memoryUsage: await this.getCurrentMemoryUsage(),
      cpuUsage: await this.getCPUUsage(),
      networkRequests: this.getNetworkRequestCount(),
      userEngagement: await this.calculateEngagementMetrics()
    };
  }
}
```

---

## 🚀 Deployment & Infrastructure

### CI/CD Pipeline
```yaml
# .github/workflows/mobile-notifications.yml
name: Mobile Notifications Testing

on:
  push:
    paths:
      - 'src/services/notification/**'
      - 'capacitor.config.ts'

jobs:
  test-notifications:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run notification unit tests
        run: npm run test:notifications
      
      - name: Build iOS
        run: |
          npx cap build ios
          npx cap run ios --target="iPhone 14 Simulator"
      
      - name: Test notification delivery
        run: npm run test:e2e:notifications
```

### Monitoring & Alerting
```typescript
// Supabase Edge Function: notification-monitor
export default async function handler(req: Request) {
  const metrics = await collectSystemMetrics();
  
  // Critical thresholds
  if (metrics.failureRate > 0.05) { // 5% failure rate
    await sendAdminAlert('High notification failure rate detected');
  }
  
  if (metrics.avgDeliveryLatency > 5000) { // 5 second delay
    await sendAdminAlert('Notification delivery degraded');
  }
  
  // Store metrics for dashboard
  await supabase
    .from('notification_system_metrics')
    .insert({
      timestamp: new Date().toISOString(),
      ...metrics
    });
}
```

---

## 📋 Implementation Checklist

### Phase 1: Core Infrastructure (2 hafta)
- [ ] Capacitor kurulumu ve konfigürasyonu
- [ ] Local Notifications temel implementasyonu
- [ ] Push Notifications FCM entegrasyonu
- [ ] Temel permission handling
- [ ] Veritabanı şeması oluşturma

### Phase 2: Smart Scheduling (2 hafta)
- [ ] NotificationScheduler class implementasyonu
- [ ] Yumurta çevirme hatırlatmaları
- [ ] Kuluçka milestone bildirimleri
- [ ] Do Not Disturb sistemi
- [ ] Temel lokalizasyon

### Phase 3: Advanced Features (3 hafta)
- [ ] IoT sensor entegrasyonu (Bluetooth/Wi-Fi)
- [ ] Sıcaklık/nem uyarı sistemi
- [ ] Cross-device sync
- [ ] AI-powered optimization
- [ ] Advanced analytics

### Phase 4: UX & Polish (2 hafta)
- [ ] Bildirim yönetim arayüzü
- [ ] Export/import features
- [ ] Comprehensive testing
- [ ] Performance optimization
- [ ] Accessibility improvements

### Phase 5: Production Ready (1 hafta)
- [ ] Security audit
- [ ] Privacy compliance check
- [ ] App store submission preparation
- [ ] Production monitoring setup
- [ ] Documentation ve user guide

---

Bu spesifikasyon, endüstri standartlarında profesyonel bir bildirim sistemi için gereken tüm teknik detayları içermektedir. Implementasyon sırasında her fazın tamamlanması sonrası kullanıcı testleri ve feedback toplanması önerilir.