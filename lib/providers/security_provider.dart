import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:app_settings/app_settings.dart';

import '../utils/logger.dart';
import '../repositories/vault_repository.dart';
import 'vault_provider.dart';



// Triggering re-analysis
// Triggering re-analysis

class SecurityState {
  final bool isLocked;
  final bool isEnabled;
  final bool lockOnBackground;
  final bool canAuthenticate;
  final bool isAuthenticating;

  SecurityState({
    this.isLocked = false,
    this.isEnabled = false,
    this.lockOnBackground = true,
    this.canAuthenticate = false,
    this.isAuthenticating = false,
  });

  SecurityState copyWith({
    bool? isLocked,
    bool? isEnabled,
    bool? lockOnBackground,
    bool? canAuthenticate,
    bool? isAuthenticating,
  }) {
    return SecurityState(
      isLocked: isLocked ?? this.isLocked,
      isEnabled: isEnabled ?? this.isEnabled,
      lockOnBackground: lockOnBackground ?? this.lockOnBackground,
      canAuthenticate: canAuthenticate ?? this.canAuthenticate,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
    );
  }
}

class SecurityNotifier extends StateNotifier<SecurityState> {
  final LocalAuthentication auth = LocalAuthentication();
  final VaultRepository repository;
  final Ref ref;

  SecurityNotifier(this.repository, this.ref) : super(SecurityState()) {
    _init();
  }

  Future<void> _init() async {
    final config = await repository.getConfig();
    final bool isEnabledInDb = config.isSecurityEnabled;
    final bool lockOnBg = config.lockOnBackground;

    // Set initial state based on DB only first, to unlock UI immediately
    state = state.copyWith(
      isEnabled: isEnabledInDb,
      isLocked: isEnabledInDb, // Start locked if enabled, we'll refine this below
      lockOnBackground: lockOnBg,
    );

    // If security is NOT enabled, we don't need to block for hardware checks
    // We can run them after a small delay to keep startup smooth
    if (!isEnabledInDb) {
      Future.delayed(const Duration(seconds: 3), () async {
        final hasHardware = await _checkHardwareSupport();
        state = state.copyWith(canAuthenticate: hasHardware);
        logger.i('Security: Lazy Hardware Check - Supported: $hasHardware');
      });
      return;
    }

    // If security IS enabled, we MUST check hardware now to know if we can unlock
    final hasHardware = await _checkHardwareSupport();
    state = state.copyWith(
      canAuthenticate: hasHardware,
      isLocked: isEnabledInDb && hasHardware,
    );
    
    logger.i('Security: Init - Enabled: $isEnabledInDb, HardwareSupport: $hasHardware, Locked: ${state.isLocked}');
  }

  Future<bool> _checkHardwareSupport() async {
    try {
      final isSupported = await auth.isDeviceSupported();
      final canCheck = await auth.canCheckBiometrics;
      final available = await auth.getAvailableBiometrics();
      return isSupported || canCheck || available.isNotEmpty;
    } catch (e) {
      logger.e('Security: Hardware check failed', error: e);
      return false;
    }
  }


  Future<void> toggleSecurity(bool enabled) async {
    // If enabling, check if hardware can actually authenticate
    if (enabled && !state.canAuthenticate) {
      // We don't enable it if the device itself isn't secure
      return;
    }

    if (enabled) {
      // Senior UX Fix: Request immediate authentication to verify the owner before enabling
      final authenticated = await authenticate(force: true);
      if (!authenticated) {
        // If authentication fails or is cancelled, don't enable security
        return;
      }
    }

    state = state.copyWith(isEnabled: enabled);
    
    await repository.updateConfig(
      (await repository.getConfig())..isSecurityEnabled = enabled
    );
  }


  /// Opens the system security settings so the user can set a PIN/Biometrics
  Future<void> openSecuritySettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.security);
  }


  Future<void> toggleLockOnBackground(bool enabled) async {
    final config = await repository.getConfig();
    config.lockOnBackground = enabled;
    await repository.updateConfig(config);

    state = state.copyWith(lockOnBackground: enabled);
  }

  Future<bool> authenticate({bool force = false}) async {
    // If security is disabled or hardware doesn't support it, just unlock
    // (Unless forced, e.g. during activation)
    if (!force && (!state.isEnabled || !state.canAuthenticate)) {
      state = state.copyWith(isLocked: false);
      return true;
    }
    
    if (!state.canAuthenticate) return false;
    
    if (state.isAuthenticating) return false;

    state = state.copyWith(isAuthenticating: true);
    try {
      // Senior Fix: Using standard AuthenticationOptions (compatible with ^2.3.0+)
      final authenticated = await auth.authenticate(
        localizedReason: 'Unlock DueVault to access your data',
        options: const AuthenticationOptions(
          stickyAuth: true,
          useErrorDialogs: true,
          biometricOnly: false,
        ),
      );
      
      if (authenticated) {
        state = state.copyWith(isLocked: false);
      }
      return authenticated;
    } on PlatformException catch (e, stack) {
      // Senior Fix: Explicitly handle lockouts and other platform-specific codes for Android 16/17 readiness
      if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
        logger.w('Security: Biometrics locked out. System will require PIN/Pattern fallback.');
      } else {
        logger.e('Security authentication error: ${e.code}', error: e, stackTrace: stack);
      }
      return false;
    } catch (e, stack) {
      logger.e('Unexpected security error', error: e, stackTrace: stack);
      return false;
    } finally {
      state = state.copyWith(isAuthenticating: false);
    }
  }


  void lock() {
    if (state.isEnabled) {
      state = state.copyWith(isLocked: true);
    }
  }

  Future<void> reset() async {
    state = state.copyWith(isEnabled: false, isLocked: false);
    final config = await repository.getConfig();
    config.isSecurityEnabled = false;
    await repository.updateConfig(config);
    logger.i('Security: Reset complete (disabled and unlocked).');
  }
}

final securityProvider = StateNotifierProvider<SecurityNotifier, SecurityState>((ref) {
  final repository = ref.watch(vaultRepositoryProvider);
  return SecurityNotifier(repository, ref);
});
