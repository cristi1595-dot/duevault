// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAppConfigCollection on Isar {
  IsarCollection<AppConfig> get appConfigs => this.collection();
}

const AppConfigSchema = CollectionSchema(
  name: r'AppConfig',
  id: -7085420701237142207,
  properties: {
    r'alertDays': PropertySchema(
      id: 0,
      name: r'alertDays',
      type: IsarType.long,
    ),
    r'autoSync': PropertySchema(id: 1, name: r'autoSync', type: IsarType.bool),
    r'currencyCode': PropertySchema(
      id: 2,
      name: r'currencyCode',
      type: IsarType.string,
    ),
    r'dataVersion': PropertySchema(
      id: 3,
      name: r'dataVersion',
      type: IsarType.long,
    ),
    r'finalReminderDays': PropertySchema(
      id: 4,
      name: r'finalReminderDays',
      type: IsarType.long,
    ),
    r'finalReminderEnabled': PropertySchema(
      id: 5,
      name: r'finalReminderEnabled',
      type: IsarType.bool,
    ),
    r'globalNotificationsEnabled': PropertySchema(
      id: 6,
      name: r'globalNotificationsEnabled',
      type: IsarType.bool,
    ),
    r'guestDataMigrated': PropertySchema(
      id: 7,
      name: r'guestDataMigrated',
      type: IsarType.bool,
    ),
    r'hasAcceptedPrivacyPolicy': PropertySchema(
      id: 8,
      name: r'hasAcceptedPrivacyPolicy',
      type: IsarType.bool,
    ),
    r'hasSeenDemo': PropertySchema(
      id: 9,
      name: r'hasSeenDemo',
      type: IsarType.bool,
    ),
    r'hasSeenOnboarding': PropertySchema(
      id: 10,
      name: r'hasSeenOnboarding',
      type: IsarType.bool,
    ),
    r'isDarkMode': PropertySchema(
      id: 11,
      name: r'isDarkMode',
      type: IsarType.bool,
    ),
    r'isGuest': PropertySchema(id: 12, name: r'isGuest', type: IsarType.bool),
    r'isSecurityEnabled': PropertySchema(
      id: 13,
      name: r'isSecurityEnabled',
      type: IsarType.bool,
    ),
    r'lastCloudSync': PropertySchema(
      id: 14,
      name: r'lastCloudSync',
      type: IsarType.dateTime,
    ),
    r'lastLocalChange': PropertySchema(
      id: 15,
      name: r'lastLocalChange',
      type: IsarType.dateTime,
    ),
    r'lastSyncCheck': PropertySchema(
      id: 16,
      name: r'lastSyncCheck',
      type: IsarType.dateTime,
    ),
    r'localDatabaseChecksum': PropertySchema(
      id: 17,
      name: r'localDatabaseChecksum',
      type: IsarType.string,
    ),
    r'lockOnBackground': PropertySchema(
      id: 18,
      name: r'lockOnBackground',
      type: IsarType.bool,
    ),
    r'needsBackup': PropertySchema(
      id: 19,
      name: r'needsBackup',
      type: IsarType.bool,
    ),
    r'notificationHour': PropertySchema(
      id: 20,
      name: r'notificationHour',
      type: IsarType.long,
    ),
    r'notificationMinute': PropertySchema(
      id: 21,
      name: r'notificationMinute',
      type: IsarType.long,
    ),
    r'syncOnWifiOnly': PropertySchema(
      id: 22,
      name: r'syncOnWifiOnly',
      type: IsarType.bool,
    ),
    r'threeDayAlertEnabled': PropertySchema(
      id: 23,
      name: r'threeDayAlertEnabled',
      type: IsarType.bool,
    ),
  },

  estimateSize: _appConfigEstimateSize,
  serialize: _appConfigSerialize,
  deserialize: _appConfigDeserialize,
  deserializeProp: _appConfigDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _appConfigGetId,
  getLinks: _appConfigGetLinks,
  attach: _appConfigAttach,
  version: '3.3.2',
);

