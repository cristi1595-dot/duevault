import 'package:isar_community/isar.dart';
part 'vault_item.g.dart';

@collection
class VaultItem {
  Id id = Isar.autoIncrement;

  @Index()
  String ownerId = 'local_user';

  @Index(unique: true)
  String uuid = '';
  @Index()
  bool isPaid = false;
  @Index()
  bool isArchived = false;

  @Index()
  bool isDeleted = false; // Soft delete for multi-device sync

  @Index()
  int? originalDueDay; // Original day of month for recurring bills

  List<String> cloudFileIds = []; // IDs of files in Google Drive for sync
  List<String> cloudFileChecksums =
      []; // MD5 hashes of files for content-based sync
  bool wasSynced = false; // Track if item has reached the cloud

  DateTime lastModified = DateTime.now();

  @Index()
  String? itemType; // 'Bill' or 'Document'

  // Smart Helpers
  @ignore
  bool get isExpired {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return dueDate!.isBefore(today);
  }

  @ignore
  bool get isOverdue => isExpired && !isPaid;

  String category = 'Utilities';
  String title = '';

  double? amount; // Nullable for Documents

  @Index()
  DateTime? dueDate;

  bool isSample = false;

  String recurrence = 'None'; // "None", "Monthly", "Yearly"
  bool directDebit = false;

  String? notes;
  List<String> attachedFiles = []; // List of local paths or Google Drive IDs

  void validate() {
    // Assert barriers for early catch in development
    assert(title.trim().isNotEmpty, 'Title cannot be empty');
    assert(title.trim().length <= 40, 'Title cannot exceed 40 characters');
    assert(category.trim().isNotEmpty, 'Category cannot be empty');
    assert(itemType == 'Bill' || itemType == 'Document', 'Invalid itemType: must be Bill or Document');

    if (itemType == 'Bill') {
      assert(amount != null, 'Amount is required for Bills');
      assert(amount! > 0 && amount!.isFinite && amount! <= 99999999.99, 'Amount must be positive, finite, and under 100,000,000');
      assert(dueDate != null, 'DueDate is required for Bills');
    } else {
      if (amount != null) {
        assert(amount! > 0 && amount!.isFinite && amount! <= 99999999.99, 'Amount must be positive and finite');
      }
    }

    if (dueDate != null) {
      assert(dueDate!.year >= 1900 && dueDate!.year <= 2100, 'Date must be between 1900 and 2100');
    }

    if (notes != null && !notes!.startsWith('encrypted:')) {
      assert(notes!.length <= 1000, 'Notes cannot exceed 1000 characters');
    }

    assert(attachedFiles.length <= 5, 'Maximum of 5 attachments allowed');

    // Runtime barriers for production database preservation
    if (itemType != 'Bill' && itemType != 'Document') {
      throw ValidationError('Invalid item type: must be Bill or Document.');
    }
    if (title.trim().isEmpty) {
      throw ValidationError('Title cannot be empty.');
    }
    if (title.trim().length > 40) {
      throw ValidationError('Title cannot exceed 40 characters.');
    }
    if (category.trim().isEmpty) {
      throw ValidationError('Category cannot be empty.');
    }
    if (itemType == 'Bill') {
      if (amount == null) {
        throw ValidationError('Amount is required for Bills.');
      }
      if (amount! <= 0 || amount!.isNaN || amount!.isInfinite || amount! > 99999999.99) {
        throw ValidationError('Amount must be a positive finite number under 100,000,000.');
      }
      if (dueDate == null) {
        throw ValidationError('Due date is required for Bills.');
      }
    } else {
      if (amount != null && (amount! <= 0 || amount!.isNaN || amount!.isInfinite || amount! > 99999999.99)) {
        throw ValidationError('Amount must be a positive finite number under 100,000,000.');
      }
    }
    if (dueDate != null) {
      if (dueDate!.year < 1900 || dueDate!.year > 2100) {
        throw ValidationError('Date must be between 1900 and 2100.');
      }
    }
    if (notes != null && !notes!.startsWith('encrypted:') && notes!.length > 1000) {
      throw ValidationError('Notes cannot exceed 1000 characters.');
    }
    if (attachedFiles.length > 5) {
      throw ValidationError('Maximum of 5 attachments allowed.');
    }
  }

  // --- Firestore Serialization (Senior Logic) ---

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'ownerId': ownerId,
      'title': title,
      'category': category,
      'amount': amount,
      'dueDate': dueDate?.toIso8601String(),
      'isPaid': isPaid,
      'isArchived': isArchived,
      'isDeleted': isDeleted,
      'itemType': itemType,
      'recurrence': recurrence,
      'directDebit': directDebit,
      'notes': notes,
      'isSample': isSample,
      'lastModified': lastModified.toIso8601String(),
      'attachedFiles': attachedFiles,
      'cloudFileChecksums': cloudFileChecksums,
      'originalDueDay': originalDueDay,
    };
  }

  static VaultItem fromMap(Map<String, dynamic> map) {
    final item = VaultItem()
      ..uuid = map['uuid'] ?? ''
      ..ownerId = map['ownerId'] ?? 'local_user'
      ..title = map['title'] ?? ''
      ..category = map['category'] ?? 'Utilities'
      ..amount = (map['amount'] as num?)?.toDouble()
      ..isPaid = map['isPaid'] ?? false
      ..isArchived = map['isArchived'] ?? false
      ..isDeleted = map['isDeleted'] ?? false
      ..itemType = map['itemType']
      ..recurrence = map['recurrence'] ?? 'None'
      ..directDebit = map['directDebit'] ?? false
      ..notes = map['notes']
      ..isSample = map['isSample'] ?? false
      ..attachedFiles = List<String>.from(map['attachedFiles'] ?? [])
      ..cloudFileChecksums = List<String>.from(map['cloudFileChecksums'] ?? [])
      ..originalDueDay = map['originalDueDay'];

    if (map['dueDate'] != null) {
      item.dueDate = DateTime.tryParse(map['dueDate']);
    }

    if (map['lastModified'] != null) {
      item.lastModified =
          DateTime.tryParse(map['lastModified']) ?? DateTime.now();
    }

    return item;
  }
}

class ValidationError implements Exception {
  final String message;
  ValidationError(this.message);
  @override
  String toString() => message;
}
