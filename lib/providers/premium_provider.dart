import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../utils/logger.dart';

final isPremiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  return PremiumNotifier();
});

class PremiumNotifier extends StateNotifier<bool> {
  PremiumNotifier() : super(false) {
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      // Check if 'pro' entitlement is active
      state = customerInfo.entitlements.all['pro']?.isActive ?? false;
      logger.d('RevenueCat customer info loaded. Premium status: $state');
    } catch (e) {
      // API key is mock, so this will print a warning but not crash the application.
      logger.w('RevenueCat getCustomerInfo failed (expected for mock API key): $e');
      state = false;
    }
  }

  Future<void> refresh() async {
    await _checkPremiumStatus();
  }

  void setMockPremium(bool value) {
    state = value;
    logger.i('Premium state manually overridden (mock): $value');
  }
}
