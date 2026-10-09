import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/vault_item.dart';
import '../../providers/vault_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/vault_item_tile.dart';
import '../../widgets/vault_snackbar.dart';
import '../item_detail_screen.dart';

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

  void _toggleRenewedStatus(VaultItem item) {
    final notifier = ref.read(vaultProvider.notifier);
    final nextState = !item.isPaid;
    notifier.updatePaidStatus(item.id, nextState);

    VaultSnackBar.show(
      message:
          '${item.title} ${nextState ? "marked as renewed" : "marked as not renewed"}',
      actionLabel: 'UNDO',
      backgroundColor: AppTheme.safeGreen,
      onAction: () => notifier.updatePaidStatus(item.id, !nextState),
    );
  }

  Widget _buildFilterChip(String label, int index, bool isDark) {
    final isSelected = _filterIndex == index;
    return InkWell(
      onTap: () => setState(() => _filterIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryAction
              : (isDark ? const Color(0xFF161F30) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryAction
                : (isDark ? const Color(0xFF222F48) : const Color(0xFFE2E8F0)),
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allItems = ref.watch(vaultProvider);
    final currency = ref.watch(currencyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Filter only documents
    final docs = allItems
        .where((i) => i.itemType == 'Document' && !i.isDeleted)
        .toList();

    // Search filter
    final query = _searchQuery.trim().toLowerCase();
    final filteredDocs = query.isEmpty
        ? docs
        : docs.where((d) {
            return d.title.toLowerCase().contains(query) ||
                (d.notes?.toLowerCase().contains(query) ?? false);
          }).toList();

    // Split into Active and Expired/Renewed
    final activeDocs =
        filteredDocs.where((d) {
          if (d.isArchived || d.isPaid) return false;
          if (d.dueDate != null && d.dueDate!.isBefore(today)) return false;
          return true;
        }).toList()..sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });

    int compareClosestToFarthest(DateTime? a, DateTime? b) {
      if (a == null && b == null) return 0;
      if (a == null) return 1;
      if (b == null) return -1;

      final aDay = DateTime(a.year, a.month, a.day);
      final bDay = DateTime(b.year, b.month, b.day);

      final aDiff = aDay.difference(today).inDays;
      final bDiff = bDay.difference(today).inDays;

      // Both upcoming (>= 0): closest upcoming date first
      if (aDiff >= 0 && bDiff >= 0) {
        return aDiff.compareTo(bDiff);
      }
      // Both in past (< 0): closest past date to today first (-1 before -30)
      if (aDiff < 0 && bDiff < 0) {
        return bDiff.compareTo(aDiff);
      }
      // Upcoming before past
      return aDiff >= 0 ? -1 : 1;
    }

    final expiredDocs =
        filteredDocs.where((d) {
          if (d.isArchived || d.isPaid) return true;
          if (d.dueDate != null && d.dueDate!.isBefore(today)) return true;
          return false;
        }).toList()..sort((a, b) => compareClosestToFarthest(a.dueDate, b.dueDate));

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
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Documents',
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryAction.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.primaryAction.withValues(
                                  alpha: 0.25,
                                ),
                              ),
                            ),
                            child: Text(
                              '${activeDocs.length} Active',
                              style: const TextStyle(
                                color: AppTheme.primaryAction,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'IDs, warranties, policies and contracts',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 14),
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search documents...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF161F30)
                              : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xFF222F48)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xFF222F48)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Filter Pills
                      Row(
                        children: [
                          _buildFilterChip('All', 0, isDark),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'Active (${activeDocs.length})',
                            1,
                            isDark,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'Expired (${expiredDocs.length})',
                            2,
                            isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              if (filteredDocs.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 56,
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No documents match your search'
                              : 'No documents added yet',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Try a different keyword'
                              : 'Tap + to add your first document',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // Active Section
                if (_filterIndex != 2 && activeDocs.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            size: 16,
                            color: AppTheme.primaryAction,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ACTIVE DOCUMENTS (${activeDocs.length})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final doc = activeDocs[index];
                        return VaultItemTile(
                          item: doc,
                          currency: currency,
                          isHomeScreen: false,
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

                // Expired / Renewed Section
                if (_filterIndex != 1 && expiredDocs.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.history,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'EXPIRED & RENEWED (${expiredDocs.length})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final doc = expiredDocs[index];
                        return Opacity(
                          opacity: 0.85,
                          child: VaultItemTile(
                            item: doc,
                            currency: currency,
                            isHomeScreen: false,
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
                      }, childCount: expiredDocs.length),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