int _appConfigEstimateSize(
  AppConfig object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.currencyCode.length * 3;
  {
    final value = object.localDatabaseChecksum;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _appConfigSerialize(
  AppConfig object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.alertDays);
  writer.writeBool(offsets[1], object.autoSync);
  writer.writeString(offsets[2], object.currencyCode);
  writer.writeLong(offsets[3], object.dataVersion);
  writer.writeLong(offsets[4], object.finalReminderDays);
  writer.writeBool(offsets[5], object.finalReminderEnabled);
  writer.writeBool(offsets[6], object.globalNotificationsEnabled);
  writer.writeBool(offsets[7], object.guestDataMigrated);
  writer.writeBool(offsets[8], object.hasAcceptedPrivacyPolicy);
  writer.writeBool(offsets[9], object.hasSeenDemo);
  writer.writeBool(offsets[10], object.hasSeenOnboarding);
  writer.writeBool(offsets[11], object.isDarkMode);
  writer.writeBool(offsets[12], object.isGuest);
  writer.writeBool(offsets[13], object.isSecurityEnabled);
  writer.writeDateTime(offsets[14], object.lastCloudSync);
  writer.writeDateTime(offsets[15], object.lastLocalChange);
  writer.writeDateTime(offsets[16], object.lastSyncCheck);
  writer.writeString(offsets[17], object.localDatabaseChecksum);
  writer.writeBool(offsets[18], object.lockOnBackground);
  writer.writeBool(offsets[19], object.needsBackup);
  writer.writeLong(offsets[20], object.notificationHour);
  writer.writeLong(offsets[21], object.notificationMinute);
  writer.writeBool(offsets[22], object.syncOnWifiOnly);
  writer.writeBool(offsets[23], object.threeDayAlertEnabled);
}

AppConfig _appConfigDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AppConfig();
  object.alertDays = reader.readLong(offsets[0]);
  object.autoSync = reader.readBool(offsets[1]);
  object.currencyCode = reader.readString(offsets[2]);
  object.dataVersion = reader.readLong(offsets[3]);
  object.finalReminderDays = reader.readLong(offsets[4]);
  object.finalReminderEnabled = reader.readBool(offsets[5]);
  object.globalNotificationsEnabled = reader.readBool(offsets[6]);
  object.guestDataMigrated = reader.readBool(offsets[7]);
  object.hasAcceptedPrivacyPolicy = reader.readBool(offsets[8]);
  object.hasSeenDemo = reader.readBool(offsets[9]);
  object.hasSeenOnboarding = reader.readBool(offsets[10]);
  object.id = id;
  object.isDarkMode = reader.readBool(offsets[11]);
  object.isGuest = reader.readBool(offsets[12]);
  object.isSecurityEnabled = reader.readBool(offsets[13]);
  object.lastCloudSync = reader.readDateTimeOrNull(offsets[14]);
  object.lastLocalChange = reader.readDateTimeOrNull(offsets[15]);
  object.lastSyncCheck = reader.readDateTimeOrNull(offsets[16]);
  object.localDatabaseChecksum = reader.readStringOrNull(offsets[17]);
  object.lockOnBackground = reader.readBool(offsets[18]);
  object.needsBackup = reader.readBool(offsets[19]);
  object.notificationHour = reader.readLong(offsets[20]);
  object.notificationMinute = reader.readLong(offsets[21]);
  object.syncOnWifiOnly = reader.readBool(offsets[22]);
  object.threeDayAlertEnabled = reader.readBool(offsets[23]);
  return object;
}

