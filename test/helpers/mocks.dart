import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/birds_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/clutches_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/conflict_history_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/eggs_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/genetics_history_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/incubations_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/data/remote/storage/storage_service.dart';
import 'package:budgie_breeding_tracker/data/repositories/bird_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/breeding_pair_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/chick_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/clutch_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/egg_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/event_reminder_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/event_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/growth_measurement_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/health_record_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/incubation_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/nest_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/notification_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/notification_schedule_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/photo_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/profile_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/community_post_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/sync_metadata_repository.dart';
import 'package:budgie_breeding_tracker/domain/services/ads/ad_service.dart';
import 'package:budgie_breeding_tracker/domain/services/auth/two_factor_service.dart';
import 'package:budgie_breeding_tracker/domain/services/backup/backup_service.dart';
import 'package:budgie_breeding_tracker/domain/services/encryption/encryption_service.dart';
import 'package:budgie_breeding_tracker/domain/services/calendar/calendar_event_generator.dart';
import 'package:budgie_breeding_tracker/domain/services/export/excel_export_service.dart';
import 'package:budgie_breeding_tracker/domain/services/export/pdf_export_service.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/import/data_import_service.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_processor.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_scheduler.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_service.dart';
import 'package:budgie_breeding_tracker/domain/services/payment/purchase_service.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_orchestrator.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';

// ── Repositories ──

class MockBirdRepository extends Mock implements BirdRepository {}

class MockBreedingPairRepository extends Mock
    implements BreedingPairRepository {}

class MockEggRepository extends Mock implements EggRepository {}

class MockChickRepository extends Mock implements ChickRepository {}

class MockClutchRepository extends Mock implements ClutchRepository {}

class MockHealthRecordRepository extends Mock
    implements HealthRecordRepository {}

class MockEventRepository extends Mock implements EventRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockIncubationRepository extends Mock implements IncubationRepository {}

class MockNestRepository extends Mock implements NestRepository {}

class MockPhotoRepository extends Mock implements PhotoRepository {}

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

class MockNotificationScheduleRepository extends Mock
    implements NotificationScheduleRepository {}

class MockEventReminderRepository extends Mock
    implements EventReminderRepository {}

class MockGrowthMeasurementRepository extends Mock
    implements GrowthMeasurementRepository {}

class MockCommunityPostRepository extends Mock
    implements CommunityPostRepository {}

class MockSyncMetadataRepository extends Mock
    implements SyncMetadataRepository {}

// ── DAOs ──

class MockSyncMetadataDao extends Mock implements SyncMetadataDao {}

class MockGeneticsHistoryDao extends Mock implements GeneticsHistoryDao {}

class MockEggsDao extends Mock implements EggsDao {}

class MockClutchesDao extends Mock implements ClutchesDao {}

class MockIncubationsDao extends Mock implements IncubationsDao {}

class MockBirdsDao extends Mock implements BirdsDao {}

class MockConflictHistoryDao extends Mock implements ConflictHistoryDao {}

// ── Services ──

class MockAuthActions extends Mock implements AuthActions {}

class MockTwoFactorService extends Mock implements TwoFactorService {}

class MockAdService extends Mock implements AdService {
  @override
  Future<void> ensureSdkInitialized() async {}
}

class MockSyncOrchestrator extends Mock implements SyncOrchestrator {}

class MockNotificationService extends Mock implements NotificationService {}

class MockNotificationScheduler extends Mock implements NotificationScheduler {}

class MockNotificationProcessor extends Mock implements NotificationProcessor {}

class MockPurchaseService extends Mock implements PurchaseService {}

class MockPdfExportService extends Mock implements PdfExportService {}

class MockExcelExportService extends Mock implements ExcelExportService {}

class MockMendelianCalculator extends Mock implements MendelianCalculator {}

class MockBackupService extends Mock implements BackupService {}

class MockEncryptionService extends Mock implements EncryptionService {}

class MockCalendarEventGenerator extends Mock
    implements CalendarEventGenerator {}

class MockDataImportService extends Mock implements DataImportService {}

class MockStorageService extends Mock implements StorageService {}

// ── External ──

typedef ConnectivityPlus = Connectivity;

class MockConnectivity extends Mock implements ConnectivityPlus {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class MockFunctionsClient extends Mock implements FunctionsClient {}

class MockAppDatabase extends Mock implements AppDatabase {}
