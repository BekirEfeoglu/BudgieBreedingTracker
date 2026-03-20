part of 'premium_providers.dart';

/// State for purchase/restore actions with loading and error tracking.
class PurchaseActionState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final PremiumPlan? purchasingPlan;

  const PurchaseActionState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.purchasingPlan,
  });

  PurchaseActionState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    PremiumPlan? purchasingPlan,
  }) => PurchaseActionState(
    isLoading: isLoading ?? this.isLoading,
    error: error,
    isSuccess: isSuccess ?? this.isSuccess,
    purchasingPlan: purchasingPlan,
  );
}

/// Manages purchase/restore action lifecycle (loading, success, error).
class PurchaseActionNotifier extends Notifier<PurchaseActionState> {
  @override
  PurchaseActionState build() => const PurchaseActionState();

  /// Purchases a plan via RevenueCat offerings.
  Future<void> purchasePlan(PremiumPlan plan) async {
    if (!ref.mounted) return;
    state = PurchaseActionState(isLoading: true, purchasingPlan: plan);

    try {
      final isReady = await ref.read(purchaseServiceReadyProvider.future);
      if (!ref.mounted) return;
      if (!isReady) {
        AppLogger.warning('Purchase service is not ready');
        state = const PurchaseActionState(
          error: PurchaseErrorCodes.noOfferings,
        );
        return;
      }

      final offerings = await ref.read(premiumOfferingsProvider.future);
      if (!ref.mounted) return;

      if (offerings.isEmpty) {
        AppLogger.warning('No RevenueCat offerings available');
        state = const PurchaseActionState(
          error: PurchaseErrorCodes.noOfferings,
        );
        return;
      }

      // Find matching package by plan type
      final package = matchPackageForPlan(offerings, plan);
      if (package == null) {
        state = const PurchaseActionState(
          error: PurchaseErrorCodes.packageNotFound,
        );
        return;
      }

      final success = await ref
          .read(localPremiumProvider.notifier)
          .purchase(package);
      if (!ref.mounted) return;
      if (success) {
        state = const PurchaseActionState(isSuccess: true);
      } else {
        state = const PurchaseActionState(error: PurchaseErrorCodes.cancelled);
      }
    } on PurchaseException catch (e, st) {
      AppLogger.error('Purchase failed', e, st);
      if (!ref.mounted) return;
      state = PurchaseActionState(error: e.code);
    } catch (e, st) {
      AppLogger.error('Purchase failed', e, st);
      if (!ref.mounted) return;
      state = PurchaseActionState(error: e.toString());
    }
  }

  /// Restores previous purchases via RevenueCat.
  Future<void> restorePurchases() async {
    if (!ref.mounted) return;
    state = const PurchaseActionState(isLoading: true);

    try {
      final isReady = await ref.read(purchaseServiceReadyProvider.future);
      if (!ref.mounted) return;
      if (!isReady) {
        AppLogger.warning('Purchase service is not ready for restore');
        state = const PurchaseActionState(
          error: PurchaseErrorCodes.noOfferings,
        );
        return;
      }

      final success = await ref.read(localPremiumProvider.notifier).restore();
      if (!ref.mounted) return;
      if (success) {
        state = const PurchaseActionState(isSuccess: true);
      } else {
        state = const PurchaseActionState(
          error: PurchaseErrorCodes.restoreNoPurchases,
        );
      }
    } on PurchaseException catch (e, st) {
      AppLogger.error('Restore failed', e, st);
      if (!ref.mounted) return;
      state = PurchaseActionState(error: e.code);
    } catch (e, st) {
      AppLogger.error('Restore failed', e, st);
      if (!ref.mounted) return;
      state = const PurchaseActionState(
        error: PurchaseErrorCodes.restoreFailed,
      );
    }
  }

  /// Resets the action state.
  void reset() => state = const PurchaseActionState();
}

/// Provider for purchase/restore action state.
final purchaseActionProvider =
    NotifierProvider<PurchaseActionNotifier, PurchaseActionState>(
      PurchaseActionNotifier.new,
    );
