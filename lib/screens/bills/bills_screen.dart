import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/vault_item.dart';
import '../../providers/vault_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/global_components.dart';
import '../../utils/date_helper.dart';
import '../item_detail_screen.dart';
import '../shared/vault_filter_pills.dart';
import '../shared/vault_section_header.dart';
import '../shared/vault_search_field.dart';

class BillsScreen extends ConsumerStatefulWidget {
  const BillsScreen({super.key});

  @override
  ConsumerState<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends ConsumerState<BillsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _filterIndex = 0; // 0: All, 1: Unpaid, 2: Paid

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _togglePaidStatus(VaultItem item) async {
    await HapticFeedback.mediumImpact();
    final notifier = ref.read(vaultProvider.notifier);
    final nextState = !item.isPaid;
    await notifier.updatePaidStatus(item.id, nextState);

    VaultSnackBar.show(
      message:
          '${item.title} ${nextState ? "marked as paid" : "marked as unpaid"}',
      actionLabel: 'UNDO',
      backgroundColor: AppColors.emerald500,
      onAction: () => notifier.updatePaidStatus(item.id, !nextState),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allItems = ref.watch(vaultProvider);
    final currency = ref.watch(currencyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bills = allItems
        .where((i) => i.itemType == 'Bill' && !i.isDeleted)
        .toList();

    final query = _searchQuery.trim().toLowerCase();
    final filteredBills = query.isEmpty
        ? bills
        : bills.where((b) {
            return b.title.toLowerCase().contains(query) ||
                (b.notes?.toLowerCase().contains(query) ?? false) ||
                (b.amount != null && b.amount.toString().contains(query));
          }).toList();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final activeBills =
        filteredBills.where((b) => !b.isPaid && !b.isArchived).toList()
          ..sort((a, b) {
            if (a.dueDate == null && b.dueDate == null) return 0;
            if (a.dueDate == null) return 1;
            if (b.dueDate == null) return -1;
            return a.dueDate!.compareTo(b.dueDate!);
          });

    final paidBills =
        filteredBills.where((b) => b.isPaid || b.isArchived).toList()
          ..sort((a, b) => DateHelper.compareClosestToFarthest(a.dueDate, b.dueDate, today));

    final totalOutstanding = activeBills.fold<double>(
      0.0,
      (sum, item) => sum + (item.amount ?? 0.0),
    );

    final emeraldAccent = isDark ? AppColors.emerald400 : AppColors.emerald700;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification) {
              final delta = notification.scrollDelta ?? 0;
              if (delta.abs() > 2) {
                ref.read(navBarVisibleProvider.notifier).state = false;
              }
            }
            if (notification is ScrollEndNotification) {
              ref.read(navBarVisibleProvider.notifier).state = true;
            }
            return false;
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.base,
                    AppSpacing.base,
                    AppSpacing.base,
                    AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Bills',
                            style: AppTypography.headlineLarge(AppColors.textPrimary(isDark)).copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.emerald500.withValues(
                                alpha: isDark ? 0.12 : 0.1,
                              ),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: emeraldAccent.withValues(alpha: 0.3),
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              'Due: ${currency.symbol}${totalOutstanding.toStringAsFixed(2)}',
                              style: AppTypography.labelMedium(emeraldAccent).copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${activeBills.length} active • ${paidBills.length} settled',
                        style: AppTypography.bodySmall(AppColors.textSecondary(isDark)),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      VaultSearchField(
                        controller: _searchController,
                        hintText: 'Search bills...',
                        query: _searchQuery,
                        isDark: isDark,
                        focusColor: AppColors.emerald500,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        onClear: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      VaultFilterPills(
                        selectedIndex: _filterIndex,
                        options: [
                          'All',
                          'Unpaid (${activeBills.length})',
                          'Paid (${paidBills.length})',
                        ],
                        isDark: isDark,
                        activeColor: isDark ? AppColors.emerald500 : AppColors.emerald600,
                        onSelect: (index) => setState(() => _filterIndex = index),
                      ),
                    ],
                  ),
                ),
              ),

              if (filteredBills.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    title: _searchQuery.isNotEmpty
                        ? 'No bills match your search'
                        : 'No bills added yet',
                    subtitle: _searchQuery.isNotEmpty
                        ? 'Try a different keyword or clear filters'
                        : 'Tap + to add your first bill and stay ahead of deadlines.',
                    icon: Icons.receipt_long_outlined,
                  ),
                )
              else ...[
                if (_filterIndex != 2 && activeBills.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: VaultSectionHeader(
                      title: 'Upcoming & Due',
                      count: activeBills.length,
                      color: AppColors.emerald500,
                      isDark: isDark,
                      icon: Icons.schedule_rounded,
                      singularSuffix: 'bill',
                      pluralSuffix: 'bills',
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final bill = activeBills[index];
                        return VaultItemTile(
                          item: bill,
                          currency: currency,
                          isHomeScreen: false,
                          isFirst: index == 0,
                          isLast: index == activeBills.length - 1,
                          showDivider: index < activeBills.length - 1,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ItemDetailScreen(item: bill),
                              ),
                            );
                          },
                          onCheckPressed: () => _togglePaidStatus(bill),
                        );
                      }, childCount: activeBills.length),
                    ),
                  ),
                ],

                if (_filterIndex != 1 && paidBills.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: VaultSectionHeader(
                      title: 'Paid & Settled',
                      count: paidBills.length,
                      color: AppColors.statusSafeText(isDark),
                      isDark: isDark,
                      icon: Icons.check_circle_outline_rounded,
                      singularSuffix: 'bill',
                      pluralSuffix: 'bills',
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final bill = paidBills[index];
                        return Opacity(
                          opacity: 0.85,
                          child: VaultItemTile(
                            item: bill,
                            currency: currency,
                            isHomeScreen: false,
                            isFirst: index == 0,
                            isLast: index == paidBills.length - 1,
                            showDivider: index < paidBills.length - 1,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ItemDetailScreen(item: bill),
                                ),
                              );
                            },
                            onCheckPressed: () => _togglePaidStatus(bill),
                          ),
                        );
                      }, childCount: paidBills.length),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 140)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
