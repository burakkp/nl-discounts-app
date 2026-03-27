import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';

class WatchlistScreen extends ConsumerStatefulWidget {
  const WatchlistScreen({super.key});

  @override
  ConsumerState<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends ConsumerState<WatchlistScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _smartNotificationsEnabled = true;

  Future<void> _addItem(String product) async {
    if (product.isEmpty) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await ref.read(apiServiceProvider).addToWatchlist(product);
      ref.invalidate(watchlistProvider);
      await ref.read(watchlistProvider.future);
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Added to Watchlist!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Product toevoegen'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'Naam van product (bijv. Melk)', border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuleren'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = _controller.text;
                _controller.clear();
                Navigator.pop(context);
                _addItem(text);
              },
              child: const Text('Toevoegen'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // We can still listen to real data, but we'll showcase the static UI as well.
    final watchlistAsync = ref.watch(watchlistProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 100, left: 24, right: 24, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section & Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Watchlist', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900, color: AppColors.onSurface)),
                    const SizedBox(height: 8),
                    const Text('Je volgt momenteel 8 producten voor prijsverlagingen.', style: TextStyle(color: AppColors.onSurfaceVariant)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.secondaryContainer, borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: AppColors.onSecondaryContainer),
                      SizedBox(width: 4),
                      Text('UTRECHT CENTRUM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onSecondaryContainer, letterSpacing: 1.2)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Smart Notifications Toggle
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(24)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(color: AppColors.primaryContainer.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.notifications_active, color: AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Smart Meldingen', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                          Text('Ontvang pushberichten bij bodemprijzen.', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                  CupertinoSwitch(
                    value: _smartNotificationsEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _smartNotificationsEnabled = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Add New Button
            InkWell(
              onTap: _showAddDialog,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3), style: BorderStyle.solid), // A dashed border implementation is a bit more complex in flutter natively without packages, using solid
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Product toevoegen aan lijst', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Watchlist Items
            const Text('ACTIEVE TRACKING', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.outline, letterSpacing: 2.0)),
            const SizedBox(height: 24),

            // Item 1
            const _WatchlistItemCard(
              imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAXZfRUCAuJGQWmyuwNRAjYPJ8SqIDbCgsb62sYLdeilrxH_tNF-8x9IryAxHie4UuHigSaYmeZ9LJWTBVPqiiAV7SmIxUWVXFhYRTucpEx8ugiKvWL_vK-luiS-FQg2W921-9397vfNEdN9t22u4flYsLS0PCB04B8CKHBNAnm8AqpcPP9hs4PB0PFWT-uPEcAu1iQ6RwUBfwfA-DWlNBkFrxYpElZLpsVfWW7hRIz7X4hGn6EnanlyPvF3yDpD8IwhpKw1olZ1MSd',
              category: 'HAVERMELK',
              title: 'Oatly Barista Edition (1L)',
              subtitle: 'Beste prijs bij Albert Heijn',
              currentPrice: '€1,49',
              oldPrice: '€2,29',
              badge: '-35% DEAL',
              badgeColor: AppColors.tertiaryContainer,
              onBadgeColor: AppColors.onTertiaryContainer,
              priceColor: AppColors.tertiary,
              buttonText: 'Bekijk Deal',
            ),
            const SizedBox(height: 16),
            // Item 2
            _WatchlistItemCard(
              imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAN6mR423tMijPjC3gKtWbgv36r4fqtgsdzLU6pdaqCrjOya5Yghxb0a17P9jyWcs9cXi9FOPvIOqfUplgX3RFafnCBt4I3n3cCV5-XzMpvdAG5yyEc__JqazeHXSwjdyrh67izdZd7-THI5-NKAORUus4MjlqUuXCWGYFpXl2I4pVhprHap3pW9mM_rnjfGPv9BjPezeUabKV-BlydqwekQ1J8876g0LXW4_NuXhZnuxPDcPMaPdr0K8BbkUWKhIx_5DkzWuXtw1fk',
              category: 'VERS PRODUCT',
              title: 'Avocado Ready-to-Eat (2st)',
              subtitle: 'Geen actuele aanbieding',
              currentPrice: '€2,99',
              priceColor: AppColors.onSurface,
              customStatus: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: const Text('Alert staat aan', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                  const SizedBox(height: 4),
                  const Text('Target: €1,99', style: TextStyle(fontSize: 10, color: AppColors.outline)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Item 3
            const _WatchlistItemCard(
              imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDVBCH98IptkKIA3_KRnovIDqM3hZh1NyvkYtolC1Ol_gNk7tZMo1Hpcgi4MN2NhWSNWtW8oueoUpf6HAb-YPGDOwyiKH3u3JNG0G8iA_t_PFPuh73dAgk7UsiT0PKEcJdaWWMNOPrr44HQ8_Vn6dblSoDYK8HtZvhJKtlgKjRvCtcESXhqj9-9ml3OCHT4n5G2YOhRtMv9IwNaOuGoHWFU-um3R3AVjLy1gceSW3Bfi79M4k8ResscgcfhYnEX4UdnCH2YN1yRDtQ7',
              category: 'HUISHOUDELIJK',
              title: 'Ariel Pods All-in-1 (30st)',
              subtitle: 'Nu 1+1 gratis bij Jumbo',
              currentPrice: '€9,49',
              oldPrice: '€18,98',
              badge: 'WEEKACTIE',
              badgeColor: AppColors.primaryContainer,
              onBadgeColor: AppColors.onPrimaryContainer,
              priceColor: AppColors.tertiary,
              buttonText: 'Bekijk Deal',
            ),
            const SizedBox(height: 48),

            // Notification History
            const Text('RECENTE MELDINGEN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.outline, letterSpacing: 2.0)),
            const SizedBox(height: 24),

            _NotificationItem(
              title: 'Prijsverlaging: Oatly Barista Edition',
              description: 'De prijs is gezakt van €2,29 naar €1,49 bij Albert Heijn. Dit is een bodemprijs!',
              time: '2 UUR GELEDEN',
              isNew: true,
            ),
            const SizedBox(height: 12),
            _NotificationItem(
              title: 'Nieuwe actie: Robijn Wasmiddel',
              description: '2+3 gratis actie gespot bij Kruidvat. Voeg toe aan je watchlist om updates te krijgen.',
              time: 'GISTEREN',
              isNew: false,
            ),

            // Render existing real watchlist items temporarily here just so they aren't lost
            const SizedBox(height: 32),
            watchlistAsync.when(
              data: (items) {
                if (items.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CLOUD ITEMS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.outline, letterSpacing: 2.0)),
                    const SizedBox(height: 16),
                    ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item, style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.delete, color: AppColors.error),
                              onPressed: () {},
                            )
                          ],
                        ),
                      ),
                    ))
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e,s) => const SizedBox.shrink(),
            ),

          ],
        ),
      ),
    );
  }
}

