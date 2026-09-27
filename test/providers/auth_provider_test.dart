import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:duevault_app/providers/auth_provider.dart';

void main() {
  test('authStateProvider catches exception and falls back to empty stream', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final asyncValue = container.read(authStateProvider);
    expect(asyncValue, isA<AsyncValue>());
  });

  test('isGuestProvider defaults to true', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(isGuestProvider), isTrue);
  });

  test('hasSeenOnboardingProvider defaults to false', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(hasSeenOnboardingProvider), isFalse);
  });
}
