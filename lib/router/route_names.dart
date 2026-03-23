abstract class AppRoutes {
  // App initialization
  static const splash = '/splash';

  // Public
  static const login = '/login';
  static const register = '/register';
  static const authCallback = '/auth/callback';
  static const oauthCallback = '/login-callback';
  static const emailVerification = '/email-verification';
  static const forgotPassword = '/forgot-password';

  // Main (Bottom Nav Shell)
  static const home = '/';
  static const birds = '/birds';
  static const birdDetail = '/birds/:id';
  static const birdForm = '/birds/form';
  static const breeding = '/breeding';
  static const breedingDetail = '/breeding/:id';
  static const breedingForm = '/breeding/form';
  static const breedingEggs = '/breeding/:id/eggs';
  static const chicks = '/chicks';
  static const chickDetail = '/chicks/:id';
  static const chickForm = '/chicks/form';
  static const calendar = '/calendar';

  // Community
  static const community = '/community';
  static const communityPostDetail = '/community/post/:postId';
  static const communityCreatePost = '/community/create';
  static const communityUserPosts = '/community/user/:userId';
  static const communityBookmarks = '/community/bookmarks';
  static const communitySearch = '/community/search';

  // Health Records
  static const healthRecords = '/health-records';
  static const healthRecordDetail = '/health-records/:id';
  static const healthRecordForm = '/health-records/form';

  // Premium-gated
  static const statistics = '/statistics';
  static const genealogy = '/genealogy';
  static const genetics = '/genetics';
  static const geneticsHistory = '/genetics/history';
  static const geneticsCompare = '/genetics/compare';
  static const geneticsReverse = '/genetics/reverse';
  static const geneticsColorAudit = '/dev/genetics-color-audit';

  // User
  static const profile = '/profile';
  static const settings = '/settings';
  static const more = '/more';
  static const premium = '/premium';
  static const userGuide = '/user-guide';
  static const userGuideDetail = '/user-guide/:topicIndex';
  static const notifications = '/notifications';
  static const notificationSettings = '/notification-settings';
  static const backup = '/backup';
  static const feedback = '/feedback';
  static const privacyPolicy = '/privacy-policy';
  static const termsOfService = '/terms-of-service';
  static const communityGuidelines = '/community-guidelines';
  static const twoFactorSetup = '/2fa-setup';
  static const twoFactorVerify = '/2fa-verify';

  // Admin
  static const admin = '/admin';
  static const adminDashboard = '/admin/dashboard';
  static const adminUsers = '/admin/users';
  static const adminUserDetail = '/admin/users/:userId';
  static const adminMonitoring = '/admin/monitoring';
  static const adminDatabase = '/admin/database';
  static const adminAudit = '/admin/audit';
  static const adminSecurity = '/admin/security';
  static const adminSettings = '/admin/settings';
  static const adminFeedback = '/admin/feedback';
}
