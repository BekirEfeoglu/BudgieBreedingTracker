export type Language = 'tr' | 'en';

export interface Translations {
  intro: {
    slogan: string;
    tagline: string;
  };
  dashboard: {
    title: string;
    greeting: string;
    totalBirds: string;
    activeBreedings: string;
    totalChicks: string;
    incubatingEggs: string;
    realtimeOverview: string;
    statsAtGlance: string;
    quickActions: string;
  };
  birds: {
    title: string;
    detailedProfiles: string;
    photoGallery: string;
    ringTracking: string;
    smartFiltering: string;
    male: string;
    female: string;
  };
  breeding: {
    title: string;
    incubationTracking: string;
    autoChickCreation: string;
    growthCharts: string;
    milestones: string;
    day: string;
    progress: string;
    eggManagement: string;
    chickTracking: string;
  };
  genetics: {
    title: string;
    punnettSquare: string;
    mutationDatabase: string;
    epistasisEngine: string;
    familyTree: string;
    interactiveTree: string;
    premium: string;
  };
  stats: {
    title: string;
    detailedAnalytics: string;
    autoEvents: string;
    reminderSystem: string;
    breedingSuccess: string;
    genderDistribution: string;
    monthlyTrend: string;
  };
  smart: {
    title: string;
    notifications: string;
    offlineFirst: string;
    cloudSync: string;
    multiLanguage: string;
    exportBackup: string;
    turnEggsReminder: string;
    incubationDay: string;
    worksOffline: string;
    pdfExcel: string;
  };
  premium: {
    title: string;
    unlockAll: string;
    geneticsCalc: string;
    familyTree: string;
    advancedStats: string;
    unlimitedBirds: string;
    prioritySupport: string;
    noAds: string;
    monthly: string;
    yearly: string;
    downloadNow: string;
    startFreeTrial: string;
  };
  common: {
    appName: string;
  };
}
