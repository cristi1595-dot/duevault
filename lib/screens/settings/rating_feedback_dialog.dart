import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class RatingFeedbackDialog extends StatefulWidget {
  final ValueChanged<int> onRated;
  final ValueChanged<String> onFeedbackSubmitted;

  const RatingFeedbackDialog({
    super.key,
    required this.onRated,
    required this.onFeedbackSubmitted,
  });

  @override
  State<RatingFeedbackDialog> createState() => _RatingFeedbackDialogState();
}

class _RatingFeedbackDialogState extends State<RatingFeedbackDialog> {
  int _selectedRating = 0;
  final _feedbackController = TextEditingController();
  bool _submittedFeedback = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryEmerald = isDark ? AppColors.emerald500 : AppColors.emerald600;

    return Dialog(
      backgroundColor: AppColors.surface(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(
          color: AppColors.border(isDark),
          width: 1.0,
        ),
      ),
      elevation: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: MediaQuery.of(context).size.width * 0.88,
        constraints: const BoxConstraints(maxHeight: 520),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dynamic Icon Header
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: (_selectedRating >= 4 ? primaryEmerald : AppColors.warningAmber500).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  _selectedRating == 0
                      ? Icons.star_border_rounded
                      : _selectedRating >= 4
                          ? Icons.favorite_rounded
                          : Icons.rate_review_rounded,
                  color: _selectedRating >= 4 ? primaryEmerald : AppColors.warningAmber500,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Title
              Text(
                _selectedRating == 0
                    ? 'Enjoying DueVault?'
                    : _selectedRating >= 4
                        ? 'We love you back!'
                        : 'Help us improve',
                textAlign: TextAlign.center,
                style: AppTypography.headlineMedium(AppColors.textPrimary(isDark)).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 19,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // Description
              Text(
                _selectedRating == 0
                    ? 'Tap a star to rate your experience with us.'
                    : _selectedRating >= 4
                        ? 'Would you mind sharing a quick rating on the Google Play Store to support our development?'
                        : 'Please tell us what we can do better so we can make it right for you.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall(AppColors.textSecondary(isDark)).copyWith(
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Interactive Stars Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starValue = index + 1;
                  final isLit = starValue <= _selectedRating;
                  return GestureDetector(
                    onTap: _submittedFeedback || _isSubmitting
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _selectedRating = starValue;
                            });
                            widget.onRated(starValue);
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: AnimatedScale(
                        scale: isLit ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: Icon(
                          isLit ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: isLit ? AppColors.warningAmber500 : AppColors.textMuted(isDark),
                          size: 38,
                        ),
                      ),
                    ),
                  );
                }),
              ),

              // Feedback Form (1-3 stars)
              if (_selectedRating > 0 && _selectedRating <= 3 && !_submittedFeedback) ...[
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _feedbackController,
                  maxLines: 3,
                  maxLength: 500,
                  style: TextStyle(
                    color: AppColors.textPrimary(isDark),
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Share your thoughts, suggestions, or issues...',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted(isDark),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceElevated(isDark),
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(
                        color: AppColors.border(isDark),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(
                        color: AppColors.border(isDark),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(
                        color: primaryEmerald,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                Navigator.pop(context);
                              },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.textSecondary(isDark),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () async {
                                await HapticFeedback.mediumImpact();
                                setState(() {
                                  _isSubmitting = true;
                                });
                                widget.onFeedbackSubmitted(_feedbackController.text);
                                setState(() {
                                  _isSubmitting = false;
                                  _submittedFeedback = true;
                                });
                                await Future.delayed(const Duration(milliseconds: 1500));
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: primaryEmerald,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Send Feedback',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],

              // Promotion Row for Play Store (4-5 stars)
              if (_selectedRating >= 4) ...[
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        child: Text(
                          'Not now',
                          style: TextStyle(
                            color: AppColors.textSecondary(isDark),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                          widget.onFeedbackSubmitted('STORES_REVIEW');
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: primaryEmerald,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        child: const Text(
                          'Rate App',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Success Message
              if (_submittedFeedback) ...[
                const SizedBox(height: AppSpacing.md),
                AnimatedOpacity(
                  opacity: _submittedFeedback ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, color: primaryEmerald, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Thank you for your response!',
                        style: TextStyle(
                          color: primaryEmerald,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
