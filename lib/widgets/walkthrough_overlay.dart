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
      if (_currentStep < 3) {
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

    // Dynamic targets based on screen dimensions
    final double topPadding = media.padding.top;
    final double bottomPadding = media.padding.bottom;

    // Target definitions: [x, y, width, height, radius, title, description, alignment]
    final targets = [
      // Step 1: Dashboard Bento Card
      {
        'left': 16.0,
        'top': topPadding + 75.0,
        'width': size.width - 32.0,
        'height': 175.0,
        'radius': 24.0,
        'title': 'Financial Overview',
        'desc': 'This bento card shows your total balance, upcoming payments, and current billing cycle status at a glance.',
        'cardAlignment': Alignment.bottomCenter,
        'cardOffset': const Offset(0, -20.0),
      },
      // Step 2: Add Button
      {
        'left': size.width / 2 - 32.0,
        'top': size.height - bottomPadding - 74.0,
        'width': 64.0,
        'height': 64.0,
        'radius': 32.0,
        'title': 'Add Bills & Documents',
        'desc': 'Tap the "+" button to add a new bill or document. You can scan receipts using the built-in AI OCR engine!',
        'cardAlignment': Alignment.topCenter,
        'cardOffset': const Offset(0, 16.0),
      },
      // Step 3: Vault Tab
      {
        'left': (size.width * 0.725) - 28.0,
        'top': size.height - bottomPadding - 70.0,
        'width': 56.0,
        'height': 56.0,
        'radius': 16.0,
        'title': 'Your Secure Vault',
        'desc': 'Navigate here to view all stored bills, archives, and files, categorized and encrypted with device-lock security.',
        'cardAlignment': Alignment.topRight,
        'cardOffset': const Offset(-16.0, 16.0),
      },
      // Step 4: Settings
      {
        'left': size.width - 60.0,
        'top': topPadding + 6.0,
        'width': 48.0,
        'height': 48.0,
        'radius': 24.0,
        'title': 'App Customization',
        'desc': 'Tap the Settings icon to manage security locks, cloud sync, notifications, and customize system theme settings.',
        'cardAlignment': Alignment.bottomRight,
        'cardOffset': const Offset(-16.0, -16.0),
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
            left: (currentTarget['left'] as double) - 10,
            top: (currentTarget['top'] as double) - 10,
            width: (currentTarget['width'] as double) + 20,
            height: (currentTarget['height'] as double) + 20,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      (currentTarget['radius'] as double) + 10,
                    ),
                    border: Border.all(
                      color: AppTheme.primaryAction.withValues(
                        alpha: 1.0 - _pulseController.value,
                      ),
                      width: 2.0 + (_pulseController.value * 4.0),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: size.width - 48,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step Counter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'STEP ${_currentStep + 1} OF 4',
                          style: AppTheme.labelCapsStyle(context).copyWith(
                            color: AppTheme.primaryAction,
                            fontWeight: FontWeight.bold,
                          ),
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
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Description text
                    Text(
                      currentTarget['desc'] as String,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Navigation Buttons
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
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentStep == 3 ? 'Got it' : 'Next',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_currentStep < 3) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.arrow_forward, size: 14),
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
