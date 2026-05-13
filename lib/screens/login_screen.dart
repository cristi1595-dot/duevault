import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/global_components.dart';
import '../services/auto_sync_service.dart';
import '../providers/database_provider.dart';
import '../models/app_config.dart';
import '../providers/vault_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  Future<void> _completeOnboarding(WidgetRef ref) async {
    final isar = ref.read(isarProvider);
    await isar.writeTxn(() async {
      final config = await isar.appConfigs.get(0) ?? AppConfig();
      config.hasSeenOnboarding = true;
      await isar.appConfigs.put(config);
    });
    ref.read(hasSeenOnboardingProvider.notifier).state = true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // App Full Logo
              Center(
                child: Image.asset(
                  'assets/images/full_logo.png',
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 12),
              // Subtitle
              Text(
                'Securely manage your bills\nand documents in one place.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const Spacer(),
              // Google Sign In Button
              _buildGoogleSignInButton(context, ref),
              const SizedBox(height: 16),
              // Continue as Guest Button
              SecondaryButton(
                label: 'Continue as Guest',
                icon: Icons.person_outline,
                onPressed: () async {
                  await _completeOnboarding(ref);
                  ref.read(isGuestProvider.notifier).state = true;
                },
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryAction),
          ),
        );

        final userCredential = await ref.read(authServiceProvider).signInWithGoogle();
        
        // Remove loading indicator
        if (context.mounted) {
          Navigator.pop(context);
        }

        if (userCredential != null) {
          // Migrate guest data to the new user ID
          await ref.read(vaultProvider.notifier).migrateGuestData(userCredential.user!.uid);

          // Get the display name — handle null AND empty string
          final firebaseUser = FirebaseAuth.instance.currentUser;
          final rawName = userCredential.user?.displayName 
              ?? firebaseUser?.displayName;
          final displayName = (rawName != null && rawName.isNotEmpty) 
              ? rawName 
              : (firebaseUser?.email?.split('@').first ?? 'User');
          messenger.showSnackBar(
            SnackBar(content: Text('Welcome, $displayName! Syncing your data...')),
          );
          
          // Intelligent sync after login
          final syncResult = await ref.read(autoSyncServiceProvider).syncAfterLogin();

          // ONLY mark onboarding complete AFTER sync is done
          // This ensures main.dart doesn't switch to MainNavigation prematurely
          await _completeOnboarding(ref);

          if (context.mounted) {
            messenger.clearSnackBars();
            String message;
            Color? bgColor;
            
            if (syncResult == 'restored') {
              message = '✓ Your vault data has been restored from Cloud!';
              bgColor = AppTheme.safeGreen;
            } else if (syncResult == 'uploaded') {
              message = '✓ Your local data has been synchronized with your account!';
              bgColor = AppTheme.primaryAction;
            } else {
              message = 'Welcome! Starting fresh with your new vault.';
              bgColor = null;
            }

            messenger.showSnackBar(SnackBar(
              content: Text(message),
              backgroundColor: bgColor,
            ));
          }
        } else {
          messenger.showSnackBar(
            const SnackBar(content: Text('Sign in failed or was canceled')),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).cardTheme.color,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(
            'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
            height: 24,
            errorBuilder: (ctx, err, st) => const Icon(
              Icons.account_circle,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Sign in with Google',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
