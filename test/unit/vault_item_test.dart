import 'package:flutter_test/flutter_test.dart';
import 'package:duevault_app/models/vault_item.dart';

void main() {
  group('VaultItem Tests', () {
    group('validate() validation barrier', () {
      test('passes for a valid Bill', () {
        final bill = VaultItem()
          ..title = 'Electric Bill'
          ..category = 'Utilities'
          ..itemType = 'Bill'
          ..amount = 120.50
          ..dueDate = DateTime(2025, 6, 15)
          ..notes = 'Regular monthly bill'
          ..attachedFiles = ['receipt.pdf'];

        expect(() => bill.validate(), returnsNormally);
      });

      test('passes for a valid Document without amount or dueDate', () {
        final doc = VaultItem()
          ..title = 'Passport ID'
          ..category = 'Identity'
          ..itemType = 'Document'
          ..amount = null
          ..dueDate = null
          ..attachedFiles = ['passport.jpg'];

        expect(() => doc.validate(), returnsNormally);
      });

      test('throws for empty title', () {
        final item = VaultItem()
          ..title = '   '
          ..category = 'Utilities'
          ..itemType = 'Bill'
          ..amount = 50.0
          ..dueDate = DateTime(2025, 6, 1);

        expect(() => item.validate(), throwsA(anyOf(isA<ValidationError>(), isA<AssertionError>())));
      });

      test('throws for title exceeding 40 characters', () {
        final item = VaultItem()
          ..title = 'A' * 41
          ..category = 'Utilities'
          ..itemType = 'Bill'
          ..amount = 50.0
          ..dueDate = DateTime(2025, 6, 1);

        expect(() => item.validate(), throwsA(anyOf(isA<ValidationError>(), isA<AssertionError>())));
      });

      test('throws for empty category', () {
        final item = VaultItem()
          ..title = 'Gas Bill'
          ..category = ''
          ..itemType = 'Bill'
          ..amount = 50.0
          ..dueDate = DateTime(2025, 6, 1);

        expect(() => item.validate(), throwsA(anyOf(isA<ValidationError>(), isA<AssertionError>())));
      });

      test('throws for invalid itemType', () {
        final item = VaultItem()
          ..title = 'Item'
          ..category = 'Utilities'
          ..itemType = 'Invoice' // Invalid: must be Bill or Document
          ..amount = 50.0
          ..dueDate = DateTime(2025, 6, 1);

        expect(() => item.validate(), throwsA(anyOf(isA<ValidationError>(), isA<AssertionError>())));
      });

      test('throws if Bill has null or non-positive amount', () {
        final item1 = VaultItem()
          ..title = 'Bill'
          ..category = 'Utilities'
          ..itemType = 'Bill'
          ..amount = null
          ..dueDate = DateTime(2025, 6, 1);
        expect(() => item1.validate(), throwsA(anyOf(isA<ValidationError>(), isA<AssertionError>())));

        final item2 = VaultItem()
          ..title = 'Bill'
          ..category = 'Utilities'
          ..itemType = 'Bill'
          ..amount = 0.0
          ..dueDate = DateTime(2025, 6, 1);
        expect(() => item2.validate(), throwsA(anyOf(isA<ValidationError>(), isA<AssertionError>())));

        final item3 = VaultItem()
          ..title = 'Bill'
          ..category = 'Utilities'
          ..itemType = 'Bill'
          ..amount = -10.0
          ..dueDate = DateTime(2025, 6, 1);
        expect(() => item3.validate(), throwsA(anyOf(isA<ValidationError>(), isA<AssertionError>())));
      });

      test('throws if Bill has no dueDate', () {
        final item = VaultItem()
          ..title = 'Bill'
          ..category = 'Utilities'
          ..itemType = 'Bill'
          ..amount = 25.0
          ..dueDate = null;

        expect(() => item.validate(), throwsA(anyOf(isA<ValidationError>(), isA<AssertionError>())));
      });

      test('throws if date is outside 1900-2100 range', () {
        final item = VaultItem()
          ..title = 'Historical'
          ..category = 'Document'
          ..itemType = 'Document'
          ..dueDate = DateTime(1850, 1, 1);

        expect(() => item.validate(), throwsA(anyOf(isA<ValidationError>(), isA<AssertionError>())));
      });

      test('throws if non-encrypted notes exceed 1000 characters', () {
        final item = VaultItem()
          ..title = 'Document'
          ..category = 'Identity'
          ..itemType = 'Document'
          ..notes = 'N' * 1001;

        expect(() => item.validate(), throwsA(anyOf(isA<ValidationError>(), isA<AssertionError>())));
      });

      test('allows encrypted notes even if longer than 1000 characters', () {
        final item = VaultItem()
          ..title = 'Document'
          ..category = 'Identity'
          ..itemType = 'Document'
          ..notes = 'encrypted:${'A' * 1200}';

        expect(() => item.validate(), returnsNormally);
      });

      test('throws if attachments exceed 5', () {
        final item = VaultItem()
          ..title = 'Document'
          ..category = 'Identity'
          ..itemType = 'Document'
          ..attachedFiles = ['1.pdf', '2.pdf', '3.pdf', '4.pdf', '5.pdf', '6.pdf'];

        expect(() => item.validate(), throwsA(anyOf(isA<ValidationError>(), isA<AssertionError>())));
      });
    });

    group('Serialization toMap / fromMap', () {
      test('correctly serializes to Map and deserializes back', () {
        final original = VaultItem()
          ..uuid = 'test-uuid-12345'
          ..ownerId = 'user_abc'
          ..title = 'Netflix Premium'
          ..category = 'Subscriptions'
          ..amount = 15.99
          ..dueDate = DateTime(2025, 7, 20, 14, 30)
          ..isPaid = true
          ..isArchived = false
          ..isDeleted = false
          ..itemType = 'Bill'
          ..recurrence = 'Monthly'
          ..directDebit = true
          ..notes = 'Family plan'
          ..isSample = false
          ..lastModified = DateTime(2025, 6, 1, 10, 0)
          ..attachedFiles = ['netflix_receipt.pdf']
          ..cloudFileChecksums = ['d41d8cd98f00b204e9800998ecf8427e']
          ..originalDueDay = 20;

        final map = original.toMap();

        expect(map['uuid'], equals('test-uuid-12345'));
        expect(map['ownerId'], equals('user_abc'));
        expect(map['title'], equals('Netflix Premium'));
        expect(map['category'], equals('Subscriptions'));
        expect(map['amount'], equals(15.99));
        expect(map['isPaid'], isTrue);
        expect(map['recurrence'], equals('Monthly'));
        expect(map['directDebit'], isTrue);
        expect(map['originalDueDay'], equals(20));

        final reconstructed = VaultItem.fromMap(map);

        expect(reconstructed.uuid, equals(original.uuid));
        expect(reconstructed.ownerId, equals(original.ownerId));
        expect(reconstructed.title, equals(original.title));
        expect(reconstructed.category, equals(original.category));
        expect(reconstructed.amount, equals(original.amount));
        expect(reconstructed.dueDate?.toIso8601String(), equals(original.dueDate?.toIso8601String()));
        expect(reconstructed.isPaid, equals(original.isPaid));
        expect(reconstructed.isArchived, equals(original.isArchived));
        expect(reconstructed.isDeleted, equals(original.isDeleted));
        expect(reconstructed.itemType, equals(original.itemType));
        expect(reconstructed.recurrence, equals(original.recurrence));
        expect(reconstructed.directDebit, equals(original.directDebit));
        expect(reconstructed.notes, equals(original.notes));
        expect(reconstructed.isSample, equals(original.isSample));
        expect(reconstructed.attachedFiles, equals(original.attachedFiles));
        expect(reconstructed.cloudFileChecksums, equals(original.cloudFileChecksums));
        expect(reconstructed.originalDueDay, equals(original.originalDueDay));
      });

      test('fromMap provides safe defaults when map has missing or null values', () {
        final reconstructed = VaultItem.fromMap({});

        expect(reconstructed.uuid, isEmpty);
        expect(reconstructed.ownerId, equals('local_user'));
        expect(reconstructed.title, isEmpty);
        expect(reconstructed.category, equals('Utilities'));
        expect(reconstructed.amount, isNull);
        expect(reconstructed.dueDate, isNull);
        expect(reconstructed.isPaid, isFalse);
        expect(reconstructed.isArchived, isFalse);
        expect(reconstructed.isDeleted, isFalse);
        expect(reconstructed.recurrence, equals('None'));
        expect(reconstructed.directDebit, isFalse);
        expect(reconstructed.attachedFiles, isEmpty);
        expect(reconstructed.cloudFileChecksums, isEmpty);
      });
    });
  });
}
