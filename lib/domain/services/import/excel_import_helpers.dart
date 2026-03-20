import 'package:easy_localization/easy_localization.dart';
import 'package:excel/excel.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';

final _dateFormat = DateFormat('dd.MM.yyyy');

/// Finds a sheet by trying multiple possible names, falling back to null.
Sheet? findSheet(Excel excel, List<String> names) {
  for (final name in names) {
    if (excel.tables.containsKey(name)) {
      return excel.tables[name];
    }
  }
  return null;
}

String? cellToString(List<Data?> row, int index) {
  if (index >= row.length) return null;
  final cell = row[index];
  if (cell == null) return null;
  return cell.value?.toString();
}

/// Parses a date string, trying `dd.MM.yyyy` first, then ISO 8601 fallback.
DateTime? parseDate(String? value) {
  if (value == null || value.isEmpty) return null;
  try {
    return _dateFormat.parse(value);
  } catch (_) {
    return DateTime.tryParse(value);
  }
}

BirdGender parseGender(String? value) {
  if (value == null) return BirdGender.unknown;
  final lower = value.toLowerCase().trim();
  if (lower == 'erkek' || lower == 'male' || lower == 'maennlich') {
    return BirdGender.male;
  }
  if (lower == 'disi' || lower == 'female' || lower == 'weiblich') {
    return BirdGender.female;
  }
  return BirdGender.unknown;
}

BreedingStatus parseBreedingStatus(String? value) {
  if (value == null) return BreedingStatus.active;
  final lower = value.toLowerCase().trim();
  if (lower == 'aktif' || lower == 'active' || lower == 'aktiv') {
    return BreedingStatus.active;
  }
  if (lower == 'devam' ||
      lower == 'devam ediyor' ||
      lower == 'ongoing' ||
      lower == 'laufend') {
    return BreedingStatus.ongoing;
  }
  if (lower == 'tamamlandi' ||
      lower == 'completed' ||
      lower == 'abgeschlossen') {
    return BreedingStatus.completed;
  }
  if (lower == 'iptal' ||
      lower == 'iptal edildi' ||
      lower == 'cancelled' ||
      lower == 'abgebrochen') {
    return BreedingStatus.cancelled;
  }
  return BreedingStatus.active;
}

EggStatus parseEggStatus(String? value) {
  if (value == null) return EggStatus.laid;
  final lower = value.toLowerCase().trim();
  if (lower == 'birakildi' || lower == 'laid' || lower == 'gelegt') {
    return EggStatus.laid;
  }
  if (lower == 'kuluckada' || lower == 'incubating' || lower == 'bruetend') {
    return EggStatus.incubating;
  }
  if (lower == 'verimli' || lower == 'fertile' || lower == 'befruchtet') {
    return EggStatus.fertile;
  }
  if (lower == 'verimsiz' || lower == 'infertile' || lower == 'unbefruchtet') {
    return EggStatus.infertile;
  }
  if (lower == 'cikti' || lower == 'hatched' || lower == 'geschluepft') {
    return EggStatus.hatched;
  }
  if (lower == 'bos' || lower == 'empty' || lower == 'leer') {
    return EggStatus.empty;
  }
  if (lower == 'hasarli' || lower == 'damaged' || lower == 'beschaedigt') {
    return EggStatus.damaged;
  }
  if (lower == 'atildi' || lower == 'discarded' || lower == 'entsorgt') {
    return EggStatus.discarded;
  }
  return EggStatus.laid;
}

ChickHealthStatus parseHealthStatus(String? value) {
  if (value == null) return ChickHealthStatus.healthy;
  final lower = value.toLowerCase().trim();
  if (lower == 'saglikli' || lower == 'healthy' || lower == 'gesund') {
    return ChickHealthStatus.healthy;
  }
  if (lower == 'hasta' || lower == 'sick' || lower == 'krank') {
    return ChickHealthStatus.sick;
  }
  if (lower == 'vefat' || lower == 'deceased' || lower == 'verstorben') {
    return ChickHealthStatus.deceased;
  }
  return ChickHealthStatus.unknown;
}

HealthRecordType parseHealthRecordType(String? value) {
  if (value == null) return HealthRecordType.checkup;
  final lower = value.toLowerCase().trim();
  if (lower == 'kontrol' || lower == 'checkup' || lower == 'untersuchung') {
    return HealthRecordType.checkup;
  }
  if (lower == 'hastalik' || lower == 'illness' || lower == 'krankheit') {
    return HealthRecordType.illness;
  }
  if (lower == 'yaralanma' || lower == 'injury' || lower == 'verletzung') {
    return HealthRecordType.injury;
  }
  if (lower == 'asilama' || lower == 'vaccination' || lower == 'impfung') {
    return HealthRecordType.vaccination;
  }
  if (lower == 'ilac' ||
      lower == 'ilac tedavisi' ||
      lower == 'medication' ||
      lower == 'medikation') {
    return HealthRecordType.medication;
  }
  if (lower == 'vefat' || lower == 'death' || lower == 'tod') {
    return HealthRecordType.death;
  }
  return HealthRecordType.unknown;
}
