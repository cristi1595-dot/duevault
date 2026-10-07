import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WalkthroughOverlay extends StatefulWidget {
  final VoidCallback onFinished;
  final VoidCallback onSkipped;

  const WalkthroughOverlay({
    super.key,
    required this.onFinished,
    required this.onSkipped,
  });

  @override
  State<WalkthroughOverlay> createState() => _WalkthroughOverlayState();
}

class _WalkthroughOverlayState extends State<WalkthroughOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _pulseController;

  static const int _totalSteps = 6;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _nextStep() {
    setState(() {
      if (_currentStep < _totalSteps - 1) {
        _currentStep++;
      } else {
        widget.onFinished();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final theme = Theme.of(context);

    final double topPadding = media.padding.top;
    final double bottomPadding = media.padding.bottom;

    // Responsive bottom bar geometry
    final double navBarTop = size.height - bottomPadding - 12.0 - 66.0;
    const double navBarHeight = 66.0;
    final double navBarWidth = size.width - 32.0;
    const double centerBtnWidth = 54.0;
    final double tabWidth = (navBarWidth - centerBtnWidth) / 4;

    // Target definitions: [x, y, width, height, radius, title, description, alignment, cardPadding]
    final targets = [
      // Step 1: Dashboard Bento Card (Home)
      {
        'left': 16.0,
        'top': topPadding + 75.0,
        'width': size.width - 32.0,
        'height': 180.0,
        'radius': 28.0,
        'title': 'Financial & Document Overview',
        'desc':
            'Your central command hub: track upcoming bills and expiring documents across 7-day and 30-day horizons in a unified bento grid.',
        'cardAlignment': Alignment.bottomCenter,
        'cardPadding': EdgeInsets.fromLTRB(24, 0, 24, bottomPadding + 90.0),
      },
      // Step 2: Profile & Account (Home Header - Top Right)
      {
        'left': size.width - 58.0,
        'top': topPadding + 11.0,
        'width': 48.0,
        'height': 48.0,
        'radius': 24.0,
        'title': 'Profile & Account (Home Only)',
        'desc':
            'Located exclusively on your Home screen: tap your avatar to verify Google Cloud Sync status, check sign-in, or quickly jump into settings.',
        'cardAlignment': Alignment.topCenter,
        'cardPadding': EdgeInsets.fromLTRB(24, topPadding + 72.0, 24, 0),
      },
      // Step 3: Add Button (+) (Center Bottom Bar)
      {
        'left': size.width / 2 - 27.0,
        'top': navBarTop + 6.0,
        'width': 54.0,
        'height': 54.0,
        'radius': 27.0,
        'title': 'Fast Add & AI Scanner',
        'desc':
            'Tap the "+" button anytime to create an entry or scan paper receipts and invoices using the built-in DueVault AI OCR engine.',
        'cardAlignment': Alignment.topCenter,
        'cardPadding': EdgeInsets.fromLTRB(24, topPadding + 110.0, 24, 0),
      },
      // Step 4: Bills Hub (Bottom Bar Tab 1)
      {
        'left': 16.0 + tabWidth,
        'top': navBarTop,
        'width': tabWidth,
        'height': navBarHeight,
        'radius': 16.0,
        'title': 'Dedicated Bills Hub',
        'desc':
            'Manage recurring bills, utilities, and subscriptions. Track auto-pay status, due dates, and mark payments complete with instant swipe actions.',
        'cardAlignment': Alignment.topCenter,
        'cardPadding': EdgeInsets.fromLTRB(24, topPadding + 110.0, 24, 0),
      },
      // Step 5: Documents Hub (Bottom Bar Tab 2)
      {
        'left': size.width / 2 + 27.0,
        'top': navBarTop,
        'width': tabWidth,
        'height': navBarHeight,
        'radius': 16.0,
        'title': 'Secure Documents Hub',
        'desc':
            'Keep contracts, IDs, vehicle licenses, and warranties safe with end-to-end encryption, expiry countdowns, and renewal alerts.',
        'cardAlignment': Alignment.topCenter,
        'cardPadding': EdgeInsets.fromLTRB(24, topPadding + 110.0, 24, 0),
      },
      // Step 6: Settings Hub (Bottom Bar Tab 3)
      {
        'left': size.width / 2 + 27.0 + tabWidth,
        'top': navBarTop,
        'width': tabWidth,
        'height': navBarHeight,
        'radius': 16.0,
        'title': 'Global Settings Hub',
        'desc':
            'Access complete app preferences from any screen in the bottom bar: configure biometric security, Google Drive backups, custom currencies, and alert reminders.',
        'cardAlignment': Alignment.topCenter,
        'cardPadding': EdgeInsets.fromLTRB(24, topPadding + 110.0, 24, 0),
      },
    ];

    final currentTarget = targets[_currentStep];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. ColorFiltered transparent cutout overlay
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.72),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    backgroundBlendMode: BlendMode.clear,
                  ),
                ),
                // Transparent Hole
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  left: currentTarget['left'] as double,
                  top: currentTarget['top'] as double,
                  width: currentTarget['width'] as double,
                  height: currentTarget['height'] as double,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        currentTarget['radius'] as double,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Pulse Ring Animation around current target
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            left: (currentTarget['left'] as double) - 8,
            top: (currentTarget['top'] as double) - 8,
            width: (currentTarget['width'] as double) + 16,
            height: (currentTarget['height'] as double) + 16,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      (currentTarget['radius'] as double) + 8,
                    ),
                    border: Border.all(
                      color: AppTheme.primaryAction.withValues(
                        alpha: 1.0 - _pulseController.value,
                      ),
                      width: 2.0 + (_pulseController.value * 3.5),
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. Explanation Card
          Align(
            alignment: currentTarget['cardAlignment'] as Alignment,
            child: Padding(
              padding: currentTarget['cardPadding'] as EdgeInsets,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: size.width - 48,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step Counter & Skip
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'STEP ${_currentStep + 1} OF $_totalSteps',
                              style: AppTheme.labelCapsStyle(context).copyWith(
                                color: AppTheme.primaryAction,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Progress dots
                            Row(
                              children: List.generate(_totalSteps, (index) {
                                final isActive = index == _currentStep;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin: const EdgeInsets.only(right: 4),
                                  width: isActive ? 14 : 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? AppTheme.primaryAction
                                        : theme.dividerColor
                                            .withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: widget.onSkipped,
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Skip Tour',
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Title
                    Text(
                      currentTarget['title'] as String,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Description text
                    Text(
                      currentTarget['desc'] as String,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13.5,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Navigation Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: _nextStep,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            backgroundColor: AppTheme.primaryAction,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentStep == _totalSteps - 1
                                    ? 'Got it'
                                    : 'Next',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (_currentStep < _totalSteps - 1) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
