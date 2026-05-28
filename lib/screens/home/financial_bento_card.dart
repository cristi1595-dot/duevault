import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/vault_provider.dart';
import '../../providers/currency_provider.dart';
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
      if (item.itemType != 'Bill' || item.isPaid || item.isArchived || item.dueDate == null) {
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
      if (item.itemType != 'Bill' || item.isPaid || item.isArchived || item.dueDate == null) {
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
      if (item.itemType != 'Bill' || item.isPaid || item.isArchived || item.dueDate == null) {
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

    // Calculate days remaining across active unpaid items to determine status
    final activeBills = vaultItems.where((item) {
      return item.itemType == 'Bill' && !item.isPaid && !item.isArchived && item.dueDate != null;
    }).toList();

    int billMinDaysLeft = 99999;
    for (final item in activeBills) {
      final due = DateTime(
        item.dueDate!.year,
        item.dueDate!.month,
        item.dueDate!.day,
      );
      final days = due.difference(today).inDays;
      if (days < billMinDaysLeft) {
        billMinDaysLeft = days;
      }
    }

    final bool billUrgent = overdueBills.isNotEmpty || billMinDaysLeft <= 3;
    final bool billWarning = !billUrgent && billMinDaysLeft <= 7;

    final Color billColor;
    if (billUrgent) {
      billColor = AppTheme.urgentRed;
    } else if (billWarning) {
      billColor = AppTheme.warningYellow;
    } else {
      billColor = AppTheme.safeGreen;
    }

    final activeDocs = vaultItems.where((item) {
      return item.itemType == 'Document' && !item.isArchived && !item.isPaid && item.dueDate != null;
    }).toList();

    int docMinDaysLeft = 99999;
    for (final item in activeDocs) {
      final due = DateTime(
        item.dueDate!.year,
        item.dueDate!.month,
        item.dueDate!.day,
      );
      final days = due.difference(today).inDays;
      if (days < docMinDaysLeft) {
        docMinDaysLeft = days;
      }
    }

    final bool docUrgent = expiredDocs.isNotEmpty || docMinDaysLeft <= 3;
    final bool docWarning = !docUrgent && docMinDaysLeft <= 7;

    final Color docColor;
    if (docUrgent) {
      docColor = AppTheme.urgentRed;
    } else if (docWarning) {
      docColor = AppTheme.warningYellow;
    } else {
      docColor = AppTheme.safeGreen;
    }

    final bool isUrgentRed = billUrgent || docUrgent;
    final bool isWarningYellow = !isUrgentRed && (billWarning || docWarning);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    if (isUrgentRed) {
      statusColor = AppTheme.urgentRed;
      statusLabel = 'ACTION REQUIRED';
      statusIcon = Icons.error_outline_rounded;
    } else if (isWarningYellow) {
      statusColor = AppTheme.warningYellow;
      statusLabel = 'UPCOMING DUE';
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = AppTheme.safeGreen;
      statusLabel = 'ALL CLEAR';
      statusIcon = Icons.check_circle_outline_rounded;
    }

    BoxDecoration buildCardDecoration(Color cardStatusColor) {
      final Color cardBg;
      final Gradient? cardGradient;

      if (isDark) {
        const Color baseStartColor = Color(0xFF1C2028);
        const Color baseEndColor = Color(0xFF101217);
        final Color startColor = Color.alphaBlend(
          cardStatusColor.withValues(alpha: 0.08),
          baseStartColor,
        );
        final Color endColor = Color.alphaBlend(
          cardStatusColor.withValues(alpha: 0.02),
          baseEndColor,
        );
        cardBg = Colors.transparent;
        cardGradient = LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      } else {
        cardBg = Color.alphaBlend(
          cardStatusColor.withValues(alpha: 0.03),
          Colors.white,
        );
        cardGradient = null;
      }

      final double borderOpacity = isDark ? 0.15 : 0.10;
      final Color borderColor = cardStatusColor.withValues(alpha: borderOpacity);

      return BoxDecoration(
        color: cardGradient == null ? cardBg : null,
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: borderColor,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? cardStatusColor.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: isDark ? 16 : 10,
            offset: const Offset(0, 3),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: Global Status & Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '7-DAY OUTLOOK',
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontSize: 12.6,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        size: 13.2,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10.8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Bento Cards Row
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card 1: Financial (Bills)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                    decoration: buildCardDecoration(billColor),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'FINANCIAL',
                              style: TextStyle(
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                fontSize: 11.0,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: billColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.receipt_long_rounded,
                                size: 16,
                                color: billColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            currency.formatAmount(totalDue7Days),
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontWeight: FontWeight.w900,
                              fontSize: 27.0,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'due bills',
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                            fontSize: 13.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(height: 10),
                        if (totalDueOverdue > 0)
                          Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 12,
                                color: AppTheme.urgentRed,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${currency.formatAmount(totalDueOverdue)} overdue',
                                  style: const TextStyle(
                                    color: AppTheme.urgentRed,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Icon(
                                Icons.analytics_outlined,
                                size: 12,
                                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '30d: ${currency.formatAmount(totalDue30Days)}',
                                  style: TextStyle(
                                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Card 2: Documents
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                    decoration: buildCardDecoration(docColor),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'DOCUMENTS',
                              style: TextStyle(
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                fontSize: 11.0,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: docColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.description_rounded,
                                size: 16,
                                color: docColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '$totalDocs7Days',
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontWeight: FontWeight.w900,
                              fontSize: 27.0,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'expiring soon',
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                            fontSize: 13.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(height: 10),
                        if (expiredDocs.isNotEmpty)
                          Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 12,
                                color: AppTheme.urgentRed,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${expiredDocs.length} expired',
                                  style: const TextStyle(
                                    color: AppTheme.urgentRed,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Icon(
                                Icons.analytics_outlined,
                                size: 12,
                                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '30d: $totalDocs30Days expiring',
                                  style: TextStyle(
                                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
