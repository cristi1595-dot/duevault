import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/vault_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/navigation_provider.dart';
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
    final next7Days = today.add(const Duration(days: 7));
    final next30Days = today.add(const Duration(days: 30));

    // --- BILLS STATS ---
    final overdueBills = vaultItems.where((item) {
      if (item.itemType != 'Bill' || item.isPaid || item.isArchived || item.dueDate == null) {
        return false;
      }
      return item.dueDate!.isBefore(today);
    }).toList();

    final overdueBillsTotal = overdueBills.fold<double>(
      0.0,
      (sum, item) => sum + (item.amount ?? 0),
    );

    final upcomingBills7Days = vaultItems.where((item) {
      if (item.itemType != 'Bill' || item.isPaid || item.isArchived || item.dueDate == null) {
        return false;
      }
      final due = DateTime(item.dueDate!.year, item.dueDate!.month, item.dueDate!.day);
      return (due.isBefore(next7Days) || due.isAtSameMomentAs(next7Days)) &&
          (due.isAfter(today) || due.isAtSameMomentAs(today));
    }).toList();

    final totalBills7Days = (upcomingBills7Days.fold<double>(
          0.0,
          (sum, item) => sum + (item.amount ?? 0),
        )) +
        overdueBillsTotal;

    final upcomingBills30Days = vaultItems.where((item) {
      if (item.itemType != 'Bill' || item.isPaid || item.isArchived || item.dueDate == null) {
        return false;
      }
      final due = DateTime(item.dueDate!.year, item.dueDate!.month, item.dueDate!.day);
      return (due.isBefore(next30Days) || due.isAtSameMomentAs(next30Days)) &&
          (due.isAfter(today) || due.isAtSameMomentAs(today));
    }).toList();

    final totalBills30Days = (upcomingBills30Days.fold<double>(
          0.0,
          (sum, item) => sum + (item.amount ?? 0),
        )) +
        overdueBillsTotal;

    // --- DOCUMENTS STATS ---
    final expiredDocs = vaultItems.where((item) {
      if (item.itemType != 'Document' || item.isArchived || item.isPaid || item.dueDate == null) {
        return false;
      }
      return item.dueDate!.isBefore(today);
    }).toList();

    final upcomingDocs7Days = vaultItems.where((item) {
      if (item.itemType != 'Document' || item.isArchived || item.isPaid || item.dueDate == null) {
        return false;
      }
      final due = DateTime(item.dueDate!.year, item.dueDate!.month, item.dueDate!.day);
      return (due.isBefore(next7Days) || due.isAtSameMomentAs(next7Days)) &&
          (due.isAfter(today) || due.isAtSameMomentAs(today));
    }).toList();

    final totalDocs7Days = expiredDocs.length + upcomingDocs7Days.length;

    final upcomingDocs30Days = vaultItems.where((item) {
      if (item.itemType != 'Document' || item.isArchived || item.isPaid || item.dueDate == null) {
        return false;
      }
      final due = DateTime(item.dueDate!.year, item.dueDate!.month, item.dueDate!.day);
      return (due.isBefore(next30Days) || due.isAtSameMomentAs(next30Days)) &&
          (due.isAfter(today) || due.isAtSameMomentAs(today));
    }).toList();

    final totalDocs30Days = expiredDocs.length + upcomingDocs30Days.length;

    // Card Colors & Styling
    final cardBg = isDark ? const Color(0xFF161A22) : Colors.white;
    final borderColor = isDark ? const Color(0xFF222734) : const Color(0xFFE2E8F0);
    const billAccent = Color(0xFF10B981); // Emerald
    const docAccent = Color(0xFF6366F1);  // Slate Indigo

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // === LEFT COLUMN: BILLS ===
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(28),
                    ),
                    onTap: () {
                      ref.read(bottomNavIndexProvider.notifier).state = 1;
                    },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title + Icon + Chevron
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: billAccent.withValues(alpha: 0.14),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long_rounded,
                                    size: 15,
                                    color: billAccent,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'BILLS',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: billAccent,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 10,
                                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // 7 Days Primary Metric (Big & Bold)
                            Text(
                              'NEXT 7 DAYS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${currency.symbol}${totalBills7Days.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                      fontSize: 21.5,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                              ),
                            ),

                            // Overdue indicator if any
                            if (overdueBills.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.urgentRed.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      size: 11,
                                      color: AppTheme.urgentRed,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${overdueBills.length} overdue',
                                      style: const TextStyle(
                                        color: AppTheme.urgentRed,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const Spacer(),
                            const SizedBox(height: 12),

                            // 30 Days Secondary Metric (Pill container)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF222734)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_month_outlined,
                                    size: 13,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '30 Days',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                          ),
                                        ),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            '${currency.symbol}${totalBills30Days.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 11.3,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Vertical Divider between Columns
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: borderColor,
                ),

                // === RIGHT COLUMN: DOCUMENTS ===
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(28),
                      ),
                      onTap: () {
                        ref.read(bottomNavIndexProvider.notifier).state = 2;
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title + Icon + Chevron
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: docAccent.withValues(alpha: 0.14),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.description_rounded,
                                    size: 15,
                                    color: docAccent,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'DOCUMENTS',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: docAccent,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 10,
                                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // 7 Days Primary Metric (Big & Bold)
                            Text(
                              'NEXT 7 DAYS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '$totalDocs7Days',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5,
                                          fontSize: 21.5,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'expiring',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Expired indicator if any
                            if (expiredDocs.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.urgentRed.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      size: 11,
                                      color: AppTheme.urgentRed,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${expiredDocs.length} expired',
                                      style: const TextStyle(
                                        color: AppTheme.urgentRed,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const Spacer(),
                            const SizedBox(height: 12),

                            // 30 Days Secondary Metric (Pill container)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF222734)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_month_outlined,
                                    size: 13,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '30 Days',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                          ),
                                        ),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            '$totalDocs30Days expiring',
                                            style: TextStyle(
                                              fontSize: 11.3,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}
