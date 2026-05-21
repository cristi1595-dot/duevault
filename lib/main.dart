import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/vault_screen.dart';
import 'screens/login_screen.dart';
import 'models/user.dart';
import 'models/vault_item.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'screens/add_bill_screen.dart';
import 'screens/add_document_screen.dart';
import 'widgets/global_components.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'models/app_config.dart';
import 'providers/database_provider.dart';
import 'providers/navigation_provider.dart';
import 'widgets/security_lock_screen.dart';
import 'screens/onboarding_screen.dart';
import 'providers/security_provider.dart';
import 'services/auto_sync_service.dart';
import 'widgets/bento_error_screen.dart';
import 'dart:async';
import 'utils/logger.dart';
import 'services/firebase_sync_service.dart';
import 'providers/sync_provider.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Stability Fix for Android 15: Lock to Portrait to avoid memory crashes on rotation
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Parallelize ONLY critical initializations
    await Firebase.initializeApp();

    // Enable Crashlytics collection (explicitly enabled for both debug & release in beta phase)
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

    // Pass all uncaught framework errors (UI or synchronous exceptions) to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    final appDir = await getApplicationDocumentsDirectory();

    // Initialize notifications in the background to not block the UI
    unawaited(
      NotificationService.initialize().catchError((e, stack) {
        logger.e('Notification init skipped', error: e, stackTrace: stack);
      }),
    );

    // Lazy load background services after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      BackgroundService.initialize();
      BackgroundService.registerPeriodicTask();
      logger.i('Delayed Services: Background Sync & WorkManager initialized.');
    });

    // Initialize Isar DB (Isar 3.x does not support native DB encryption,
    // we use field-level encryption in EncryptionService instead)
    final isar = await Isar.open(
      [UserSchema, VaultItemSchema, AppConfigSchema],
      directory: appDir.path,
      inspector: false, // Fix for Android 15/Pixel 9 userfaultfd timeout
    );

    // Run Data Migrations (Postponed to VaultNotifier for Android 15 stability)
    // await MigrationService.runMigrations(isar);

    // Read initial session state (Persistence fix)
    final config = await isar.appConfigs.get(0);
    final hasSeen = config?.hasSeenOnboarding ?? false;
    final isGuest = config?.isGuest ?? false;

    runApp(
      ProviderScope(
        overrides: [
          isarProvider.overrideWith((ref) => isar),
          hasSeenOnboardingProvider.overrideWith((ref) => hasSeen),
          isGuestProvider.overrideWith((ref) => isGuest),
        ],
        child: const DueVaultApp(),
      ),
    );
  } catch (e, stackTrace) {
    runApp(
      MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: BentoErrorScreen(
          error: e.toString(),
          stackTrace: stackTrace.toString(),
        ),
      ),
    );
  }
}

class DueVaultApp extends ConsumerStatefulWidget {
  const DueVaultApp({super.key});

  @override
  ConsumerState<DueVaultApp> createState() => _DueVaultAppState();
}

class _DueVaultAppState extends ConsumerState<DueVaultApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize Firebase Sync (Senior Architecture)
    ref.read(firebaseSyncServiceProvider).initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 1. Senior Fix: Removed "Lock when minimized" logic as per user request.
    // The app now only locks on cold start if security is enabled.

    // 2. Smart Sync & Timezone check on Resume
    if (state == AppLifecycleState.resumed) {
      final user = ref.read(authStateProvider).valueOrNull;

      // Re-init timezone in case of travel
      NotificationService.initialize();

      if (user != null) {
        logger.i('App resumed: Triggering Safe Sync sequence...');
        _runSafeSyncSequence();
      }
    }

    if (state == AppLifecycleState.paused) {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user != null) {
        logger.i('App paused: Triggering immediate background backup...');
        ref.read(autoSyncServiceProvider).scheduleBackup(immediate: true);
        ref.read(firebaseSyncServiceProvider).sync(); // Immediate Firebase Sync
      }
    }
  }

  /// Sequential sync to avoid Isar write lock contention on resume
  Future<void> _runSafeSyncSequence() async {
    try {
      // 1. Wait for system and animations to fully settle
      await Future.delayed(const Duration(milliseconds: 1200));

      // 2. Google Drive Sync
      await ref.read(autoSyncServiceProvider).syncOnStartup();

      // 3. Small gap
      await Future.delayed(const Duration(milliseconds: 300));

      // 4. Firebase Sync
      await ref.read(firebaseSyncServiceProvider).sync();

      logger.i('Safe Sync sequence completed.');
    } catch (e, stack) {
      logger.e('Error during safe sync sequence', error: e, stackTrace: stack);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'DueVault',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: Consumer(
        builder: (context, ref, child) {
          final authState = ref.watch(authStateProvider);
          final isGuest = ref.watch(isGuestProvider);
          final security = ref.watch(securityProvider);

          return authState.when(
            data: (user) {
              final hasSeenOnboarding = ref.watch(hasSeenOnboardingProvider);
              logger.i(
                'DueVault: Auth state changed. User: ${user?.uid}, Guest: $isGuest, Onboarding seen: $hasSeenOnboarding',
              );

              Widget root;
              if (!hasSeenOnboarding) {
                root = const OnboardingScreen();
              } else if ((user != null || isGuest) &&
                  !ref.watch(isProcessingAuthSyncProvider)) {
                root = const MainNavigation();
              } else {
                root = const LoginScreen();
              }

              final bool userReady = user != null || isGuest;

              // Only show lock screen if enabled, device supports it, and user is ready
              if (security.isLocked && userReady && security.canAuthenticate) {
                return Stack(
                  children: [
                    root,
                    const Positioned.fill(child: SecurityLockScreen()),
                  ],
                );
              }

              return root;
            },
            loading: () => Scaffold(
              backgroundColor: themeMode == ThemeMode.dark
                  ? const Color(0xFF131313)
                  : const Color(0xFFF8FAFC),
              body: const Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) =>
                Scaffold(body: Center(child: Text('Error: $err'))),
          );
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigation extends ConsumerWidget {
  const MainNavigation({super.key});

  final List<Widget> _screens = const [HomeScreen(), VaultScreen()];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: _screens),
      bottomNavigationBar: IntegratedBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ref.read(bottomNavIndexProvider.notifier).state = index;
        },
        onAddPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Theme.of(context).cardTheme.color,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add New Item',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select the type of item you want to vault.',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildPopupItem(
                    context,
                    'Bill',
                    'Track payments & due dates',
                    Icons.receipt_long,
                  ),
                  const SizedBox(height: 12),
                  _buildPopupItem(
                    context,
                    'Document',
                    'Store IDs, contracts & more',
                    Icons.description,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopupItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => title == 'Document'
                ? const AddDocumentScreen()
                : AddBillScreen(item: VaultItem()..itemType = title),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryAction.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primaryAction),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ],
        ),
      ),
    );
  }
}
