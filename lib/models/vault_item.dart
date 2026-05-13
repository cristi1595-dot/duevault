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
}
