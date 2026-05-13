import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:isar/isar.dart';
import 'package:duevault_app/models/app_config.dart';
import 'package:duevault_app/providers/database_provider.dart';
import 'package:app_settings/app_settings.dart';

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
  final Isar isar;

  SecurityNotifier(this.isar) : super(SecurityState()) {
    _init();
  }

  Future<void> _init() async {
    final config = isar.appConfigs.getSync(0);
    final bool isEnabledInDb = config?.isSecurityEnabled ?? false;
    final bool lockOnBg = config?.lockOnBackground ?? true;

    final isSupported = await auth.isDeviceSupported();
    final canCheck = await auth.canCheckBiometrics;
    final available = await auth.getAvailableBiometrics();
    
    // Check if the device has ANY form of security (Biometrics or PIN/Pass)
    final bool hasHardwareSecurity = isSupported || canCheck || available.isNotEmpty;

    // Start as locked ONLY if enabled AND the hardware supports it
    bool shouldBeLocked = isEnabledInDb && hasHardwareSecurity;

    state = state.copyWith(
      isEnabled: isEnabledInDb,
      isLocked: shouldBeLocked,
      lockOnBackground: lockOnBg,
      canAuthenticate: hasHardwareSecurity,
    );
    
    debugPrint('Security: Init - Enabled: $isEnabledInDb, HardwareSupport: $hasHardwareSecurity, Locked: $shouldBeLocked');
  }


  Future<void> toggleSecurity(bool enabled) async {
    // If enabling, check if hardware can actually authenticate
    if (enabled && !state.canAuthenticate) {
      // We don't enable it if the device itself isn't secure
      return;
    }

    state = state.copyWith(isEnabled: enabled);
    
    await isar.writeTxn(() async {
      final config = await isar.appConfigs.get(0) ?? AppConfig();
      config.isSecurityEnabled = enabled;
      await isar.appConfigs.put(config);
    });
  }


  /// Opens the system security settings so the user can set a PIN/Biometrics
  Future<void> openSecuritySettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.security);
  }


  Future<void> toggleLockOnBackground(bool enabled) async {
    final config = await isar.appConfigs.get(0) ?? AppConfig();
    config.lockOnBackground = enabled;
    
    await isar.writeTxn(() async {
      await isar.appConfigs.put(config);
    });

    state = state.copyWith(lockOnBackground: enabled);
  }

  Future<bool> authenticate() async {
    // If security is disabled or hardware doesn't support it, just unlock
    if (!state.isEnabled || !state.canAuthenticate) {
      state = state.copyWith(isLocked: false);
      return true;
    }
    
    if (state.isAuthenticating) return false;

    state = state.copyWith(isAuthenticating: true);
    try {
      final authenticated = await (auth as dynamic).authenticate(
        localizedReason: 'Unlock DueVault to access your data',
        biometricOnly: false, // FALLBACK: Use PIN/Pattern/Password if biometrics fail or are missing
        stickyAuth: true,
      );
      
      if (authenticated) {
        state = state.copyWith(isLocked: false);
      }
      return authenticated;
    } on PlatformException catch (e) {
      debugPrint('Security authentication error: ${e.code} - ${e.message}');
      // If no biometrics are enrolled but PIN exists, local_auth usually handles it via biometricOnly: false.
      // If everything fails, we keep it locked for safety unless we detect the device is insecure.
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
}

final securityProvider = StateNotifierProvider<SecurityNotifier, SecurityState>((ref) {
  final isar = ref.watch(isarProvider);
  return SecurityNotifier(isar);
});
