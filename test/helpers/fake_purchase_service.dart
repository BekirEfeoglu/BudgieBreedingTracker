import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:budgie_breeding_tracker/domain/services/payment/purchase_service.dart';

/// A fake [PurchaseService] for unit tests that allows configuring
/// return values and errors for each method without touching RevenueCat SDK.
///
/// Superset of all test needs: supports result/error pairs, call counters,
/// and argument tracking for all public methods.
class FakePurchaseService extends PurchaseService {
  bool fakeInitialized = true;
  bool initializeResult = true;
  Object? initializeError;
  bool isPremiumResult = false;
  Object? isPremiumError;
  List<Package> offeringsResult = const [];
  Object? offeringsError;
  bool purchaseResult = false;
  Object? purchaseError;
  bool restoreResult = false;
  Object? restoreError;
  SubscriptionInfo subscriptionInfoResult = const SubscriptionInfo(
    isActive: false,
  );

  int initializeCallCount = 0;
  String? lastInitializedApiKey;
  String? lastInitializedUserId;
  int isPremiumCallCount = 0;
  int logoutCallCount = 0;
  Package? lastPurchasedPackage;

  @override
  bool get isInitialized => fakeInitialized;

  @override
  Future<bool> initialize({
    required String apiKey,
    required String userId,
  }) async {
    initializeCallCount++;
    lastInitializedApiKey = apiKey;
    lastInitializedUserId = userId;
    if (initializeError != null) throw initializeError!;
    return initializeResult;
  }

  @override
  Future<bool> isPremium() async {
    isPremiumCallCount++;
    if (isPremiumError != null) throw isPremiumError!;
    return isPremiumResult;
  }

  @override
  Future<List<Package>> getOfferings() async {
    if (offeringsError != null) throw offeringsError!;
    return offeringsResult;
  }

  @override
  Future<bool> purchasePackage(Package package) async {
    lastPurchasedPackage = package;
    if (purchaseError != null) throw purchaseError!;
    return purchaseResult;
  }

  @override
  Future<bool> restorePurchases() async {
    if (restoreError != null) throw restoreError!;
    return restoreResult;
  }

  @override
  Future<SubscriptionInfo> getSubscriptionInfo() async =>
      subscriptionInfoResult;

  @override
  Future<void> logout() async {
    logoutCallCount++;
  }
}
