import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/vault_repository.dart';
import '../providers/vault_provider.dart';
import '../utils/logger.dart';
import '../screens/settings/rating_feedback_dialog.dart';

class AppReviewService {
  final VaultRepository _repository;
  final InAppReview _inAppReview = InAppReview.instance;

  AppReviewService(this._repository);

  /// Increment the action count. If milestone (e.g. 3) is reached,
  /// trigger automatic prompt checks.
  Future<void> incrementActionCounter(WidgetRef ref, BuildContext context) async {
    try {
      final config = await _repository.getConfig();
      if (config.hasRatedApp) return;

      config.successfulActionsCount++;
      await _repository.updateConfig(config);
      logger.i('AppReviewService: Actions count incremented to ${config.successfulActionsCount}');

      if (config.successfulActionsCount >= 3) {
        // Run automatic trigger check in a post-frame callback to avoid UI build issues
        WidgetsBinding.instance.addPostFrameCallback((_) {
          checkAndPromptAutomaticReview(ref, context);
        });
      }
    } catch (e) {
      logger.e('AppReviewService: Failed to increment action counter', error: e);
    }
  }

  /// Automatically prompts the user if they qualify
  Future<void> checkAndPromptAutomaticReview(WidgetRef ref, BuildContext context) async {
    try {
      final config = await _repository.getConfig();
      if (config.hasRatedApp) return;

      // Only prompt if they have performed at least 3 successful actions
      if (config.successfulActionsCount < 3) return;

      final lastPrompt = config.lastPromptedDate;
      final now = DateTime.now();

      // Cooldown of 30 days between automatic prompts
      if (lastPrompt == null || now.difference(lastPrompt).inDays >= 30) {
        logger.i('AppReviewService: Qualifying user for automatic review. Triggering prompt...');
        
        // Update prompt date first to avoid double prompts
        config.lastPromptedDate = now;
        await _repository.updateConfig(config);

        if (context.mounted) {
          await showRatingDialog(context);
        }
      }
    } catch (e, stack) {
      logger.e('AppReviewService: Error checking automatic review condition', error: e, stackTrace: stack);
    }
  }

  /// Present the custom dialog manually or automatically
  Future<void> showRatingDialog(BuildContext context) async {
    int ratingValue = 0;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => RatingFeedbackDialog(
        onRated: (rating) {
          ratingValue = rating;
        },
        onFeedbackSubmitted: (feedbackText) async {
          if (feedbackText == 'STORES_REVIEW') {
            // Trigger 4-5 stars Play Store rating
            await _triggerStoreRating();
            
            // Mark rated in config
            final config = await _repository.getConfig();
            config.hasRatedApp = true;
            await _repository.updateConfig(config);
          } else {
            // Trigger 1-3 stars in-app feedback submission to Firestore
            await _submitFeedbackToCloud(ratingValue, feedbackText);
          }
        },
      ),
    );
  }

  /// Trigger Google Play Store/App Store review sheet or fall back to store page
  Future<void> _triggerStoreRating() async {
    try {
      final isAvailable = await _inAppReview.isAvailable();
      if (isAvailable) {
        logger.i('AppReviewService: Launching in-app review sheet');
        await _inAppReview.requestReview();
      } else {
        logger.i('AppReviewService: in_app_review not available. Falling back to Store listing');
        await _inAppReview.openStoreListing();
      }
    } catch (e, stack) {
      logger.e('AppReviewService: Failed to trigger store review flow', error: e, stackTrace: stack);
      // Fallback
      try {
        await _inAppReview.openStoreListing();
      } catch (ex) {
        logger.e('AppReviewService: Store redirect fallback failed', error: ex);
      }
    }
  }

  /// Submits negative/neutral (1-3 stars) feedback to Firestore collection 'feedback'
  Future<void> _submitFeedbackToCloud(int rating, String text) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final data = {
        'rating': rating,
        'feedback': text,
        'userId': user?.uid ?? 'guest_user',
        'userEmail': user?.email ?? 'guest@duevault.local',
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'Android',
      };

      logger.i('AppReviewService: Submitting feedback to Firestore: $data');
      await FirebaseFirestore.instance.collection('feedback').add(data);
    } catch (e, stack) {
      logger.w('AppReviewService: Failed to upload feedback to Firestore (offline or disabled)', error: e, stackTrace: stack);
    }
  }
}

/// Riverpod provider for AppReviewService
final appReviewServiceProvider = Provider<AppReviewService>((ref) {
  final repository = ref.watch(vaultRepositoryProvider);
  return AppReviewService(repository);
});
