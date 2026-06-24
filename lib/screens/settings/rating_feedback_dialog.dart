import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

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
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      elevation: 8,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: MediaQuery.of(context).size.width * 0.88,
        constraints: const BoxConstraints(maxHeight: 520),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dynamic Icon Header
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (_selectedRating >= 4 ? AppTheme.primaryAction : AppTheme.warningYellow).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _selectedRating == 0
                      ? Icons.star_border_rounded
                      : _selectedRating >= 4
                          ? Icons.favorite_rounded
                          : Icons.rate_review_rounded,
                  color: _selectedRating >= 4 ? AppTheme.primaryAction : AppTheme.warningYellow,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                _selectedRating == 0
                    ? 'Enjoying DueVault?'
                    : _selectedRating >= 4
                        ? 'We love you back!'
                        : 'Help us improve',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                _selectedRating == 0
                    ? 'Tap a star to rate your experience with us.'
                    : _selectedRating >= 4
                        ? 'Would you mind sharing a quick rating on the Google Play Store to support our development?'
                        : 'Please tell us what we can do better so we can make it right for you.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

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
                            setState(() {
                              _selectedRating = starValue;
                            });
                            widget.onRated(starValue);
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: AnimatedScale(
                        scale: isLit ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: Icon(
                          isLit ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: isLit ? Colors.amber : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
                          size: 42,
                        ),
                      ),
                    ),
                  );
                }),
              ),

              // Feedback Form (1-3 stars)
              if (_selectedRating > 0 && _selectedRating <= 3 && !_submittedFeedback) ...[
                const SizedBox(height: 24),
                TextField(
                  controller: _feedbackController,
                  maxLines: 3,
                  maxLength: 500,
                  style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Share your thoughts, suggestions, or issues...',
                    hintStyle: TextStyle(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: theme.scaffoldBackgroundColor,
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: theme.dividerColor.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: theme.dividerColor.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryAction,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () async {
                                setState(() {
                                  _isSubmitting = true;
                                });
                                widget.onFeedbackSubmitted(_feedbackController.text);
                                setState(() {
                                  _isSubmitting = false;
                                  _submittedFeedback = true;
                                });
                                // Keep it briefly open to show completion animation
                                await Future.delayed(const Duration(milliseconds: 1500));
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppTheme.primaryAction,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],

              // Promotion Row for Play Store (4-5 stars)
              if (_selectedRating >= 4) ...[
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Not now',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onFeedbackSubmitted('STORES_REVIEW');
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppTheme.primaryAction,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Rate App',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Success Message
              if (_submittedFeedback) ...[
                const SizedBox(height: 24),
                AnimatedOpacity(
                  opacity: _submittedFeedback ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppTheme.safeGreen, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Thank you for your response!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.safeGreen,
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
