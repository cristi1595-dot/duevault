import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/currency_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/analytics_service.dart';
import 'settings_list_tile.dart';

class InterfaceCustomizationSection extends ConsumerWidget {
  const InterfaceCustomizationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCurrency = ref.watch(currencyProvider);
    final themeMode = ref.watch(themeProvider);

    return Column(
      children: [
        _buildCurrencyItem(context, ref, currentCurrency),
        Divider(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
          height: 1,
          indent: 56,
        ),
        SettingsListTile(
          icon: themeMode == ThemeMode.dark
              ? Icons.dark_mode_outlined
              : Icons.light_mode_outlined,
          title: 'Light & Dark Mode',
          trailing: SizedBox(
            height: 24,
            child: Switch(
              value: themeMode == ThemeMode.dark,
              onChanged: (v) {
                ref.read(themeProvider.notifier).toggleTheme();
                ref.read(analyticsServiceProvider).logSettingsChanged(
                      'theme_mode',
                      themeMode == ThemeMode.dark ? 'light' : 'dark',
                    );
              },
              activeThumbColor: Colors.greenAccent,
              activeTrackColor: Colors.greenAccent.withValues(
                alpha: 0.3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyItem(
    BuildContext context,
    WidgetRef ref,
    Currency current,
  ) {
    return SettingsListTile(
      icon: Icons.currency_exchange_rounded,
      title: 'Primary Currency',
      subtitle: current.code == 'RON'
          ? current.code
          : '${current.code} (${current.symbol})',
      trailing: DropdownButton<Currency>(
        value: current,
        underline: const SizedBox(),
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Theme.of(context).textTheme.bodySmall?.color,
          size: 16,
        ),
        onChanged: (Currency? newValue) {
          if (newValue != null) {
            ref.read(currencyProvider.notifier).setCurrency(newValue);
            ref.read(analyticsServiceProvider).logSettingsChanged(
                  'primary_currency',
                  newValue.code,
                );
          }
        },
        items: availableCurrencies.map<DropdownMenuItem<Currency>>((
          Currency value,
        ) {
          return DropdownMenuItem<Currency>(
            value: value,
            child: Text(
              value.code,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
        dropdownColor: Theme.of(context).cardTheme.color,
      ),
    );
  }
}
