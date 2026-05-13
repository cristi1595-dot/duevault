import 'dart:io';
import 'package:flutter/material.dart';


import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
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
import 'screens/add_item_screen.dart';
import 'screens/add_document_screen.dart';
import 'widgets/global_components.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'models/app_config.dart';
import 'providers/database_provider.dart';
import 'widgets/security_lock_screen.dart';
import 'screens/onboarding_screen.dart';
import 'providers/security_provider.dart';
import 'services/auto_sync_service.dart';
import 'services/migration_service.dart';
import 'widgets/bento_error_screen.dart';






final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Parallelize heavy initializations
    final results = await Future.wait([
      Firebase.initializeApp(),
      NotificationService.initialize().catchError((e) {
        debugPrint('Notification init skipped: $e');
        return null;
      }),
      getApplicationDocumentsDirectory(),
    ]);

    final dir = results[2] as Directory;
    
    BackgroundService.initialize();
    BackgroundService.registerPeriodicTask();

    // Initialize Isar DB (Isar 3.x does not support native DB encryption, 
    // we use field-level encryption in EncryptionService instead)
    final isar = await Isar.open(
      [UserSchema, VaultItemSchema, AppConfigSchema],
      directory: dir.path,
    );

    // Run Data Migrations (Auto-update categories, etc.)
    await MigrationService.runMigrations(isar);






    // Read initial onboarding state
    final config = await isar.appConfigs.get(0);
    final hasSeen = config?.hasSeenOnboarding ?? false;

    runApp(
      ProviderScope(
        overrides: [
          isarProvider.overrideWith((ref) => isar),
          hasSeenOnboardingProvider.overrideWith((ref) => hasSeen),
        ],
        child: const DueVaultApp(),
      ),
    );
  } catch (e, stackTrace) {
    runApp(MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: BentoErrorScreen(
        error: e.toString(),
        stackTrace: stackTrace.toString(),
      ),
    ));

  }
}

class DueVaultApp extends ConsumerStatefulWidget {
  const DueVaultApp({super.key});

  @override
  ConsumerState<DueVaultApp> createState() => _DueVaultAppState();
}

class _DueVaultAppState extends ConsumerState<DueVaultApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 1. Lock when minimized
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      final security = ref.read(securityProvider);
      if (security.isEnabled && security.lockOnBackground) {
        debugPrint('App minimized: locking DueVault');
        ref.read(securityProvider.notifier).lock();
      }
    }
    
    // 2. Smart Sync on Resume (Check for cloud updates)
    if (state == AppLifecycleState.resumed) {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user != null) {
        debugPrint('App resumed: Triggering Smart Sync check...');
        // We use Future.delayed to ensure the app is fully ready
        Future.delayed(const Duration(milliseconds: 500), () {
          ref.read(autoSyncServiceProvider).syncOnStartup();
        });
      }
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
              debugPrint('DueVault: Auth state changed. User: ${user?.uid}, Guest: $isGuest, Onboarding seen: $hasSeenOnboarding');
              
              Widget root;
              if (!hasSeenOnboarding) {
                root = const OnboardingScreen();
              } else if (user != null || isGuest) {
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
                    const Positioned.fill(
                      child: SecurityLockScreen(),
                    ),
                  ],
                );
              }

              
              return root;
            },
            loading: () => Scaffold(
              backgroundColor: themeMode == ThemeMode.dark ? const Color(0xFF131313) : const Color(0xFFF8FAFC),
              body: const Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
          );
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    VaultScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: IntegratedBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          setState(() => _currentIndex = index);
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
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
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

  Widget _buildPopupItem(BuildContext context, String title, String subtitle, IconData icon) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => title == 'Document'
                ? const AddDocumentScreen()
                : AddItemScreen(item: VaultItem()..itemType = title),
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
            Icon(Icons.chevron_right, color: Theme.of(context).textTheme.bodyMedium?.color),
          ],
        ),
      ),
    );
  }
}