P _appConfigDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readBool(offset)) as P;
    case 11:
      return (reader.readBool(offset)) as P;
    case 12:
      return (reader.readBool(offset)) as P;
    case 13:
      return (reader.readBool(offset)) as P;
    case 14:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 15:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 16:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 17:
      return (reader.readStringOrNull(offset)) as P;
    case 18:
      return (reader.readBool(offset)) as P;
    case 19:
      return (reader.readBool(offset)) as P;
    case 20:
      return (reader.readLong(offset)) as P;
    case 21:
      return (reader.readLong(offset)) as P;
    case 22:
      return (reader.readBool(offset)) as P;
    case 23:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _appConfigGetId(AppConfig object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _appConfigGetLinks(AppConfig object) {
  return [];
}

void _appConfigAttach(IsarCollection<dynamic> col, Id id, AppConfig object) {
  object.id = id;
}

extension AppConfigQueryWhereSort
    on QueryBuilder<AppConfig, AppConfig, QWhere> {
  QueryBuilder<AppConfig, AppConfig, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AppConfigQueryWhere
    on QueryBuilder<AppConfig, AppConfig, QWhereClause> {
  QueryBuilder<AppConfig, AppConfig, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension AppConfigQueryFilter
    on QueryBuilder<AppConfig, AppConfig, QFilterCondition> {
  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition> alertDaysEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'alertDays', value: value),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  alertDaysGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'alertDays',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition> alertDaysLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'alertDays',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition> alertDaysBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'alertDays',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition> autoSyncEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'autoSync', value: value),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition> currencyCodeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'currencyCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  currencyCodeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'currencyCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  currencyCodeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'currencyCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition> currencyCodeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'currencyCode',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  currencyCodeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'currencyCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  currencyCodeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'currencyCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  currencyCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'currencyCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition> currencyCodeMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'currencyCode',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  currencyCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'currencyCode', value: ''),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  currencyCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'currencyCode', value: ''),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition> dataVersionEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'dataVersion', value: value),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  dataVersionGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'dataVersion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition> dataVersionLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'dataVersion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition> dataVersionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'dataVersion',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  finalReminderDaysEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'finalReminderDays', value: value),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  finalReminderDaysGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'finalReminderDays',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  finalReminderDaysLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'finalReminderDays',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  finalReminderDaysBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'finalReminderDays',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  finalReminderEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'finalReminderEnabled',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  globalNotificationsEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'globalNotificationsEnabled',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  guestDataMigratedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'guestDataMigrated', value: value),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  hasAcceptedPrivacyPolicyEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'hasAcceptedPrivacyPolicy',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition> hasSeenDemoEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'hasSeenDemo', value: value),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  hasSeenOnboardingEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'hasSeenOnboarding', value: value),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition> isDarkModeEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isDarkMode', value: value),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition> isGuestEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isGuest', value: value),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  isSecurityEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isSecurityEnabled', value: value),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  lastCloudSyncIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastCloudSync'),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  lastCloudSyncIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastCloudSync'),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  lastCloudSyncEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastCloudSync', value: value),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  lastCloudSyncGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastCloudSync',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  lastCloudSyncLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastCloudSync',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  lastCloudSyncBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastCloudSync',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  lastLocalChangeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastLocalChange'),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  lastLocalChangeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastLocalChange'),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  lastLocalChangeEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastLocalChange', value: value),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  lastLocalChangeGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastLocalChange',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  lastLocalChangeLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastLocalChange',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  lastLocalChangeBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastLocalChange',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  lastSyncCheckIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastSyncCheck'),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  lastSyncCheckIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastSyncCheck'),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  lastSyncCheckEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastSyncCheck', value: value),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  lastSyncCheckGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastSyncCheck',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  lastSyncCheckLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastSyncCheck',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  lastSyncCheckBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastSyncCheck',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  localDatabaseChecksumIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'localDatabaseChecksum'),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  localDatabaseChecksumIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'localDatabaseChecksum'),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  localDatabaseChecksumEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'localDatabaseChecksum',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  localDatabaseChecksumGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'localDatabaseChecksum',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  localDatabaseChecksumLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'localDatabaseChecksum',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  localDatabaseChecksumBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'localDatabaseChecksum',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  localDatabaseChecksumStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'localDatabaseChecksum',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  localDatabaseChecksumEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'localDatabaseChecksum',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  localDatabaseChecksumContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'localDatabaseChecksum',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  localDatabaseChecksumMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'localDatabaseChecksum',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  localDatabaseChecksumIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'localDatabaseChecksum', value: ''),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  localDatabaseChecksumIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'localDatabaseChecksum',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  lockOnBackgroundEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lockOnBackground', value: value),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition> needsBackupEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'needsBackup', value: value),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  notificationHourEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'notificationHour', value: value),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  notificationHourGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'notificationHour',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  notificationHourLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'notificationHour',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  notificationHourBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'notificationHour',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  notificationMinuteEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'notificationMinute', value: value),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  notificationMinuteGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'notificationMinute',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  notificationMinuteLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'notificationMinute',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  notificationMinuteBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'notificationMinute',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  syncOnWifiOnlyEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'syncOnWifiOnly', value: value),
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterFilterCondition>
  threeDayAlertEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'threeDayAlertEnabled',
          value: value,
        ),
      );
    });
  }
}

