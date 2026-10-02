import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../utils/logger.dart';

class OcrResult {
  final String rawText;
  final double? probableAmount;
  final DateTime? probableDate;
  final String? probableTitle;
  final bool isReceipt;

  OcrResult({
    required this.rawText,
    this.probableAmount,
    this.probableDate,
    this.probableTitle,
    this.isReceipt = false,
  });

  /// Formats a concise summary of what was found by OCR
  String get summary {
    final parts = <String>[];
    if (probableAmount != null) {
      parts.add('Amount: ${probableAmount!.toStringAsFixed(2)}');
    }
    if (probableDate != null) {
      parts.add('Due: ${probableDate!.day}/${probableDate!.month}/${probableDate!.year}');
    }
    if (probableTitle != null && probableTitle!.isNotEmpty) {
      parts.add('($probableTitle)');
    }
    return parts.isEmpty ? 'Details captured' : parts.join(' • ');
  }
}

class OcrService {
  static final _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  /// Process an image file and extract potential data
  /// [isDocument] helps prioritize future dates for expiry
  static Future<OcrResult> processImage(
    File imageFile, {
    bool isDocument = false,
  }) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      final String fullText = recognizedText.text;
      return parseRecognizedText(fullText, isDocument: isDocument);
    } catch (e, stack) {
      logger.e('OCR Error', error: e, stackTrace: stack);
      return OcrResult(rawText: '');
    }
  }

  /// Parses recognized raw OCR text to extract structured fields
  static OcrResult parseRecognizedText(
    String fullText, {
    bool isDocument = false,
  }) {
    final isReceipt = !isDocument && _detectReceipt(fullText);
    final amount = isDocument ? null : _extractAmount(fullText);
    final date = _extractDate(
      fullText,
      preferFuture: isDocument,
      isReceipt: isReceipt,
    );
    final title = _extractTitle(fullText);

    return OcrResult(
      rawText: fullText,
      probableAmount: amount,
      probableDate: date,
      probableTitle: title,
      isReceipt: isReceipt,
    );
  }

  /// Closes the recognizer when no longer needed
  static void dispose() {
    _textRecognizer.close();
  }

  static bool _detectReceipt(String text) {
    final upper = text.toUpperCase();
    const receiptKeywords = [
      'BON FISCAL',
      'CASA DE MARCAT',
      'CHITANTA',
      'BON NR',
      'BF:',
      'TAX RECEIPT',
      'RECEIPT',
      'CASHIER',
      'NUMERAR',
      'SCHIMB',
      'TVA',
    ];
    for (final kw in receiptKeywords) {
      if (upper.contains(kw)) return true;
    }
    return false;
  }

  static double? _parseAmountString(String str) {
    try {
      var cleaned = str.trim();
      if (cleaned.contains('.') && cleaned.contains(',')) {
        // e.g. 1.250,50 -> 1250.50 or 1,250.50 -> 1250.50
        if (cleaned.lastIndexOf(',') > cleaned.lastIndexOf('.')) {
          cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
        } else {
          cleaned = cleaned.replaceAll(',', '');
        }
      } else if (cleaned.contains(',')) {
        cleaned = cleaned.replaceAll(',', '.');
      }
      final val = double.tryParse(cleaned);
      if (val != null && val > 0 && val < 1000000) {
        return val;
      }
    } catch (_) {}
    return null;
  }

  static double? _extractAmount(String text) {
    final lines = text.split('\n');

    // High-priority bilingual keywords for total amount
    const priorityKeywords = [
      'TOTAL DE PLATA',
      'TOTAL PLATA',
      'REST DE PLATA',
      'SUMA DE PLATA',
      'VALOARE TOTALA',
      'AMOUNT DUE',
      'TOTAL DUE',
      'BALANCE DUE',
      'INVOICE TOTAL',
      'NET DE PLATA',
      'DE PLATA',
      'TOTAL',
    ];

    final RegExp amountPattern = RegExp(r'(\d{1,3}(?:[.,]\d{3})*|\d+)[.,](\d{2})');

    // 1. Check lines matching priority keywords first
    for (final kw in priorityKeywords) {
      for (int i = 0; i < lines.length; i++) {
        final upperLine = lines[i].toUpperCase();
        if (upperLine.contains(kw)) {
          // Look on this line
          final matchOnLine = amountPattern.firstMatch(lines[i]);
          if (matchOnLine != null) {
            final parsed = _parseAmountString(matchOnLine.group(0)!);
            if (parsed != null) return parsed;
          }
          // Look on immediately following line
          if (i + 1 < lines.length) {
            final matchNextLine = amountPattern.firstMatch(lines[i + 1]);
            if (matchNextLine != null) {
              final parsed = _parseAmountString(matchNextLine.group(0)!);
              if (parsed != null) return parsed;
            }
          }
        }
      }
    }

    // 2. Fallback: collect all valid amount patterns and pick the largest one
    final List<double> allAmounts = [];
    final allMatches = amountPattern.allMatches(text);
    for (final match in allMatches) {
      final parsed = _parseAmountString(match.group(0)!);
      if (parsed != null) {
        allAmounts.add(parsed);
      }
    }

    if (allAmounts.isEmpty) return null;
    allAmounts.sort();
    return allAmounts.last;
  }

  static DateTime? _extractDate(
    String text, {
    bool preferFuture = false,
    bool isReceipt = false,
  }) {
    final lines = text.split('\n');

    // Format 1: DD.MM.YYYY, DD/MM/YYYY, DD-MM-YYYY
    final RegExp dmyPattern = RegExp(
      r'\b(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})\b',
    );
    // Format 2: YYYY-MM-DD
    final RegExp ymdPattern = RegExp(
      r'\b(\d{4})[./-](\d{1,2})[./-](\d{1,2})\b',
    );

    DateTime? parseDateString(String str) {
      final dmyMatch = dmyPattern.firstMatch(str);
      if (dmyMatch != null) {
        try {
          final day = int.parse(dmyMatch.group(1)!);
          final month = int.parse(dmyMatch.group(2)!);
          final rawYear = int.parse(dmyMatch.group(3)!);
          final year = rawYear < 100 ? rawYear + 2000 : rawYear;
          if (month >= 1 && month <= 12 && day >= 1 && day <= 31 && year >= 2000 && year <= 2099) {
            return DateTime(year, month, day);
          }
        } catch (_) {}
      }

      final ymdMatch = ymdPattern.firstMatch(str);
      if (ymdMatch != null) {
        try {
          final year = int.parse(ymdMatch.group(1)!);
          final month = int.parse(ymdMatch.group(2)!);
          final day = int.parse(ymdMatch.group(3)!);
          if (month >= 1 && month <= 12 && day >= 1 && day <= 31 && year >= 2000 && year <= 2099) {
            return DateTime(year, month, day);
          }
        } catch (_) {}
      }
      return null;
    }

    // Keyword priorities for due dates
    const dueDateKeywords = [
      'DATA SCADENTA',
      'SCADENTA',
      'SCADENT LA',
      'TERMEN LIMITA',
      'TERMEN DE PLATA',
      'DATA LIMITA',
      'DUE DATE',
      'PAY BY',
      'DUE BY',
      'PAYMENT DUE',
      'VALID UNTIL',
      'EXPIRY',
    ];

    // Check lines matching due date keywords first
    for (final kw in dueDateKeywords) {
      for (int i = 0; i < lines.length; i++) {
        final upperLine = lines[i].toUpperCase();
        if (upperLine.contains(kw)) {
          final d = parseDateString(lines[i]) ??
              (i + 1 < lines.length ? parseDateString(lines[i + 1]) : null);
          if (d != null) return d;
        }
      }
    }

    // Collect all dates found in text
    final List<DateTime> dates = [];
    for (final line in lines) {
      final d = parseDateString(line);
      if (d != null) dates.add(d);
    }

    if (dates.isEmpty) return null;

    final now = DateTime.now();

    if (preferFuture) {
      final futureDates = dates.where((d) => d.isAfter(now)).toList();
      if (futureDates.isNotEmpty) {
        futureDates.sort();
        return futureDates.last;
      }
    }

    if (isReceipt) {
      // For receipts, the date is almost always the issue date (most recent or today)
      dates.sort();
      return dates.last;
    }

    // Default: find future date if available, else most recent
    final futureDates = dates.where((d) => d.isAfter(now.subtract(const Duration(days: 1)))).toList();
    if (futureDates.isNotEmpty) {
      futureDates.sort();
      return futureDates.first; // nearest upcoming due date
    }

    dates.sort();
    return dates.last;
  }

  static String? _extractTitle(String text) {
    final upperText = text.toUpperCase();

    // Comprehensive Romanian & International utilities, services and retailers
    final Map<String, List<String>> keywords = {
      // Supermarkets & Retail (Receipts)
      'Lidl': ['LIDL'],
      'Kaufland': ['KAUFLAND'],
      'Carrefour': ['CARREFOUR'],
      'Mega Image': ['MEGA IMAGE'],
      'Auchan': ['AUCHAN'],
      'Profi': ['PROFI'],
      'Penny': ['PENNY'],
      'Altex': ['ALTEX'],
      'eMAG': ['EMAG', 'DANTE INTERNATIONAL'],
      'Dedeman': ['DEDEMAN'],
      'Hornbach': ['HORNBACH'],
      'Leroy Merlin': ['LEROY MERLIN'],
      'Decathlon': ['DECATHLON'],
      'Ikea': ['IKEA'],
      'OMV': ['OMV'],
      'Petrom': ['PETROM'],
      'Rompetrol': ['ROMPETROL'],
      'Mol': ['MOL ROMANIA'],

      // Utilities & Telecoms (Bills)
      'Hidroelectrica': ['HIDROELECTRICA'],
      'Electrica Furnizare': ['ELECTRICA FURNIZARE', 'ELECTRICA'],
      'Enel / PPC': ['ENEL', 'PPC ENERGY'],
      'E.ON': ['E.ON', 'EON ENERGIE'],
      'Engie': ['ENGIE'],
      'Digi (RCS & RDS)': ['DIGI', 'RCS & RDS', 'RCS-RDS'],
      'Orange': ['ORANGE'],
      'Vodafone': ['VODAFONE'],
      'Telekom': ['TELEKOM'],
      'Apa Nova': ['APA NOVA'],
      'Apavital': ['APAVITAL'],
      'Raja': ['RAJA'],

      // Documents
      'Passport': ['PASAPORT', 'PASSPORT', 'REPUBLICA ROMANIA'],
      'ID Card': ['CARTE IDENTITATE', 'IDENTITY CARD', 'CNP', 'BULLETIN'],
      'Driver License': ['PERMIS CONDUCERE', 'DRIVING LICENCE'],
      'Health Card': ['CARD SANATATE', 'HEALTH CARD'],
      'Contract': ['CONTRACT', 'CONVENTIE'],
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
