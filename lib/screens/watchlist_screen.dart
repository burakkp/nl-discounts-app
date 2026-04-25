// lib/screens/watchlist_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../models/catalog_item.dart';
import '../models/notification_history_item.dart';
import '../models/watchlist_item.dart';
import '../theme/app_theme.dart';
import 'catalog_search_sheet.dart';

class WatchlistScreen extends ConsumerStatefulWidget {
  const WatchlistScreen({super.key});

  @override
  ConsumerState<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends ConsumerState<WatchlistScreen> {
  bool _smartNotificationsEnabled = true;

  Future<void> _removeItem(WatchlistItem item) async {
    // Perform optimistic removal immediately
    await ref.read(watchlistNotifierProvider.notifier).remove(item.productId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${item.productName}" verwijderd'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          action: SnackBarAction(
            label: 'ONGEDAAN',
            textColor: AppColors.primaryContainer,
            onPressed: () {
              // Re-add on undo
              ref.read(watchlistNotifierProvider.notifier).add(
                    _watchlistItemToCatalogItem(item),
                  );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final watchlistAsync = ref.watch(watchlistNotifierProvider);
    final notifAsync = ref.watch(notificationHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(watchlistNotifierProvider.notifier).refresh(),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
            top: 100,
            left: 24,
            right: 24,
            bottom: 120,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero Section ──────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mijn Lijst',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppColors.onSurface,
                              ),
                        ),
                        const SizedBox(height: 8),
                        watchlistAsync.when(
                          data: (items) => Text(
                            '${items.length} product${items.length == 1 ? '' : 'en'} bijgehouden',
                            style: const TextStyle(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          loading: () => const Text(
                            'Laden...',
                            style:
                                TextStyle(color: AppColors.onSurfaceVariant),
                          ),
                          error: (e, s) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Deal count badge
                  watchlistAsync.maybeWhen(
                    data: (items) {
                      final dealCount =
                          items.where((i) => i.hasActiveDeal).length;
                      if (dealCount == 0) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$dealCount',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'DEALS',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Smart Notifications Toggle ─────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_active,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Smart Meldingen',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Ontvang pushberichten bij bodemprijzen.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CupertinoSwitch(
                      value: _smartNotificationsEnabled,
                      activeTrackColor: AppColors.primary,
                      onChanged: (val) =>
                          setState(() => _smartNotificationsEnabled = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Add Button ───────────────────────────────────────────────
              InkWell(
                onTap: () => showCatalogSearchSheet(context),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(43, 47, 48, 0.06),
                        blurRadius: 32,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Product toevoegen aan lijst',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Active Tracking List ──────────────────────────────────────
              const Text(
                'ACTIEVE TRACKING',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.outline,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 16),

              watchlistAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return _EmptyWatchlist(
                      onAdd: () => showCatalogSearchSheet(context),
                    );
                  }
                  return ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _SwipeableWatchlistCard(
                        item: item,
                        onDelete: () => _removeItem(item),
                      );
                    },
                  );
                },
                loading: () => _WatchlistSkeleton(),
                error: (e, _) => _ErrorState(
                  error: e.toString(),
                  onRetry: () =>
                      ref.read(watchlistNotifierProvider.notifier).refresh(),
                ),
              ),

              const SizedBox(height: 48),

              // ── Recent Notifications ──────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'RECENTE MELDINGEN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.outline,
                      letterSpacing: 2.0,
                    ),
                  ),
                  // "Clear All" only visible when there are real items
                  notifAsync.maybeWhen(
                    data: (items) => items.isNotEmpty
                        ? TextButton(
                            onPressed: () => ref
                                .read(notificationHistoryProvider.notifier)
                                .clearAll(),
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Wis alles',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Live notification list (FCM history) + pinned system card
              notifAsync.when(
                data: (items) => Column(
                  children: [
                    // Real FCM notifications — newest-first, swipe-to-dismiss
                    ...items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _DismissibleNotificationCard(
                          key: ValueKey(item.id),
                          item: item,
                          onDismissed: () => ref
                              .read(notificationHistoryProvider.notifier)
                              .delete(item.id),
                          onTap: () => ref
                              .read(notificationHistoryProvider.notifier)
                              .markRead(item.id),
                        ),
                      ),
                    ),
                    // Pinned system-info card — always visible at the bottom
                    _NotificationItem(
                      icon: Icons.notifications_active,
                      iconColor: AppColors.primary,
                      title: 'Smart Meldingen Actief',
                      description:
                          'Je ontvangt een pushbericht zodra een product op je '
                          'lijst goedkoper is bij een winkel in de buurt.',
                      time: 'SYSTEEM INFO',
                      isNew: items.isEmpty, // only highlighted when list empty
                    ),
                  ],
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                error: (_, _) => _NotificationItem(
                  icon: Icons.notifications_active,
                  iconColor: AppColors.primary,
                  title: 'Smart Meldingen Actief',
                  description:
                      'Je ontvangt een pushbericht zodra een product op je '
                      'lijst goedkoper is bij een winkel in de buurt.',
                  time: 'SYSTEEM INFO',
                  isNew: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── SWIPEABLE WATCHLIST CARD ────────────────────────────────────────────────

class _SwipeableWatchlistCard extends StatelessWidget {
  final WatchlistItem item;
  final VoidCallback onDelete;

  const _SwipeableWatchlistCard({
    required this.item,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.productId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: _WatchlistItemCard(item: item, onDelete: onDelete),
    );
  }
}

// ─── WATCHLIST ITEM CARD ─────────────────────────────────────────────────────

class _WatchlistItemCard extends StatelessWidget {
  final WatchlistItem item;
  final VoidCallback onDelete;

  const _WatchlistItemCard({
    required this.item,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = item.hasActiveDeal && item.discountPercent > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(43, 47, 48, 0.06),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product thumbnail
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.shopping_basket_outlined,
                  size: 36,
                  color: AppColors.outlineVariant,
                ),
              ),
              // Deal badge on thumbnail
              if (hasDiscount)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tertiary,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4),
                      ],
                    ),
                    child: Text(
                      '▼${item.discountPercent}%',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category + delete
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: item.hasActiveDeal
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.hasActiveDeal ? 'AANBIEDING' : 'TRACKING',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: item.hasActiveDeal
                              ? AppColors.primary
                              : AppColors.outline,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Product name
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Price row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          item.currentPrice != null
                              ? '€${item.currentPrice!.toStringAsFixed(2)}'
                              : '--',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: item.hasActiveDeal
                                ? AppColors.primary
                                : AppColors.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (item.originalPrice != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '€${item.originalPrice!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                              color: AppColors.outline,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Store name
                    if (item.storeName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.storeName!.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSecondaryContainer,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── HELPER STATES ───────────────────────────────────────────────────────────

class _EmptyWatchlist extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyWatchlist({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onAdd,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.add_shopping_cart,
              size: 36,
              color: AppColors.primary,
            ),
            SizedBox(height: 16),
            Text(
              'Je lijst is leeg',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tik hier om je eerste product toe te voegen\nen meldingen te ontvangen bij prijsdalingen.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WatchlistSkeleton extends StatefulWidget {
  @override
  State<_WatchlistSkeleton> createState() => _WatchlistSkeletonState();
}

class _WatchlistSkeletonState extends State<_WatchlistSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final color = Color.lerp(
          AppColors.surfaceContainerLow,
          AppColors.surfaceContainerHigh,
          (_controller.value > 0.5
                  ? 1 - _controller.value
                  : _controller.value) *
              2,
        )!;
        return Column(
          children: List.generate(
            3,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                height: 112,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 32),
          const SizedBox(height: 12),
          const Text(
            'Kon watchlist niet laden',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Opnieuw proberen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── NOTIFICATION ITEM (reusable card shell) ─────────────────────────────────

class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String time;
  final bool isNew;

  const _NotificationItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.time,
    required this.isNew,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNew
            ? AppColors.primary.withValues(alpha: 0.05)
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: isNew
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.2))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.outline,
                    letterSpacing: 1.2,
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

// ─── DISMISSIBLE NOTIFICATION CARD ───────────────────────────────────────────

class _DismissibleNotificationCard extends StatelessWidget {
  final NotificationHistoryItem item;
  final VoidCallback onDismissed;
  final VoidCallback onTap;

  const _DismissibleNotificationCard({
    super.key,
    required this.item,
    required this.onDismissed,
    required this.onTap,
  });

  IconData _iconForSupermarket(String? name) {
    if (name == null) return Icons.local_offer_outlined;
    final lower = name.toLowerCase();
    if (lower.contains('albert')) return Icons.store;
    if (lower.contains('jumbo')) return Icons.storefront;
    if (lower.contains('lidl') || lower.contains('aldi')) {
      return Icons.shopping_bag_outlined;
    }
    return Icons.local_offer_outlined;
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'ZOJUIST';
    if (diff.inMinutes < 60) return '${diff.inMinutes}M GELEDEN';
    if (diff.inHours < 24) return '${diff.inHours}U GELEDEN';
    return '${diff.inDays}D GELEDEN';
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !item.isRead;
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 22),
            SizedBox(height: 4),
            Text(
              'VERWIJDER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: _NotificationItem(
          icon: _iconForSupermarket(item.supermarket),
          iconColor: isUnread ? AppColors.primary : AppColors.onSurfaceVariant,
          title: item.title,
          description: item.body,
          time: _relativeTime(item.timestamp),
          isNew: isUnread,
        ),
      ),
    );
  }
}

// ─── HELPERS ─────────────────────────────────────────────────────────────────

CatalogItem _watchlistItemToCatalogItem(WatchlistItem item) {
  return CatalogItem(
    id: item.productId,
    name: item.productName,
    supermarket: item.storeName,
  );
}
