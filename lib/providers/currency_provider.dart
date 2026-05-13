import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/app_config.dart';
import '../providers/database_provider.dart';
import '../services/auto_sync_service.dart';

class Currency {
  final String code;
  final String symbol;

  const Currency(this.code, this.symbol);

  String formatAmount(double amount) {
    final amountString = amount.toStringAsFixed(2);
    if (code == 'RON') {
      return '$amountString lei';
    }
    if (code == 'PLN') {
      return '$amountString $symbol';
    }
    // Most global currencies use the symbol at the front (USD, EUR, GBP, INR, JPY, etc.)
    return '$symbol$amountString';
  }
}

const List<Currency> availableCurrencies = [
  Currency('RON', 'lei'),
  Currency('EUR', '€'),
  Currency('USD', '\$'),
  Currency('GBP', '£'),
  Currency('INR', '₹'), // India
  Currency('CNY', '¥'), // China
  Currency('JPY', '¥'), // Japan
  Currency('BRL', 'R\$'), // Brazil
  Currency('NGN', '₦'), // Nigeria
  Currency('IDR', 'Rp'), // Indonesia
  Currency('CHF', 'Fr'),
  Currency('PLN', 'zł'),
];

class CurrencyNotifier extends StateNotifier<Currency> {
  final Isar isar;
  final Ref ref;

  CurrencyNotifier(this.isar, this.ref) : super(_loadInitial(isar));

  static Currency _loadInitial(Isar isar) {
    // getSync e ok aici deoarece Isar este deja inițializat în main()
    final config = isar.appConfigs.getSync(0);
    final savedCode = config?.currencyCode ?? 'USD';
    return availableCurrencies.firstWhere(
      (c) => c.code == savedCode,
      orElse: () => availableCurrencies[0],
    );
  }

  Future<void> setCurrency(Currency currency) async {
    state = currency;
    
    // Salvează în Isar
    final config = await isar.appConfigs.get(0) ?? AppConfig();
    config.currencyCode = currency.code;
    
    await isar.writeTxn(() async {
      await isar.appConfigs.put(config);
    });

    // Trigger auto-backup
    ref.read(autoSyncServiceProvider).scheduleBackup();
  }
}

final currencyProvider = StateNotifierProvider<CurrencyNotifier, Currency>((ref) {
  final isar = ref.watch(isarProvider);
  return CurrencyNotifier(isar, ref);
});
