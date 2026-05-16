import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/vault_repository.dart';
import '../utils/logger.dart';
import '../services/auto_sync_service.dart';
import 'vault_provider.dart';

class Currency {
  final String code;
  final String symbol;

  const Currency(this.code, this.symbol);

  String formatAmount(double amount) {
    // Show decimals only if they are not zero
    String amountString;
    if (amount % 1 == 0) {
      amountString = amount.toInt().toString();
    } else {
      amountString = amount.toStringAsFixed(2);
      // Optional: remove trailing zero if it's like 10.50 -> 10.5?
      // The user said "afisezale daca au zecimale", so 10.50 is fine.
      // But let's make it clean.
      if (amountString.endsWith('0')) {
        amountString = amountString.substring(0, amountString.length - 1);
      }
    }

    if (code == 'RON') {
      return '$amountString lei';
    }
    if (code == 'PLN') {
      return '$amountString $symbol';
    }
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
  final VaultRepository repository;
  final Ref ref;

  CurrencyNotifier(this.repository, this.ref) : super(availableCurrencies[2]) {
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final config = await repository.getConfig();
    final savedCode = config.currencyCode;
    state = availableCurrencies.firstWhere(
      (c) => c.code == savedCode,
      orElse: () => availableCurrencies[2], // USD
    );
  }

  Future<void> setCurrency(Currency currency) async {
    state = currency;

    final config = await repository.getConfig();
    config.currencyCode = currency.code;
    await repository.updateConfig(config);

    logger.i('Currency changed to: ${currency.code}');

    // Trigger auto-backup
    ref.read(autoSyncServiceProvider).scheduleBackup();
  }
}

final currencyProvider = StateNotifierProvider<CurrencyNotifier, Currency>((
  ref,
) {
  final repository = ref.watch(vaultRepositoryProvider);
  return CurrencyNotifier(repository, ref);
});
