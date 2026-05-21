import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/vault_provider.dart';
import '../../providers/currency_provider.dart';
import '../../widgets/global_components.dart';
import '../../theme/app_theme.dart';

class FinancialBentoCard extends ConsumerWidget {
  const FinancialBentoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultItems = ref.watch(vaultProvider);
    final currency = ref.watch(currencyProvider);

    // Calculate Stats
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final next7Days = today.add(const Duration(days: 7));
    final next30Days = today.add(const Duration(days: 30));

    final overdueBills = vaultItems.where((item) {
      if (item.itemType != 'Bill' || item.isPaid || item.dueDate == null) {
        return false;
      }
      return item.dueDate!.isBefore(today);
    }).toList();

    final expiredDocs = vaultItems.where((item) {
      if (item.itemType != 'Document' ||
          item.isArchived ||
          item.dueDate == null) {
        return false;
      }
      return item.dueDate!.isBefore(today);
    }).toList();

    final upcomingBills = vaultItems.where((item) {
      if (item.itemType != 'Bill' || item.isPaid || item.dueDate == null) {
        return false;
      }
      final due = DateTime(
        item.dueDate!.year,
        item.dueDate!.month,
        item.dueDate!.day,
      );
      return (due.isBefore(next7Days) || due.isAtSameMomentAs(next7Days)) &&
          (due.isAfter(today) || due.isAtSameMomentAs(today));
    }).toList();

    final totalDueOverdue = overdueBills.fold(
      0.0,
      (sum, item) => sum + (item.amount ?? 0),
    );

    final totalDue7Days =
        (upcomingBills.fold(0.0, (sum, item) => sum + (item.amount ?? 0))) +
        totalDueOverdue;

    final items30Days = vaultItems.where((item) {
      if (item.itemType != 'Bill' || item.isPaid || item.dueDate == null) {
        return false;
      }
      final due = DateTime(
        item.dueDate!.year,
        item.dueDate!.month,
        item.dueDate!.day,
      );
      return (due.isBefore(next30Days) || due.isAtSameMomentAs(next30Days)) &&
          (due.isAfter(today) || due.isAtSameMomentAs(today));
    }).toList();

    final totalDue30Days =
        (items30Days.fold(0.0, (sum, item) => sum + (item.amount ?? 0))) +
        totalDueOverdue;

    // Calculate Document Expirations
    final expiredDocs7Days = vaultItems.where((item) {
      if (item.itemType != 'Document' ||
          item.isArchived ||
          item.isPaid ||
          item.dueDate == null) {
        return false;
      }
      final due = DateTime(
        item.dueDate!.year,
        item.dueDate!.month,
        item.dueDate!.day,
      );
      return (due.isBefore(next7Days) || due.isAtSameMomentAs(next7Days)) &&
          (due.isAfter(today) || due.isAtSameMomentAs(today));
    }).toList();

    final expiredDocs30Days = vaultItems.where((item) {
      if (item.itemType != 'Document' ||
          item.isArchived ||
          item.isPaid ||
          item.dueDate == null) {
        return false;
      }
      final due = DateTime(
        item.dueDate!.year,
        item.dueDate!.month,
        item.dueDate!.day,
      );
      return (due.isBefore(next30Days) || due.isAtSameMomentAs(next30Days)) &&
          (due.isAfter(today) || due.isAtSameMomentAs(today));
    }).toList();

    // Check urgency states
    final totalDocs7Days = expiredDocs.length + expiredDocs7Days.length;
    final totalDocs30Days = expiredDocs.length + expiredDocs30Days.length;

    final has7DaysIssues = totalDue7Days > 0 || totalDocs7Days > 0;
    final has30DaysIssues = totalDue30Days > 0 || totalDocs30Days > 0;

    final Color bentoBgColor;
    final Color bentoBorderColor;

    if (has7DaysIssues) {
      bentoBgColor = AppTheme.urgentRed.withValues(alpha: 0.04);
      bentoBorderColor = AppTheme.urgentRed.withValues(alpha: 0.35);
    } else if (has30DaysIssues) {
      bentoBgColor = AppTheme.warningYellow.withValues(alpha: 0.04);
      bentoBorderColor = AppTheme.warningYellow.withValues(alpha: 0.35);
    } else {
      bentoBgColor = AppTheme.safeGreen.withValues(alpha: 0.04);
      bentoBorderColor = AppTheme.safeGreen.withValues(alpha: 0.35);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
      child: BentoCard(
        color: bentoBgColor,
        borderColor: bentoBorderColor,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        borderRadius: 14.0,
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ROW 1: 7 DAYS
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BILLS • NEXT 7 DAYS',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currency.formatAmount(totalDue7Days),
                          style: TextStyle(
                            color: totalDue7Days > 0 ? AppTheme.urgentRed : AppTheme.safeGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DOCS • NEXT 7 DAYS',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$totalDocs7Days',
                          style: TextStyle(
                            color: totalDocs7Days > 0 ? AppTheme.urgentRed : AppTheme.safeGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Divider(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
                  height: 1,
                ),
              ),
              // ROW 2: 30 DAYS
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BILLS • NEXT 30 DAYS',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currency.formatAmount(totalDue30Days),
                          style: TextStyle(
                            color: totalDue30Days > 0 ? AppTheme.warningYellow : AppTheme.safeGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 19,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DOCS • NEXT 30 DAYS',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$totalDocs30Days',
                          style: TextStyle(
                            color: totalDocs30Days > 0 ? AppTheme.warningYellow : AppTheme.safeGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 19,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
