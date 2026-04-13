import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: unnecessary_import
import 'package:intl/intl.dart' show DateFormat;
import 'package:shared_preferences/shared_preferences.dart';

import '../local/preferences/app_preferences.dart';

// ---------------------------------------------------------------------------
// Date Format
// ---------------------------------------------------------------------------

enum AppDateFormat {
  dmy,
  mdy,
  ymd;

  String get label => switch (this) {
    AppDateFormat.dmy => 'GG.AA.YYYY',
    AppDateFormat.mdy => 'AA/GG/YYYY',
    AppDateFormat.ymd => 'YYYY-AA-GG',
  };

  String get intlPattern => switch (this) {
    AppDateFormat.dmy => 'dd.MM.yyyy',
    AppDateFormat.mdy => 'MM/dd/yyyy',
    AppDateFormat.ymd => 'yyyy-MM-dd',
  };

  DateFormat formatter({bool withTime = false}) {
    final pattern = withTime ? '$intlPattern HH:mm' : intlPattern;
    return DateFormat(pattern);
  }
}

final dateFormatProvider = NotifierProvider<DateFormatNotifier, AppDateFormat>(
  DateFormatNotifier.new,
);

class DateFormatNotifier extends Notifier<AppDateFormat> {
  @override
  AppDateFormat build() {
    _loadFromPrefs();
    return AppDateFormat.dmy;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(AppPreferences.keyDateFormat);
    if (value != null) {
      state = AppDateFormat.values.firstWhere(
        (e) => e.name == value,
        orElse: () => AppDateFormat.dmy,
      );
    }
  }

  Future<void> setFormat(AppDateFormat format) async {
    state = format;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppPreferences.keyDateFormat, format.name);
  }
}