extension AppConfigQueryObject
    on QueryBuilder<AppConfig, AppConfig, QFilterCondition> {}

extension AppConfigQueryLinks
    on QueryBuilder<AppConfig, AppConfig, QFilterCondition> {}

extension AppConfigQuerySortBy on QueryBuilder<AppConfig, AppConfig, QSortBy> {
  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> sortByAlertDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alertDays', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> sortByAlertDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alertDays', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> sortByAutoSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSync', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> sortByAutoSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSync', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> sortByCurrencyCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currencyCode', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> sortByCurrencyCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currencyCode', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> sortByDataVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataVersion', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> sortByDataVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataVersion', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> sortByFinalReminderDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'finalReminderDays', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy>
  sortByFinalReminderDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'finalReminderDays', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy>
  sortByFinalReminderEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'finalReminderEnabled', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy>
  sortByFinalReminderEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'finalReminderEnabled', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy>
  sortByGlobalNotificationsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'globalNotificationsEnabled', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy>
  sortByGlobalNotificationsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'globalNotificationsEnabled', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> sortByGuestDataMigrated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestDataMigrated', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy>
  sortByGuestDataMigratedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestDataMigrated', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy>
  sortByHasAcceptedPrivacyPolicy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasAcceptedPrivacyPolicy', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy>
  sortByHasAcceptedPrivacyPolicyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasAcceptedPrivacyPolicy', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> sortByHasSeenDemo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasSeenDemo', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> sortByHasSeenDemoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasSeenDemo', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> sortByHasSeenOnboarding() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasSeenOnboarding', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy>
  sortByHasSeenOnboardingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasSeenOnboarding', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> sortByIsDarkMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDarkMode', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> sortByIsDarkModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDarkMode', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> sortByIsGuest() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isGuest', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> sortByIsGuestDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isGuest', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> sortByIsSecurityEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSecurityEnabled', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy>
  sortByIsSecurityEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSecurityEnabled', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> sortByLastCloudSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCloudSync', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> sortByLastCloudSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCloudSync', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> sortByLastLocalChange() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastLocalChange', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> sortByLastLocalChangeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastLocalChange', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> sortByLastSyncCheck() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncCheck', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> sortByLastSyncCheckDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncCheck', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy>
  sortByLocalDatabaseChecksum() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localDatabaseChecksum', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy>
  sortByLocalDatabaseChecksumDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localDatabaseChecksum', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> sortByLockOnBackground() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lockOnBackground', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy>
  sortByLockOnBackgroundDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lockOnBackground', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> sortByNeedsBackup() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsBackup', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> sortByNeedsBackupDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsBackup', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> sortByNotificationHour() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationHour', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy>
  sortByNotificationHourDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationHour', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> sortByNotificationMinute() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationMinute', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy>
  sortByNotificationMinuteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationMinute', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> sortBySyncOnWifiOnly() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncOnWifiOnly', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> sortBySyncOnWifiOnlyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncOnWifiOnly', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy>
  sortByThreeDayAlertEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'threeDayAlertEnabled', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy>
  sortByThreeDayAlertEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'threeDayAlertEnabled', Sort.desc);
    });
  }
}

