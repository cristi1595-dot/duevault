import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../providers/premium_provider.dart';
import '../theme/app_theme.dart';
import '../utils/logger.dart';
import '../widgets/duevault_logo.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _isLoading = false;

  void _showNotification(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: isError ? AppTheme.urgentRed : AppTheme.safeGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleUnlockPro() async {
    setState(() => _isLoading = true);
    try {
      logger.i('Fetching RevenueCat offerings...');
      final offerings = await Purchases.getOfferings();

      if (offerings.current == null) {
        _showNotification('No offerings available. Please try again later.', isError: true);
        return;
      }

      // Use the default (first available) package from the current offering
      final package = offerings.current!.availablePackages.first;
      logger.i('Initiating purchase for package: ${package.identifier}');

      final purchaseResult = await Purchases.purchase(PurchaseParams.package(package));
      final customerInfo = purchaseResult.customerInfo;

      if (customerInfo.entitlements.all['DueVault Pro']?.isActive == true) {
        // Update premium state immediately from the returned CustomerInfo
        ref.read(isPremiumProvider.notifier).updateFromCustomerInfo(customerInfo);
        if (!mounted) return;
        _showNotification('✓ Purchase successful! PRO unlocked.');
        Navigator.pop(context); // Close Paywall
      } else {
        _showNotification('Purchase completed but PRO entitlement not found. Contact support.', isError: true);
      }
    } on PlatformException catch (e) {
      // RevenueCat wraps errors in PlatformException
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        logger.i('Purchase cancelled by user.');
        _showNotification('Purchase cancelled.', isError: true);
      } else {
        logger.e('Purchase error', error: e);
        _showNotification('Purchase failed: ${e.message}', isError: true);
      }
    } catch (e, stack) {
      logger.e('Unexpected purchase error', error: e, stackTrace: stack);
      _showNotification('Error initiating purchase: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRestorePurchases() async {
    setState(() => _isLoading = true);
    try {
      logger.i('Restoring purchases with RevenueCat...');
      final customerInfo = await Purchases.restorePurchases();
      final isPro = customerInfo.entitlements.all['DueVault Pro']?.isActive ?? false;

      if (!mounted) return;

      if (isPro) {
        ref.read(isPremiumProvider.notifier).updateFromCustomerInfo(customerInfo);
        _showNotification('✓ Purchases restored! PRO unlocked.');
        Navigator.pop(context); // Close Paywall
      } else {
        _showNotification('No active PRO subscription found.', isError: true);
      }
    } catch (e, stack) {
      logger.e('Restore error', error: e, stackTrace: stack);
      if (!mounted) return;
      _showNotification('Error restoring purchases: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090E),
      body: Stack(
        children: [
          // Elegant dark neon gradient background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF09090E),
                    Color(0xFF11111A),
                    Color(0xFF0A0714),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Glow effect top-center
          Positioned(
            top: -100,
            left: MediaQuery.of(context).size.width * 0.1,
            right: MediaQuery.of(context).size.width * 0.1,
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7C4DFF).withValues(alpha: 0.15),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF7C4DFF),
                    blurRadius: 120,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header / Close button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16, top: 8),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white60, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 28.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        const DueVaultLogo(
                          size: 80,
                          showGlow: true,
                        ),
                        const SizedBox(height: 24),
                        // Neon styled Title
                        Text(
                          'DueVault PRO',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: const Color(0xFF00E676).withValues(alpha: 0.6),
                                blurRadius: 10,
                                offset: const Offset(0, 0),
                              ),
                              Shadow(
                                color: const Color(0xFF00B0FF).withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Get the ultimate organization & security layer',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white70,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // Benefits List (3 premium cards)
                        _buildBenefitCard(
                          emoji: '☁️',
                          title: 'Cloud Sync & Backup',
                          subtitle: 'Instantly sync and restore across devices safely using Google Drive & Firebase.',
                        ),
                        const SizedBox(height: 16),
                        _buildBenefitCard(
                          emoji: '📸',
                          title: 'Auto-Scan (OCR)',
                          subtitle: 'Automatically scan documents & bills with high precision ML auto-fill tools.',
                        ),
                        const SizedBox(height: 16),
                        _buildBenefitCard(
                          emoji: '♾️',
                          title: 'Unlimited Peace of Mind',
                          subtitle: 'Save unlimited documents, alerts, categories and enjoy zero storage caps.',
                        ),
                        
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),

                // CTA Section (Always at the bottom)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Unlock PRO Action Button
                      GestureDetector(
                        onTap: _isLoading ? null : _handleUnlockPro,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF00E676),
                                Color(0xFF00B0FF),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E676).withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Unlock PRO',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Restore button
                      TextButton(
                        onPressed: _isLoading ? null : _handleRestorePurchases,
                        child: const Text(
                          'Restore Purchases',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white30,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitCard({
    required String emoji,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji Avatar
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 16),
          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
