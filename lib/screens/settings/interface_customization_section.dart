import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/currency_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/analytics_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_typography.dart';
import 'settings_list_tile.dart';
import 'settings_divider.dart';

class InterfaceCustomizationSection extends ConsumerWidget {
  const InterfaceCustomizationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCurrency = ref.watch(currencyProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        _buildCurrencyItem(context, ref, currentCurrency, isDark),
        const SettingsDivider(),
        SettingsListTile(
          icon: themeMode == ThemeMode.dark
              ? Icons.dark_mode_outlined
              : themeMode == ThemeMode.light
                  ? Icons.light_mode_outlined
                  : Icons.settings_suggest_outlined,
          title: 'App Theme',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated(isDark),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.border(isDark),
                width: 0.8,
              ),
            ),
            child: DropdownButton<ThemeMode>(
              value: themeMode,
              underline: const SizedBox(),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary(isDark),
                size: 16,
              ),
              isDense: true,
              onChanged: (ThemeMode? newValue) {
                if (newValue != null) {
                  HapticFeedback.lightImpact();
                  ref.read(themeProvider.notifier).setTheme(newValue);
                  ref.read(analyticsServiceProvider).logSettingsChanged(
                        'theme_mode',
                        newValue.name,
                      );
                }
              },
              items: ThemeMode.values.map<DropdownMenuItem<ThemeMode>>((
                ThemeMode value,
              ) {
                String label;
                switch (value) {
                  case ThemeMode.light:
                    label = 'Light';
                    break;
                  case ThemeMode.dark:
                    label = 'Dark';
                    break;
                  case ThemeMode.system:
                    label = 'System';
                    break;
                }
                return DropdownMenuItem<ThemeMode>(
                  value: value,
                  child: Text(
                    label,
                    style: AppTypography.labelMedium(AppColors.textPrimary(isDark)).copyWith(
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
              dropdownColor: AppColors.surface(isDark),
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
    bool isDark,
  ) {
    return SettingsListTile(
      icon: Icons.currency_exchange_rounded,
      title: 'Primary Currency',
      subtitle: current.code == 'RON'
          ? current.code
          : '${current.code} (${current.symbol})',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated(isDark),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.border(isDark),
            width: 0.8,
          ),
        ),
        child: DropdownButton<Currency>(
          value: current,
          underline: const SizedBox(),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary(isDark),
            size: 16,
          ),
          isDense: true,
          onChanged: (Currency? newValue) {
            if (newValue != null) {
              HapticFeedback.lightImpact();
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
                style: AppTypography.labelMedium(AppColors.textPrimary(isDark)).copyWith(
                  fontSize: 13,
                ),
              ),
            );
          }).toList(),
          dropdownColor: AppColors.surface(isDark),
        ),
      ),
    );
  }
}
