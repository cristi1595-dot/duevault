import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../utils/logger.dart';


class OcrResult {
  final String rawText;
  final double? probableAmount;
  final DateTime? probableDate;
  final String? probableTitle;

  OcrResult({
    required this.rawText,
    this.probableAmount,
    this.probableDate,
    this.probableTitle,
  });
}

class OcrService {
  static final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Process an image file and extract potential data
  /// [isDocument] helps prioritize future dates for expiry
  static Future<OcrResult> processImage(File imageFile, {bool isDocument = false}) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      final String fullText = recognizedText.text;
      
      // Attempt to extract amount and date
      final amount = isDocument ? null : _extractAmount(fullText);
      final date = _extractDate(fullText, preferFuture: isDocument);
      final title = _extractTitle(fullText);

      return OcrResult(
        rawText: fullText,
        probableAmount: amount,
        probableDate: date,
        probableTitle: title,
      );
    } catch (e, stack) {
      logger.e('OCR Error', error: e, stackTrace: stack);
      return OcrResult(rawText: '');
    }

  }

  /// Closes the recognizer when no longer needed
  static void dispose() {
    _textRecognizer.close();
  }

  static double? _extractAmount(String text) {
    // Look for numbers that look like currency/amounts (e.g., 123.45 or 123,45)
    final RegExp amountRegex = RegExp(r'\b\d{1,5}[.,]\d{2}\b');
    final matches = amountRegex.allMatches(text);
    
    if (matches.isEmpty) return null;

    final List<double> amounts = [];
    for (final match in matches) {
      final matchStr = match.group(0)!;
      // Convert comma to dot for parsing if used as decimal separator
      final parsedStr = matchStr.replaceAll(',', '.');
      final val = double.tryParse(parsedStr);
      if (val != null && val > 0) {
        amounts.add(val);
      }
    }

    if (amounts.isEmpty) return null;

    // Usually, the total amount is the largest number on the bill
    amounts.sort();
    return amounts.last;
  }

  static DateTime? _extractDate(String text, {bool preferFuture = false}) {
    // Look for common date formats: DD.MM.YYYY, DD/MM/YYYY, DD-MM-YYYY
    final RegExp dateRegex = RegExp(r'\b(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})\b');
    final matches = dateRegex.allMatches(text);

    final List<DateTime> dates = [];
    final now = DateTime.now();

    for (final match in matches) {
      try {
        final dayStr = match.group(1)!;
        final monthStr = match.group(2)!;
        final yearStr = match.group(3)!;

        final int day = int.parse(dayStr);
        final int month = int.parse(monthStr);
        final int yearRaw = int.parse(yearStr);
        final int year = yearRaw < 100 ? yearRaw + 2000 : yearRaw;

        if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
          dates.add(DateTime(year, month, day));
        }
      } catch (_) {}
    }

    if (dates.isEmpty) return null;

    if (preferFuture) {
      // Find the furthest future date (likely expiry)
      final futureDates = dates.where((d) => d.isAfter(now)).toList();
      if (futureDates.isNotEmpty) {
        futureDates.sort();
        return futureDates.last;
      }
    }

    // Otherwise find the most recent date (likely issuance/due date)
    dates.sort();
    return dates.last;
  }

  static String? _extractTitle(String text) {
    final upperText = text.toUpperCase();
    
    // Keywords for auto-title
    final Map<String, List<String>> keywords = {
      'Passport': ['PASAPORT', 'PASSPORT', 'REPUBLICA ROMANIA'],
      'ID Card': ['CARTE IDENTITATE', 'IDENTITY CARD', 'CNP', 'BULLETIN'],
      'Driver License': ['PERMIS CONDUCERE', 'DRIVING LICENCE'],
      'Contract': ['CONTRACT', 'CONVENTIE'],
      'Electricity Bill': ['ENEL', 'HIDROELECTRICA', 'ELECTRICA', 'ENERGIE'],
      'Gas Bill': ['E.ON', 'ENGIE', 'GAZE', 'NATURAL GAS'],
      'Water Bill': ['APA NOVA', 'APAVITAL', 'RAJA'],
      'Internet Bill': ['DIGI', 'ORANGE', 'VODAFONE', 'TELEKOM'],
      'Health Card': ['CARD SANATATE', 'HEALTH CARD'],
    };

    for (var entry in keywords.entries) {
      for (var word in entry.value) {
        if (upperText.contains(word)) {
          return entry.key;
        }
      }
    }

    return null;
  }
}
