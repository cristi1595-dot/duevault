import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/bills/bills_screen.dart';
import 'screens/documents/documents_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';
import 'models/user.dart';
import 'models/vault_item.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'screens/add_bill_screen.dart';
import 'screens/add_document_screen.dart';
import 'screens/add_shared/attachment_picker_helper.dart';
import 'widgets/global_components.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'models/app_config.dart';
import 'providers/database_provider.dart';
import 'providers/navigation_provider.dart';
import 'screens/onboarding_screen.dart';
import 'providers/security_provider.dart';
import 'services/auto_sync_service.dart';
import 'dart:async';
import 'utils/logger.dart';
import 'services/firebase_sync_service.dart';
import 'providers/sync_provider.dart';
import 'providers/vault_provider.dart';
import 'widgets/walkthrough_overlay.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Disable Google Fonts runtime network fetching to prevent Crashlytics errors
    // when network is unstable or blocked. Fallback to system fonts works gracefully.
    GoogleFonts.config.allowRuntimeFetching = false;

    // Stability Fix for Android 15: Lock to Portrait to avoid memory crashes on rotation
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Parallelize ONLY critical initializations
    await Firebase.initializeApp();

    // Initialize Firebase App Check with Play Integrity for Android (conditional debug/release)
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleDeviceCheckProvider(),
    );

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

      // Refresh vault so autopay date rollover, overdue bills, and recurrence are updated immediately
      ref.read(vaultProvider.notifier).refreshVault();

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
                  ? const Color(0xFF0F1115) // AppTheme.darkBackground
                  : const Color(0xFFF1F5F9), // AppTheme.lightBackground
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DueVaultLogo(size: 100),
                    SizedBox(height: 32),
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryAction,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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

final showWalkthroughProvider = StateProvider<bool>((ref) => false);

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  final List<Widget> _screens = const [
    HomeScreen(),
    BillsScreen(),
    DocumentsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initWalkthrough();
  }

  Future<void> _initWalkthrough() async {
    try {
      final repository = ref.read(vaultRepositoryProvider);
      final config = await repository.getConfig();
      ref.read(showWalkthroughProvider.notifier).state = !config.hasSeenWalkthrough;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(bottomNavIndexProvider);
    final isVaultEmpty = ref.watch(vaultProvider).isEmpty;
    final isNavBarVisible = ref.watch(navBarVisibleProvider);
    final showWalkthrough = ref.watch(showWalkthroughProvider);

    final mainScaffold = Scaffold(
      extendBody: true,
      body: IndexedStack(index: currentIndex, children: _screens),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        offset: isNavBarVisible ? Offset.zero : const Offset(0, 1),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isNavBarVisible ? 1.0 : 0.0,
          child: IntegratedBottomNavBar(
            currentIndex: currentIndex,
            isVaultEmpty: isVaultEmpty,
            onTap: (index) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ref.read(navBarVisibleProvider.notifier).state = true;
              ref.read(bottomNavIndexProvider.notifier).state = index;
            },
            onAddPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Theme.of(context).cardTheme.color,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (sheetContext) => Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Add New Item',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Scan or manually enter your bills & documents.',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildQuickActionItem(
                        context: context,
                        title: 'Scan Bill / Receipt',
                        subtitle: 'Instant AI scan with amount & due date extraction',
                        icon: Icons.document_scanner_outlined,
                        isHighlight: true,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _handleScanBill(context);
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildQuickActionItem(
                        context: context,
                        title: 'New Bill',
                        subtitle: 'Manual entry for upcoming & recurring payments',
                        icon: Icons.receipt_long,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddBillScreen(
                                item: VaultItem()..itemType = 'Bill',
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildQuickActionItem(
                        context: context,
                        title: 'New Document',
                        subtitle: 'Vault IDs, contracts, warranties & certificates',
                        icon: Icons.badge_outlined,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddDocumentScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    if (!showWalkthrough) {
      return mainScaffold;
    }

    return Stack(
      children: [
        mainScaffold,
        Positioned.fill(
          child: WalkthroughOverlay(
            onFinished: () async {
              ref.read(showWalkthroughProvider.notifier).state = false;
              final repository = ref.read(vaultRepositoryProvider);
              final config = await repository.getConfig();
              config.hasSeenWalkthrough = true;
              await repository.updateConfig(config);
            },
            onSkipped: () async {
              ref.read(showWalkthroughProvider.notifier).state = false;
              final repository = ref.read(vaultRepositoryProvider);
              final config = await repository.getConfig();
              config.hasSeenWalkthrough = true;
              await repository.updateConfig(config);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _handleScanBill(BuildContext context) async {
    // Show scanning progress modal
    unawaited(
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryAction),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Scanning with DueVault AI...',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final scanData = await AttachmentPickerHelper.scanWithOcr(
      context: context,
      isDocument: false,
      onError: (err) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err),
              backgroundColor: AppTheme.urgentRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );

    // Dismiss loading dialog
    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    if (scanData != null && context.mounted) {
      final ocr = scanData.ocrResult;
      final defaultTitle = ocr.probableTitle ??
          (ocr.probableDate != null
              ? 'Bill - ${ocr.probableDate!.day}/${ocr.probableDate!.month}'
              : 'Scanned Bill');

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddBillScreen(
            item: VaultItem()
              ..itemType = 'Bill'
              ..title = defaultTitle
              ..amount = ocr.probableAmount
              ..dueDate = ocr.probableDate,
            initialAttachments: [scanData.imagePath],
            initialOcrResult: ocr,
          ),
        ),
      );
    }
  }

  Widget _buildQuickActionItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isHighlight = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isHighlight
              ? AppTheme.primaryAction.withValues(alpha: 0.08)
              : Colors.transparent,
          border: Border.all(
            color: isHighlight
                ? AppTheme.primaryAction.withValues(alpha: 0.4)
                : Theme.of(context).dividerColor.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isHighlight
                    ? AppTheme.primaryAction
                    : AppTheme.primaryAction.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isHighlight ? Colors.white : AppTheme.primaryAction,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isHighlight) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryAction.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'AI OCR',
                            style: TextStyle(
                              color: AppTheme.primaryAction,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
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
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
