import 'package:flutter_riverpod/flutter_riverpod.dart';

/// All features are 100% free for all users (DueVault is completely free).
const bool kAllFeaturesFree = true;

final isPremiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  return PremiumNotifier();
});

class PremiumNotifier extends StateNotifier<bool> {
  PremiumNotifier() : super(true);

  Future<void> refresh() async {
    state = true;
  }
}
