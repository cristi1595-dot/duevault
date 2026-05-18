import 'package:flutter/services.dart';

class ValidationHelper {
  /// Validates the Title of a bill or document.
  /// Enforces non-empty and checks bounds to prevent rendering crashes or DB bloat.
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Title cannot be empty';
    }
    if (value.trim().length > 40) {
      return 'Title cannot exceed 40 characters';
    }
    return null;
  }

  /// Validates the Amount.
  /// Replaces commas with dots and ensures it's a strictly positive, finite, and sane number.
  static String? validateAmount(String? value, {required bool isRequired}) {
    if (value == null || value.trim().isEmpty) {
      if (isRequired) return 'Amount is required';
      return null;
    }

    final normalized = value.replaceAll(',', '.').trim();
    final parsed = double.tryParse(normalized);

    if (parsed == null) {
      return 'Please enter a valid number';
    }
    if (parsed.isNaN || parsed.isInfinite) {
      return 'Invalid number format';
    }
    if (parsed <= 0) {
      return 'Amount must be greater than zero';
    }
    if (parsed > 99999999.99) {
      return 'Amount cannot exceed 99,999,999.99';
    }
    return null;
  }

  /// Validates the Date to prevent corrupted OCR inputs or extreme inputs.
  /// Calendar boundaries are restricted strictly between Year 1900 and Year 2100.
  static String? validateDate(DateTime? date, {required bool isRequired}) {
    if (date == null) {
      if (isRequired) return 'Please select a date';
      return null;
    }
    final maxYear = DateTime.now().year + 50;
    if (date.year < 1900 || date.year > maxYear) {
      return 'Date must be between year 1900 and $maxYear';
    }
    return null;
  }

  /// Validates Notes length to prevent large memory load and slow encryption.
  static String? validateNotes(String? value) {
    if (value != null && value.length > 1000) {
      return 'Notes cannot exceed 1000 characters';
    }
    return null;
  }

  /// Quick checks for OCR outputs before filling form controllers
  static bool isAmountValid(String? value, {required bool isRequired}) {
    return validateAmount(value, isRequired: isRequired) == null;
  }

  static bool isDateValid(DateTime? date, {required bool isRequired}) {
    return validateDate(date, isRequired: isRequired) == null;
  }
}

/// Custom TextInputFormatter to block invalid amount characters, enforce zecimale (decimals) <= 2,
/// normalize commas to dots, block length > 11, and cap value at 99,999,999.99 in real-time.
class AmountInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Replace commas with dots
    final text = newValue.text.replaceAll(',', '.');

    // Enforce decimal point with at most 2 digits
    final regExp = RegExp(r'^\d*[\.]?\d{0,2}$');
    if (!regExp.hasMatch(text)) {
      return oldValue;
    }

    // Enforce maximum double limit
    final parsed = double.tryParse(text);
    if (parsed != null && parsed > 99999999.99) {
      return oldValue;
    }

    // Max length of 11 characters
    if (text.length > 11) {
      return oldValue;
    }

    // Return the sanitized value, keeping selection offset
    if (newValue.text != text) {
      return newValue.copyWith(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }

    return newValue;
  }
}
