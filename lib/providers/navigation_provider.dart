import 'package:flutter_riverpod/flutter_riverpod.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

/// Controls bottom nav bar visibility. Set to false when scrolling down, true when scrolling up.
final navBarVisibleProvider = StateProvider<bool>((ref) => true);
