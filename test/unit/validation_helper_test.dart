import 'package:flutter_test/flutter_test.dart';
import 'package:duevault_app/utils/validation_helper.dart';

void main() {
  group('ValidationHelper Tests', () {
    group('validateAmount', () {
      test('returns error when required and amount is null or empty', () {
        expect(
          ValidationHelper.validateAmount(null, isRequired: true),
          equals('Amount is required'),
        );
        expect(
          ValidationHelper.validateAmount('', isRequired: true),
          equals('Amount is required'),
        );
        expect(
          ValidationHelper.validateAmount('   ', isRequired: true),
          equals('Amount is required'),
        );
      });

      test('returns null when not required and amount is null or empty', () {
        expect(
          ValidationHelper.validateAmount(null, isRequired: false),
          isNull,
        );
        expect(
          ValidationHelper.validateAmount('', isRequired: false),
          isNull,
        );
        expect(
          ValidationHelper.validateAmount('   ', isRequired: false),
          isNull,
        );
      });

      test('returns error for invalid number characters', () {
        expect(
          ValidationHelper.validateAmount('abc', isRequired: true),
          equals('Please enter a valid number'),
        );
        expect(
          ValidationHelper.validateAmount('12.34.56', isRequired: true),
          equals('Please enter a valid number'),
        );
        expect(
          ValidationHelper.validateAmount('NaN', isRequired: true),
          isNotNull,
        );
      });

      test('returns error for non-positive amounts', () {
        expect(
          ValidationHelper.validateAmount('0', isRequired: true),
          equals('Amount must be greater than zero'),
        );
        expect(
          ValidationHelper.validateAmount('-15.50', isRequired: true),
          equals('Amount must be greater than zero'),
        );
        expect(
          ValidationHelper.validateAmount('0.00', isRequired: true),
          equals('Amount must be greater than zero'),
        );
      });

      test('returns error when amount exceeds maximum limit', () {
        expect(
          ValidationHelper.validateAmount('100000000', isRequired: true),
          equals('Amount cannot exceed 99,999,999.99'),
        );
      });

      test('accepts valid amounts with dot or comma separator', () {
        expect(
          ValidationHelper.validateAmount('100.50', isRequired: true),
          isNull,
        );
        expect(
          ValidationHelper.validateAmount('100,50', isRequired: true),
          isNull,
        );
        expect(
          ValidationHelper.validateAmount('0.01', isRequired: true),
          isNull,
        );
        expect(
          ValidationHelper.validateAmount('99999999.99', isRequired: true),
          isNull,
        );
      });

      test('isAmountValid helper works consistently', () {
        expect(ValidationHelper.isAmountValid('50.00', isRequired: true), isTrue);
        expect(ValidationHelper.isAmountValid('', isRequired: true), isFalse);
        expect(ValidationHelper.isAmountValid('', isRequired: false), isTrue);
        expect(ValidationHelper.isAmountValid('-10', isRequired: true), isFalse);
      });
    });

    group('validateTitle', () {
      test('rejects empty or whitespace title', () {
        expect(ValidationHelper.validateTitle(null), equals('Title cannot be empty'));
        expect(ValidationHelper.validateTitle(''), equals('Title cannot be empty'));
        expect(ValidationHelper.validateTitle('   '), equals('Title cannot be empty'));
      });

      test('rejects title longer than 40 characters', () {
        final longTitle = 'A' * 41;
        expect(
          ValidationHelper.validateTitle(longTitle),
          equals('Title cannot exceed 40 characters'),
        );
      });

      test('accepts valid title within 40 characters', () {
        expect(ValidationHelper.validateTitle('Electricity Bill'), isNull);
        expect(ValidationHelper.validateTitle('A' * 40), isNull);
      });
    });

    group('validateDate', () {
      test('handles required / optional dates', () {
        expect(ValidationHelper.validateDate(null, isRequired: true), equals('Please select a date'));
        expect(ValidationHelper.validateDate(null, isRequired: false), isNull);
      });

      test('validates year boundaries', () {
        expect(
          ValidationHelper.validateDate(DateTime(1899, 1, 1), isRequired: true),
          contains('Date must be between year 1900'),
        );
        expect(
          ValidationHelper.validateDate(DateTime(2150, 1, 1), isRequired: true),
          contains('Date must be between year 1900'),
        );
        expect(
          ValidationHelper.validateDate(DateTime(2025, 5, 20), isRequired: true),
          isNull,
        );
      });
    });

    group('validateNotes', () {
      test('accepts null or short notes', () {
        expect(ValidationHelper.validateNotes(null), isNull);
        expect(ValidationHelper.validateNotes('Short note'), isNull);
      });

      test('rejects notes exceeding 1000 characters', () {
        final longNotes = 'X' * 1001;
        expect(
          ValidationHelper.validateNotes(longNotes),
          equals('Notes cannot exceed 1000 characters'),
        );
      });
    });
  });
}
