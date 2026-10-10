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

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _filterIndex = 0; // 0: All, 1: Active, 2: Expired/Renewed

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleRenewedStatus(VaultItem item) async {
    await HapticFeedback.mediumImpact();
    final notifier = ref.read(vaultProvider.notifier);
    final nextState = !item.isPaid;
    await notifier.updatePaidStatus(item.id, nextState);

    VaultSnackBar.show(
      message:
          '${item.title} ${nextState ? "marked as renewed" : "marked as not renewed"}',
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

    final docs = allItems
        .where((i) => i.itemType == 'Document' && !i.isDeleted)
        .toList();

    final query = _searchQuery.trim().toLowerCase();
    final filteredDocs = query.isEmpty
        ? docs
        : docs.where((d) {
            return d.title.toLowerCase().contains(query) ||
                (d.notes?.toLowerCase().contains(query) ?? false) ||
                d.category.toLowerCase().contains(query);
          }).toList();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final activeDocs = filteredDocs.where((d) {
      if (d.isArchived) return false;
      if (d.isPaid) return false;
      if (d.dueDate == null) return true;
      final dueDay = DateTime(d.dueDate!.year, d.dueDate!.month, d.dueDate!.day);
      return !dueDay.isBefore(today);
    }).toList()
      ..sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });

    final expiredOrRenewedDocs = filteredDocs.where((d) {
      if (d.isArchived) return true;
      if (d.isPaid) return true;
      if (d.dueDate == null) return false;
      final dueDay = DateTime(d.dueDate!.year, d.dueDate!.month, d.dueDate!.day);
      return dueDay.isBefore(today);
    }).toList()
      ..sort((a, b) => DateHelper.compareClosestToFarthest(a.dueDate, b.dueDate, today));

    final infoAccent = isDark ? AppColors.infoBlue400 : AppColors.infoBlue700;

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
                            'Documents',
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
                              color: AppColors.infoBlue500.withValues(
                                alpha: isDark ? 0.12 : 0.1,
                              ),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: infoAccent.withValues(alpha: 0.3),
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              '${activeDocs.length} Active',
                              style: AppTypography.labelMedium(infoAccent).copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${activeDocs.length} valid • ${expiredOrRenewedDocs.length} renewed/expired',
                        style: AppTypography.bodySmall(AppColors.textSecondary(isDark)),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      VaultSearchField(
                        controller: _searchController,
                        hintText: 'Search documents...',
                        query: _searchQuery,
                        isDark: isDark,
                        focusColor: AppColors.infoBlue500,
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
                          'Active (${activeDocs.length})',
                          'Renewed/Past (${expiredOrRenewedDocs.length})',
                        ],
                        isDark: isDark,
                        activeColor: isDark ? AppColors.infoBlue500 : AppColors.infoBlue700,
                        onSelect: (index) => setState(() => _filterIndex = index),
                      ),
                    ],
                  ),
                ),
              ),

              if (filteredDocs.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    title: _searchQuery.isNotEmpty
                        ? 'No documents match your search'
                        : 'No documents added yet',
                    subtitle: _searchQuery.isNotEmpty
                        ? 'Try a different keyword or clear filters'
                        : 'Tap + to add your passport, ID, contracts, and more.',
                    icon: Icons.description_outlined,
                  ),
                )
              else ...[
                if (_filterIndex != 2 && activeDocs.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: VaultSectionHeader(
                      title: 'Active Documents',
                      count: activeDocs.length,
                      color: AppColors.infoBlue500,
                      isDark: isDark,
                      icon: Icons.verified_user_outlined,
                      singularSuffix: 'doc',
                      pluralSuffix: 'docs',
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final doc = activeDocs[index];
                        return VaultItemTile(
                          item: doc,
                          currency: currency,
                          isHomeScreen: false,
                          isFirst: index == 0,
                          isLast: index == activeDocs.length - 1,
                          showDivider: index < activeDocs.length - 1,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ItemDetailScreen(item: doc),
                              ),
                            );
                          },
                          onCheckPressed: () => _toggleRenewedStatus(doc),
                        );
                      }, childCount: activeDocs.length),
                    ),
                  ),
                ],

                if (_filterIndex != 1 && expiredOrRenewedDocs.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: VaultSectionHeader(
                      title: 'Expired & Renewed',
                      count: expiredOrRenewedDocs.length,
                      color: AppColors.textSecondary(isDark),
                      isDark: isDark,
                      icon: Icons.history_rounded,
                      singularSuffix: 'doc',
                      pluralSuffix: 'docs',
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final doc = expiredOrRenewedDocs[index];
                        return Opacity(
                          opacity: 0.85,
                          child: VaultItemTile(
                            item: doc,
                            currency: currency,
                            isHomeScreen: false,
                            isFirst: index == 0,
                            isLast: index == expiredOrRenewedDocs.length - 1,
                            showDivider: index < expiredOrRenewedDocs.length - 1,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ItemDetailScreen(item: doc),
                                ),
                              );
                            },
                            onCheckPressed: () => _toggleRenewedStatus(doc),
                          ),
                        );
                      }, childCount: expiredOrRenewedDocs.length),
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
