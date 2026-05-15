import 'package:isar/isar.dart';
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
  List<String> cloudFileChecksums = []; // MD5 hashes of files for content-based sync
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
      item.lastModified = DateTime.tryParse(map['lastModified']) ?? DateTime.now();
    }

    return item;
  }
}
