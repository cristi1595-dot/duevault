import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../utils/logger.dart';

/// Set to true to unlock all features (Google Drive Sync, Smart OCR Scanning,
/// and unlimited attachments) for all users for free, bypassing all paywalls.
const bool kAllFeaturesFree = true;

final isPremiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  return PremiumNotifier();
});

class PremiumNotifier extends StateNotifier<bool> {
  PremiumNotifier() : super(kAllFeaturesFree ? true : false) {
    if (!kAllFeaturesFree) {
      _checkPremiumStatus();
    }
  }

  Future<void> _checkPremiumStatus() async {
    if (kAllFeaturesFree) {
      state = true;
      return;
    }
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      state = customerInfo.entitlements.all['DueVault Pro']?.isActive ?? false;
      logger.d('RevenueCat: Premium status checked. isPro: $state');
    } catch (e) {
      logger.w('RevenueCat: getCustomerInfo failed: $e');
      state = false;
    }
  }

  /// Re-checks the premium status from RevenueCat.
  /// Call this after a successful purchase or restore.
  Future<void> refresh() async {
    if (kAllFeaturesFree) {
      state = true;
      return;
    }
    await _checkPremiumStatus();
  }

  /// Directly sets premium state from a CustomerInfo object.
  /// Used after purchase/restore to avoid an extra network call.
  void updateFromCustomerInfo(CustomerInfo customerInfo) {
    if (kAllFeaturesFree) {
      state = true;
      return;
    }
    state = customerInfo.entitlements.all['DueVault Pro']?.isActive ?? false;
    logger.i('RevenueCat: Premium state updated from CustomerInfo. isPro: $state');
  }
}
