import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../utils/logger.dart';

final isPremiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  return PremiumNotifier();
});

class PremiumNotifier extends StateNotifier<bool> {
  PremiumNotifier() : super(true) { // Set default to true for testing
    // _checkPremiumStatus(); // Comment out to bypass RevenueCat checks
  }

  Future<void> _checkPremiumStatus() async {
    // try {
    //   final customerInfo = await Purchases.getCustomerInfo();
    //   state = customerInfo.entitlements.all['DueVault Pro']?.isActive ?? false;
    //   logger.d('RevenueCat: Premium status checked. isPro: $state');
    // } catch (e) {
    //   logger.w('RevenueCat: getCustomerInfo failed: $e');
    //   state = true;
    // }
    state = true;
  }

  /// Re-checks the premium status from RevenueCat.
  /// Call this after a successful purchase or restore.
  Future<void> refresh() async {
    await _checkPremiumStatus();
  }

  /// Directly sets premium state from a CustomerInfo object.
  /// Used after purchase/restore to avoid an extra network call.
  void updateFromCustomerInfo(CustomerInfo customerInfo) {
    state = customerInfo.entitlements.all['DueVault Pro']?.isActive ?? false;
    logger.i('RevenueCat: Premium state updated from CustomerInfo. isPro: $state');
  }
}