extension AppConfigQuerySortThenBy
    on QueryBuilder<AppConfig, AppConfig, QSortThenBy> {
  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> thenByAlertDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alertDays', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> thenByAlertDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alertDays', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> thenByAutoSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSync', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> thenByAutoSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSync', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> thenByCurrencyCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currencyCode', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> thenByCurrencyCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currencyCode', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> thenByDataVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataVersion', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> thenByDataVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataVersion', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> thenByFinalReminderDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'finalReminderDays', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy>
  thenByFinalReminderDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'finalReminderDays', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy>
  thenByFinalReminderEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'finalReminderEnabled', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy>
  thenByFinalReminderEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'finalReminderEnabled', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy>
  thenByGlobalNotificationsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'globalNotificationsEnabled', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy>
  thenByGlobalNotificationsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'globalNotificationsEnabled', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> thenByGuestDataMigrated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestDataMigrated', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy>
  thenByGuestDataMigratedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guestDataMigrated', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy>
  thenByHasAcceptedPrivacyPolicy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasAcceptedPrivacyPolicy', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy>
  thenByHasAcceptedPrivacyPolicyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasAcceptedPrivacyPolicy', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> thenByHasSeenDemo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasSeenDemo', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> thenByHasSeenDemoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasSeenDemo', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> thenByHasSeenOnboarding() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasSeenOnboarding', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy>
  thenByHasSeenOnboardingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasSeenOnboarding', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> thenByIsDarkMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDarkMode', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> thenByIsDarkModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDarkMode', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> thenByIsGuest() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isGuest', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> thenByIsGuestDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isGuest', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> thenByIsSecurityEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSecurityEnabled', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy>
  thenByIsSecurityEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSecurityEnabled', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> thenByLastCloudSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCloudSync', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> thenByLastCloudSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCloudSync', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> thenByLastLocalChange() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastLocalChange', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> thenByLastLocalChangeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastLocalChange', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> thenByLastSyncCheck() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncCheck', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> thenByLastSyncCheckDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncCheck', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy>
  thenByLocalDatabaseChecksum() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localDatabaseChecksum', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy>
  thenByLocalDatabaseChecksumDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localDatabaseChecksum', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> thenByLockOnBackground() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lockOnBackground', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy>
  thenByLockOnBackgroundDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lockOnBackground', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> thenByNeedsBackup() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsBackup', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> thenByNeedsBackupDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsBackup', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> thenByNotificationHour() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationHour', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy>
  thenByNotificationHourDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationHour', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> thenByNotificationMinute() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationMinute', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy>
  thenByNotificationMinuteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationMinute', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> thenBySyncOnWifiOnly() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncOnWifiOnly', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy> thenBySyncOnWifiOnlyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncOnWifiOnly', Sort.desc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy>
  thenByThreeDayAlertEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'threeDayAlertEnabled', Sort.asc);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QAfterSortBy>
  thenByThreeDayAlertEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'threeDayAlertEnabled', Sort.desc);
    });
  }
}

extension AppConfigQueryWhereDistinct
    on QueryBuilder<AppConfig, AppConfig, QDistinct> {
  QueryBuilder<AppConfig, AppConfig, QDistinct> distinctByAlertDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'alertDays');
    });
  }

  QueryBuilder<AppConfig, AppConfig, QDistinct> distinctByAutoSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'autoSync');
    });
  }

  QueryBuilder<AppConfig, AppConfig, QDistinct> distinctByCurrencyCode({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currencyCode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppConfig, AppConfig, QDistinct> distinctByDataVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dataVersion');
    });
  }

  QueryBuilder<AppConfig, AppConfig, QDistinct> distinctByFinalReminderDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'finalReminderDays');
    });
  }

  QueryBuilder<AppConfig, AppConfig, QDistinct>
  distinctByFinalReminderEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'finalReminderEnabled');
    });
  }

  QueryBuilder<AppConfig, AppConfig, QDistinct>
  distinctByGlobalNotificationsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'globalNotificationsEnabled');
    });
  }

  QueryBuilder<AppConfig, AppConfig, QDistinct> distinctByGuestDataMigrated() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'guestDataMigrated');
    });
  }

  QueryBuilder<AppConfig, AppConfig, QDistinct>
  distinctByHasAcceptedPrivacyPolicy() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasAcceptedPrivacyPolicy');
    });
  }

  QueryBuilder<AppConfig, AppConfig, QDistinct> distinctByHasSeenDemo() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasSeenDemo');
    });
  }

  QueryBuilder<AppConfig, AppConfig, QDistinct> distinctByHasSeenOnboarding() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasSeenOnboarding');
    });
  }

  QueryBuilder<AppConfig, AppConfig, QDistinct> distinctByIsDarkMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDarkMode');
    });
  }

  QueryBuilder<AppConfig, AppConfig, QDistinct> distinctByIsGuest() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isGuest');
    });
  }

  QueryBuilder<AppConfig, AppConfig, QDistinct> distinctByIsSecurityEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSecurityEnabled');
    });
  }

  QueryBuilder<AppConfig, AppConfig, QDistinct> distinctByLastCloudSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastCloudSync');
    });
  }

  QueryBuilder<AppConfig, AppConfig, QDistinct> distinctByLastLocalChange() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastLocalChange');
    });
  }

  QueryBuilder<AppConfig, AppConfig, QDistinct> distinctByLastSyncCheck() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncCheck');
    });
  }

  QueryBuilder<AppConfig, AppConfig, QDistinct>
  distinctByLocalDatabaseChecksum({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'localDatabaseChecksum',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<AppConfig, AppConfig, QDistinct> distinctByLockOnBackground() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lockOnBackground');
    });
  }

  QueryBuilder<AppConfig, AppConfig, QDistinct> distinctByNeedsBackup() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'needsBackup');
    });
  }

  QueryBuilder<AppConfig, AppConfig, QDistinct> distinctByNotificationHour() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notificationHour');
    });
  }

  QueryBuilder<AppConfig, AppConfig, QDistinct> distinctByNotificationMinute() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notificationMinute');
    });
  }

  QueryBuilder<AppConfig, AppConfig, QDistinct> distinctBySyncOnWifiOnly() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncOnWifiOnly');
    });
  }

  QueryBuilder<AppConfig, AppConfig, QDistinct>
  distinctByThreeDayAlertEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'threeDayAlertEnabled');
    });
  }
}

