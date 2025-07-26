import { NotificationSchedule } from './types';

export const getIncubationMilestones = () => [
  { day: 7, title: '1. Hafta Tamamlandı! 📅', body: 'Kuluçka sürecinin ilk haftası başarıyla geçti.' },
  { day: 14, title: '2. Hafta Tamamlandı! 📅', body: 'Kuluçka sürecinin ikinci haftası tamamlandı.' },
  { day: 17, title: 'Çıkış Yaklaşıyor! 🐣', body: 'Yavrular 1-2 gün içinde çıkabilir. Hazır olun!' },
  { day: 18, title: 'Çıkış Zamanı! 🎉', body: 'Beklenen çıkış günü! Yavruları kontrol edin.' }
];

export const getChickCareSchedule = () => [
  // İlk 24 saat - her 2 saatte kontrol
  ...Array.from({ length: 12 }, (_, i) => ({
    hours: i * 2,
    title: 'Yavru Kontrolü 🐤',
    body: 'Yeni çıkan yavruyu kontrol edin. Su ve yem erişimini kontrol edin.',
    priority: 'high' as const
  })),
  // 1. hafta - günde 3 kez
  ...Array.from({ length: 21 }, (_, i) => ({
    hours: 24 + (i * 8),
    title: 'Besleme Zamanı 🍽️',
    body: 'Yavru besleme zamanı. Temiz su ve taze yemi kontrol edin.',
    priority: 'normal' as const
  }))
];

export const getDefaultSchedule = (): NotificationSchedule[] => {
  return [
    {
      id: 'default_morning',
      type: 'feeding_schedule',
      title: 'Sabah Besleme',
      body: 'Günaydın! Kuşlarınızı besleme zamanı.',
      scheduledAt: new Date(Date.now() + (8 * 60 * 60 * 1000)), // 08:00
      isRecurring: true,
      intervalMinutes: 24 * 60,
      priority: 'normal'
    },
    {
      id: 'default_evening',
      type: 'feeding_schedule',
      title: 'Akşam Besleme',
      body: 'Akşam besleme zamanı geldi.',
      scheduledAt: new Date(Date.now() + (18 * 60 * 60 * 1000)), // 18:00
      isRecurring: true,
      intervalMinutes: 24 * 60,
      priority: 'normal'
    }
  ];
};

export const analyzeHourlyActivity = (history: any[]): number[] => {
  const hourlyCount = new Array(24).fill(0);
  
  history.forEach(interaction => {
    const hour = new Date(interaction.created_at).getHours();
    hourlyCount[hour]++;
  });

  return hourlyCount;
};

export const findOptimalNotificationHours = (hourlyActivity: number[]): number[] => {
  // En aktif 3 saati bul
  return hourlyActivity
    .map((count, hour) => ({ hour, count }))
    .sort((a, b) => b.count - a.count)
    .slice(0, 3)
    .map(item => item.hour);
};

export const generateSmartSchedule = (optimalHours: number[]): NotificationSchedule[] => {
  // Optimal saatlere göre akıllı zamanlama oluştur
  return optimalHours.map((hour, index) => ({
    id: `smart_${hour}_${index}`,
    type: 'feeding_schedule' as const,
    title: 'Besleme Zamanı',
    body: 'Kuşlarınızı besleme zamanı geldi.',
    scheduledAt: new Date(Date.now() + (hour * 60 * 60 * 1000)),
    isRecurring: true,
    intervalMinutes: 24 * 60, // Günlük
    priority: 'normal' as const
  }));
};