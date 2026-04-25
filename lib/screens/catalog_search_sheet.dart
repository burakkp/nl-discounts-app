// lib/screens/catalog_search_sheet.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../models/catalog_item.dart';
import '../theme/app_theme.dart';

/// Shows the catalog search bottom sheet and returns the added [CatalogItem]
/// (or null if the user cancelled).
Future<void> showCatalogSearchSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CatalogSearchSheet(),
  );
}

class _CatalogSearchSheet extends ConsumerStatefulWidget {
  const _CatalogSearchSheet();

  @override
  ConsumerState<_CatalogSearchSheet> createState() =>
      _CatalogSearchSheetState();
}

class _CatalogSearchSheetState extends ConsumerState<_CatalogSearchSheet>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  final Set<String> _addedIds = {}; // Track locally to show instant feedback
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(catalogSearchQueryProvider.notifier).setQuery(value);
    });
  }

  Future<void> _addItem(CatalogItem item) async {
    if (_addedIds.contains(item.id)) return;
    setState(() => _addedIds.add(item.id));

    try {
      await ref.read(watchlistNotifierProvider.notifier).add(item);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ "${item.name}" aan je lijst toegevoegd!'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _addedIds.remove(item.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fout: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(catalogSearchQueryProvider);
    final searchAsync = ref.watch(catalogSearchProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product zoeken',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.onSurface,
                      ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Zoek in onze Master Catalogus en voeg toe aan je lijst.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.2), // Ghost border
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(43, 47, 48, 0.06),
                    blurRadius: 32,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onQueryChanged,
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'bijv. Melk, Koffie, Pasta...',
                  hintStyle: const TextStyle(color: AppColors.onSurfaceVariant),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.outline,
                  ),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: AppColors.outline,
                          ),
                          onPressed: () {
                             _searchController.clear();
                            ref
                                .read(catalogSearchQueryProvider.notifier)
                                .setQuery('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 8,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Results
          Expanded(
            child: _buildResults(query, searchAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(
    String query,
    AsyncValue<List<CatalogItem>> searchAsync,
  ) {
    if (query.trim().length < 2) {
      return _buildEmptyState(
        icon: Icons.search,
        title: 'Begin met typen',
        subtitle: 'Minimaal 2 tekens om te zoeken',
      );
    }

    return searchAsync.when(
      loading: () => _buildShimmer(),
      error: (e, _) => _buildEmptyState(
        icon: Icons.wifi_off,
        title: 'Zoeken mislukt',
        subtitle: e.toString(),
      ),
      data: (items) {
        if (items.isEmpty) {
          return _buildEmptyState(
            icon: Icons.search_off,
            title: 'Geen resultaten',
            subtitle: 'Probeer een andere zoekterm',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) =>
              _SearchResultTile(
            item: items[index],
            isAdded: _addedIds.contains(items[index].id),
            onAdd: () => _addItem(items[index]),
          ),
        );
      },
    );
  }

  Widget _buildShimmer() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final shimmerColor = Color.lerp(
          AppColors.surfaceContainerLow,
          AppColors.surfaceContainerHigh,
          (_shimmerController.value > 0.5
              ? 1 - _shimmerController.value
              : _shimmerController.value) *
              2,
        )!;
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          itemCount: 6,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, _) => Container(
            height: 72,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.outline),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final CatalogItem item;
  final bool isAdded;
  final VoidCallback onAdd;

  const _SearchResultTile({
    required this.item,
    required this.isAdded,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isAdded
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(43, 47, 48, 0.06),
            blurRadius: 32,
            offset: Offset(0, 12),
          )
        ],
      ),
      child: Row(
        children: [
          // Product icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shopping_basket_outlined,
              color: AppColors.outline,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Name + meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (item.category != null) ...[
                      _Chip(label: item.category!, color: AppColors.secondary),
                      const SizedBox(width: 6),
                    ],
                    if (item.supermarket != null)
                      _Chip(
                        label: item.supermarket!.toUpperCase(),
                        color: AppColors.tertiary,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Add button
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isAdded ? null : onAdd,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isAdded ? AppColors.primary : AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAdded ? Icons.check : Icons.add,
                size: 20,
                color: isAdded ? Colors.white : AppColors.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
