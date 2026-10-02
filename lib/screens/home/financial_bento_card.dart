import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/vault_provider.dart';
import '../../providers/currency_provider.dart';
import '../../theme/app_theme.dart';

class FinancialBentoCard extends ConsumerWidget {
  const FinancialBentoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultItems = ref.watch(vaultProvider);
    final currency = ref.watch(currencyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final next30Days = today.add(const Duration(days: 30));

    // Overdue bills
    final overdueBills = vaultItems.where((item) {
      if (item.itemType != 'Bill' || item.isPaid || item.isArchived || item.dueDate == null) {
        return false;
      }
      return item.dueDate!.isBefore(today);
    }).toList();

    // Upcoming 30 days
    final upcomingBills30Days = vaultItems.where((item) {
      if (item.itemType != 'Bill' || item.isPaid || item.isArchived || item.dueDate == null) {
        return false;
      }
      final due = DateTime(item.dueDate!.year, item.dueDate!.month, item.dueDate!.day);
      return (due.isBefore(next30Days) || due.isAtSameMomentAs(next30Days)) &&
          (due.isAfter(today) || due.isAtSameMomentAs(today));
    }).toList();

    final totalDueMonth = (upcomingBills30Days.fold<double>(0.0, (s, i) => s + (i.amount ?? 0))) +
        (overdueBills.fold<double>(0.0, (s, i) => s + (i.amount ?? 0)));

    // Auto-Pay / Funds reserved
    final autoPayBills = upcomingBills30Days.where((i) => i.directDebit).toList();
    final autoPayTotal = autoPayBills.fold<double>(0.0, (s, i) => s + (i.amount ?? 0));

    // Expiring docs
    final expiringDocs = vaultItems.where((i) {
      if (i.itemType != 'Document' || i.isArchived || i.isPaid || i.dueDate == null) return false;
      final due = DateTime(i.dueDate!.year, i.dueDate!.month, i.dueDate!.day);
      return due.isBefore(next30Days) || due.isAtSameMomentAs(next30Days);
    }).toList();

    final monthName = DateFormat('MMMM yyyy').format(now);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161A22) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF222734) : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'THIS MONTH',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              Text(
                monthName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${currency.symbol}${totalDueMonth.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                'to pay',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Clean Pill Badges
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Upcoming Count
              _buildBadge(
                context,
                icon: Icons.receipt_long_outlined,
                label: '${upcomingBills30Days.length} upcoming',
                color: AppTheme.primaryAction,
                bgColor: AppTheme.primaryAction.withValues(alpha: 0.1),
              ),
              // Overdue Alert (if any)
              if (overdueBills.isNotEmpty)
                _buildBadge(
                  context,
                  icon: Icons.error_outline,
                  label: '${overdueBills.length} overdue',
                  color: AppTheme.urgentRed,
                  bgColor: AppTheme.urgentRed.withValues(alpha: 0.12),
                ),
              // Auto-Pay / Funds reserved in bank
              if (autoPayBills.isNotEmpty)
                _buildBadge(
                  context,
                  icon: Icons.savings_outlined,
                  label: 'Auto-Pay: ${currency.symbol}${autoPayTotal.toStringAsFixed(0)} reserved',
                  color: AppTheme.safeGreen,
                  bgColor: AppTheme.safeGreen.withValues(alpha: 0.12),
                ),
              // Expiring Docs (if any)
              if (expiringDocs.isNotEmpty)
                _buildBadge(
                  context,
                  icon: Icons.description_outlined,
                  label: '${expiringDocs.length} docs expiring',
                  color: Colors.amber.shade700,
                  bgColor: Colors.amber.withValues(alpha: 0.12),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
