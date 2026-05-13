import 'package:isar/isar.dart';
part 'user.g.dart';

@collection
class User {
  Id id = Isar.autoIncrement;
  String authMethod = 'Guest'; 
  bool isPremium = false;
  String defaultCurrency = 'USD';
  int globalAlertDays = 3;
}