extension AppConfigQueryProperty
    on QueryBuilder<AppConfig, AppConfig, QQueryProperty> {
  QueryBuilder<AppConfig, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AppConfig, int, QQueryOperations> alertDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'alertDays');
    });
  }

  QueryBuilder<AppConfig, bool, QQueryOperations> autoSyncProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'autoSync');
    });
  }

  QueryBuilder<AppConfig, String, QQueryOperations> currencyCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currencyCode');
    });
  }

  QueryBuilder<AppConfig, int, QQueryOperations> dataVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dataVersion');
    });
  }

  QueryBuilder<AppConfig, int, QQueryOperations> finalReminderDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'finalReminderDays');
    });
  }

  QueryBuilder<AppConfig, bool, QQueryOperations>
  finalReminderEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'finalReminderEnabled');
    });
  }

  QueryBuilder<AppConfig, bool, QQueryOperations>
  globalNotificationsEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'globalNotificationsEnabled');
    });
  }

  QueryBuilder<AppConfig, bool, QQueryOperations> guestDataMigratedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'guestDataMigrated');
    });
  }

  QueryBuilder<AppConfig, bool, QQueryOperations>
  hasAcceptedPrivacyPolicyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasAcceptedPrivacyPolicy');
    });
  }

  QueryBuilder<AppConfig, bool, QQueryOperations> hasSeenDemoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasSeenDemo');
    });
  }

  QueryBuilder<AppConfig, bool, QQueryOperations> hasSeenOnboardingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasSeenOnboarding');
    });
  }

  QueryBuilder<AppConfig, bool, QQueryOperations> isDarkModeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDarkMode');
    });
  }

  QueryBuilder<AppConfig, bool, QQueryOperations> isGuestProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isGuest');
    });
  }

  QueryBuilder<AppConfig, bool, QQueryOperations> isSecurityEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSecurityEnabled');
    });
  }

  QueryBuilder<AppConfig, DateTime?, QQueryOperations> lastCloudSyncProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastCloudSync');
    });
  }

  QueryBuilder<AppConfig, DateTime?, QQueryOperations>
  lastLocalChangeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastLocalChange');
    });
  }

  QueryBuilder<AppConfig, DateTime?, QQueryOperations> lastSyncCheckProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncCheck');
    });
  }

  QueryBuilder<AppConfig, String?, QQueryOperations>
  localDatabaseChecksumProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localDatabaseChecksum');
    });
  }

  QueryBuilder<AppConfig, bool, QQueryOperations> lockOnBackgroundProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lockOnBackground');
    });
  }

  QueryBuilder<AppConfig, bool, QQueryOperations> needsBackupProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'needsBackup');
    });
  }

  QueryBuilder<AppConfig, int, QQueryOperations> notificationHourProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notificationHour');
    });
  }

  QueryBuilder<AppConfig, int, QQueryOperations> notificationMinuteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notificationMinute');
    });
  }

  QueryBuilder<AppConfig, bool, QQueryOperations> syncOnWifiOnlyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncOnWifiOnly');
    });
  }

  QueryBuilder<AppConfig, bool, QQueryOperations>
  threeDayAlertEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'threeDayAlertEnabled');
    });
  }
}
