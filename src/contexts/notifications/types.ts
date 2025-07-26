// Core notification types and interfaces
export interface NotificationAction {
  label: string;
  onClick: () => void;
  primary?: boolean;
}



// Backward compatibility
export interface Notification {
  id: string;
  title: string;
  message: string;
  type: 'egg' | 'chick' | 'breeding' | 'reminder' | 'info' | 'warning' | 'error';
  timestamp: Date;
  read: boolean;
  persistent?: boolean; // For important notifications
  actionUrl?: string; // Navigation target
}

export interface NotificationContextType {
  notifications: Notification[];
  unreadCount: number;
  permissionStatus: NotificationPermission;
  hasPermission: boolean;
  requestPermission: () => Promise<boolean>;
  markAsRead: (notificationId: string) => void;
  deleteNotification: (notificationId: string) => void;
  clearAllNotifications: () => void;
  addNotification: (notification: Omit<Notification, 'id' | 'timestamp' | 'read'>) => void;
  scheduleLocalNotification: (notification: Omit<Notification, 'id' | 'timestamp' | 'read'>, delayMs: number) => void;
  updateNotificationSettings: (enabled: boolean) => void;
  isNotificationsEnabled: boolean;
}

