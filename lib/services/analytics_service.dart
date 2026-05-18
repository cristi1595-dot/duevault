import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/logger.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Logs whether the user is running in Guest mode or Cloud/Firebase mode.
  /// Sets a user property and logs an event.
  Future<void> logUserType(bool isGuest) async {
    try {
      final userType = isGuest ? 'guest' : 'cloud';
      logger.i('Analytics: Setting user_type property to: $userType');
      await _analytics.setUserProperty(name: 'user_type', value: userType);
      await _analytics.logEvent(
        name: 'user_type_selected',
        parameters: {'user_type': userType},
      );
    } catch (e, stack) {
      logger.e('Analytics: Error logging user type', error: e, stackTrace: stack);
    }
  }

  /// Logs when a new item (Bill or Document) is added.
  Future<void> logItemAdded(String category) async {
    try {
      logger.i('Analytics: Logging item_added event with category: $category');
      await _analytics.logEvent(
        name: 'item_added',
        parameters: {'category': category},
      );
    } catch (e, stack) {
      logger.e('Analytics: Error logging item added', error: e, stackTrace: stack);
    }
  }

  /// Logs user configuration and settings modifications.
  Future<void> logSettingsChanged(String settingName, dynamic value) async {
    try {
      final String formattedValue = value.toString();
      logger.i('Analytics: Logging settings_changed event. Name: $settingName, Value: $formattedValue');
      await _analytics.logEvent(
        name: 'settings_changed',
        parameters: {
          'setting_name': settingName,
          'value': formattedValue,
        },
      );
    } catch (e, stack) {
      logger.e('Analytics: Error logging settings changed', error: e, stackTrace: stack);
    }
  }
}
