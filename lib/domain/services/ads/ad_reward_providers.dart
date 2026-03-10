import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';

/// Whether statistics is temporarily unlocked via rewarded ad (24h window).
final isStatisticsRewardActiveProvider =
    NotifierProvider<StatisticsRewardNotifier, bool>(
      StatisticsRewardNotifier.new,
    );

class StatisticsRewardNotifier extends Notifier<bool> {
  int _loadSequence = 0;

  @override
  bool build() {
    _load(++_loadSequence);
    return false;
  }

  Future<void> _load(int loadToken) async {
    final prefs = await SharedPreferences.getInstance();
    if (!_isLatestLoad(loadToken)) return;

    final ap = AppPreferences(prefs);
    final unlockedAt = ap.rewardStatisticsUnlockedAt;
    if (unlockedAt == null) {
      if (!ref.mounted) return;
      state = false;
      return;
    }

    final elapsed = DateTime.now().difference(unlockedAt);
    if (!ref.mounted) return;
    state = elapsed < const Duration(hours: 24);
  }

  Future<void> unlock() async {
    final prefs = await SharedPreferences.getInstance();
    final ap = AppPreferences(prefs);
    await ap.setRewardStatisticsUnlockedAt(DateTime.now());
    if (!ref.mounted) return;
    state = true;
  }

  bool _isLatestLoad(int token) => ref.mounted && token == _loadSequence;
}

/// Whether genetics has remaining reward uses.
final isGeneticsRewardActiveProvider =
    NotifierProvider<GeneticsRewardNotifier, bool>(GeneticsRewardNotifier.new);

class GeneticsRewardNotifier extends Notifier<bool> {
  int _loadSequence = 0;

  @override
  bool build() {
    _load(++_loadSequence);
    return false;
  }

  Future<void> _load(int loadToken) async {
    final prefs = await SharedPreferences.getInstance();
    if (!_isLatestLoad(loadToken)) return;

    final ap = AppPreferences(prefs);
    if (!ref.mounted) return;
    state = ap.rewardGeneticsUsesRemaining > 0;
  }

  Future<void> unlock() async {
    final prefs = await SharedPreferences.getInstance();
    final ap = AppPreferences(prefs);
    final current = ap.rewardGeneticsUsesRemaining;
    await ap.setRewardGeneticsUsesRemaining(current + 1);
    if (!ref.mounted) return;
    state = true;
  }

  Future<void> consume() async {
    final prefs = await SharedPreferences.getInstance();
    final ap = AppPreferences(prefs);
    final current = ap.rewardGeneticsUsesRemaining;
    if (current <= 0) return;
    await ap.setRewardGeneticsUsesRemaining(current - 1);
    if (!ref.mounted) return;
    state = current - 1 > 0;
  }

  bool _isLatestLoad(int token) => ref.mounted && token == _loadSequence;
}

/// Whether export has remaining reward uses.
final isExportRewardActiveProvider =
    NotifierProvider<ExportRewardNotifier, bool>(ExportRewardNotifier.new);

class ExportRewardNotifier extends Notifier<bool> {
  int _loadSequence = 0;

  @override
  bool build() {
    _load(++_loadSequence);
    return false;
  }

  Future<void> _load(int loadToken) async {
    final prefs = await SharedPreferences.getInstance();
    if (!_isLatestLoad(loadToken)) return;

    final ap = AppPreferences(prefs);
    if (!ref.mounted) return;
    state = ap.rewardExportUsesRemaining > 0;
  }

  Future<void> unlock() async {
    final prefs = await SharedPreferences.getInstance();
    final ap = AppPreferences(prefs);
    final current = ap.rewardExportUsesRemaining;
    await ap.setRewardExportUsesRemaining(current + 1);
    if (!ref.mounted) return;
    state = true;
  }

  Future<void> consume() async {
    final prefs = await SharedPreferences.getInstance();
    final ap = AppPreferences(prefs);
    final current = ap.rewardExportUsesRemaining;
    if (current <= 0) return;
    await ap.setRewardExportUsesRemaining(current - 1);
    if (!ref.mounted) return;
    state = current - 1 > 0;
  }

  bool _isLatestLoad(int token) => ref.mounted && token == _loadSequence;
}