class _WatchlistItemCard extends StatelessWidget {
  final String imageUrl;
  final String category;
  final String title;
  final String subtitle;
  final String currentPrice;
  final String? oldPrice;
  final String? badge;
  final Color? badgeColor;
  final Color? onBadgeColor;
  final Color priceColor;
  final String? buttonText;
  final Widget? customStatus;

  const _WatchlistItemCard({
    required this.imageUrl, required this.category, required this.title, required this.subtitle, required this.currentPrice,
    this.oldPrice, this.badge, this.badgeColor, this.onBadgeColor, required this.priceColor, this.buttonText, this.customStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary, letterSpacing: 1.5)),
                        const Icon(Icons.delete, size: 16, color: AppColors.outlineVariant),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface, leadingDistribution: TextLeadingDistribution.even), maxLines: 2),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(subtitle.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(currentPrice, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: priceColor, letterSpacing: -1.0)),
                                if (oldPrice != null) ...[
                                  const SizedBox(width: 8),
                                  Text(oldPrice!, style: const TextStyle(fontSize: 12, decoration: TextDecoration.lineThrough, color: AppColors.outline)),
                                ]
                              ],
                            ),
                          ],
                        ),
                        if (customStatus != null) customStatus!,
                        if (buttonText != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(12)),
                            child: Text(buttonText!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.onPrimaryContainer)),
                          )
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
        if (badge != null)
          Positioned(
            top: -12,
            right: -8,
            child: Transform.rotate(
              angle: 0.05,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                child: Text(badge!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: onBadgeColor, letterSpacing: -0.5)),
              ),
            ),
          )
      ],
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final String title;
  final String description;
  final String time;
  final bool isNew;

  const _NotificationItem({required this.title, required this.description, required this.time, required this.isNew});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withOpacity(isNew ? 0.5 : 0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(shape: BoxShape.circle, color: isNew ? AppColors.primary : AppColors.outlineVariant),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant, height: 1.5)),
                const SizedBox(height: 8),
                Text(time, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.outline, letterSpacing: 1.2)),
              ],
            ),
          )
        ],
      ),
    );
  }
}