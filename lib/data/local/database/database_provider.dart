import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';

AppDatabase? _sharedDatabase;

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = _sharedDatabase ??= AppDatabase();
  return db;
});
