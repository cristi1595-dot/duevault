import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

/// Senior Security Fix: Silences all logs in Release mode to prevent data leaks via adb logs.
class ProductionLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (kReleaseMode) return false;
    return true;
  }
}

final logger = Logger(
  filter: ProductionLogFilter(),
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);
