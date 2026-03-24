import 'package:budgie_breeding_tracker/data/repositories/bird_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/breeding_pair_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/chick_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/clutch_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/egg_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/event_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/growth_measurement_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/health_record_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/incubation_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/nest_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/notification_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/photo_repository.dart';

/// Bundles all entity repositories needed by backup collector and restorer.
///
/// Eliminates repeated 12-parameter constructors across BackupDataCollector,
/// BackupRestorer, and BackupService.
class BackupRepositories {
  final BirdRepository bird;
  final BreedingPairRepository breedingPair;
  final EggRepository egg;
  final ChickRepository chick;
  final HealthRecordRepository healthRecord;
  final EventRepository event;
  final IncubationRepository incubation;
  final GrowthMeasurementRepository growthMeasurement;
  final NotificationRepository notification;
  final ClutchRepository clutch;
  final NestRepository nest;
  final PhotoRepository photo;

  const BackupRepositories({
    required this.bird,
    required this.breedingPair,
    required this.egg,
    required this.chick,
    required this.healthRecord,
    required this.event,
    required this.incubation,
    required this.growthMeasurement,
    required this.notification,
    required this.clutch,
    required this.nest,
    required this.photo,
  });
}
