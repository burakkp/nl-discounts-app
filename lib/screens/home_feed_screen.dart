import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';

class HomeFeedScreen extends ConsumerWidget {
  const HomeFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We can use the actual provider data if we want for the grid, but I will structure the UI to match the static design 1:1 first.
    final discountsAsync = ref.watch(discountsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 80, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: AppColors.outline),
                          SizedBox(width: 12),
                          Text('Zoek naar "Koffie"', style: TextStyle(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.secondaryContainer, shape: BoxShape.circle),
                    child: const Icon(Icons.location_on, color: AppColors.onSecondaryContainer),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Neighborhood Badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('JE LOKALE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant, letterSpacing: 1.5)),
                    SizedBox(width: 8),
                    Text('AMSTERDAM', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.onSurface)),
                    SizedBox(width: 4),
                    Text('STORE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant, letterSpacing: 1.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Categories
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _CategoryChip(icon: Icons.whatshot, label: 'Alle', isActive: true),
                  const SizedBox(width: 12),
                  _CategoryChip(icon: Icons.eco, label: 'Vers', isActive: false),
                  const SizedBox(width: 12),
                  _CategoryChip(icon: Icons.kitchen, label: 'Pantry', isActive: false),
                  const SizedBox(width: 12),
                  _CategoryChip(icon: Icons.local_drink, label: 'Drinken', isActive: false),
                  const SizedBox(width: 12),
                  _CategoryChip(icon: Icons.home, label: 'Huis', isActive: false),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Bento Grid: Featured
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // Mega Deal
                  Expanded(
                    flex: 6,
                    child: Container(
                      height: 200,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.orange600], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text('MEGA DEAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 1.5)),
                          ),
                          const Spacer(),
                          const Text('Koffie\nBonen', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              const Text('1+1', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -2)),
                              const SizedBox(width: 4),
                              Text('GRATIS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white.withOpacity(0.8), letterSpacing: 1.5)),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Favoriet
                  Expanded(
                    flex: 4,
                    child: Container(
                      height: 200,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.favorite, color: AppColors.tertiary, size: 20),
                          ),
                          const Spacer(),
                          const Text('Jouw\nLijst', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.onSecondaryContainer, height: 1.2)),
                          const SizedBox(height: 8),
                          const Text('3 PRIJSDROPS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary, letterSpacing: 1.0)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // Populaire Aanbiedingen section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Populaire Aanbiedingen',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.onSurface, letterSpacing: -0.5),
              ),
            ),
            const SizedBox(height: 24),

            // Use the real data if available, otherwise just gracefully fallback or show placeholder layouts.
            // For now, mapping the static grid UI.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: discountsAsync.when(
                data: (discounts) {
                  // We'll interleave some mock images to make it look like the design regardless of DB.
                  return GridView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.65, // Adjust based on visual needs
                    ),
                    itemCount: 4, // Just show 4 mocked items for 1:1 design mapping
                    itemBuilder: (context, index) {
                      switch (index) {
                        case 0:
                          return const _DealGridCard(
                            imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDQqRjWIdQ8QJq6J1Qn11M64kQqG5qJ-C6T-k5U1j9iWz6yO2m67y8_Z4KqJ9dZ4xZ3yXwP212_yvK2N6K-1kYgVXVvKXjPjV5cM2ZVX-R4Y5T9NQRQyqLJWQW-S99dKXUjJk0XyD6s0JjLwN_QpD4P1M2s2gRk9C_9XQ6N6Vd7_Z4P2r3Y3y6w5Q',
                            title: 'Bananen Chiquita',
                            subtitle: 'ALBERT HEIJN • 300M',
                            price: '€1,99',
                            oldPrice: '€2,49',
                            badgeText: 'VERS',
                            badgeColor: Colors.green,
                          );
                        case 1:
                          return const _DealGridCard(
                            imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuD20a0bO53u2jH8qR555rXZyv8-U2G5X_yvK2N6K-1kYgVXVvKXjPjV5cM2ZVX-R4Y5T9NQRQyqLJWQW-S99dKXUjJk0XyD6s0JjLwN_QpD4P1M2s2gRk9C_9XQ6N6Vd7_Z4P2r3Y3y6w5Q',
                            title: 'Ariel Pods Color',
                            subtitle: 'JUMBO • 800M',
                            price: '€14,99',
                            oldPrice: '€29,98',
                            badgeText: '1+1 GRATIS',
                            badgeColor: AppColors.errorContainer,
                          );
                        case 2:
                          return const _DealGridCard(
                            imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDQqRjWIdQ8QJq6J1Qn11M64kQqG5qJ-C6T-k5U1j9iWz6yO2m67y8_Z4KqJ9dZ4xZ3yXwP212_yvK2N6K-1kYgVXVvKXjPjV5cM2ZVX-R4Y5T9NQRQyqLJWQW-S99dKXUjJk0XyD6s0JjLwN_QpD4P1M2s2gRk9C_9XQ6N6Vd7_Z4P2r3Y3y6w5Q',
                            title: 'Coca Cola Zero 6x 330ml',
                            subtitle: 'LIDL • 1.2KM',
                            price: '€3,99',
                            oldPrice: '€5,49',
                            badgeText: '-27%',
                            badgeColor: AppColors.primaryContainer,
                          );
                        case 3:
                          return const _DealGridCard(
                            imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDQqRjWIdQ8QJq6J1Qn11M64kQqG5qJ-C6T-k5U1j9iWz6yO2m67y8_Z4KqJ9dZ4xZ3yXwP212_yvK2N6K-1kYgVXVvKXjPjV5cM2ZVX-R4Y5T9NQRQyqLJWQW-S99dKXUjJk0XyD6s0JjLwN_QpD4P1M2s2gRk9C_9XQ6N6Vd7_Z4P2r3Y3y6w5Q',
                            title: 'Robijn Wasmiddel 60 Wasbeurten',
                            subtitle: 'KRUIDVAT • 450M',
                            price: '€8,99',
                            oldPrice: '€17,99',
                            badgeText: 'OP=OP',
                            badgeColor: Colors.black,
                          );
                        default:
                          return const SizedBox();
                      }
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e,s) => const Center(child: Text('Failed to load real deals, showing placeholders instead.')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _CategoryChip({required this.icon, required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? AppColors.onSurface : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isActive ? Colors.transparent : AppColors.outlineVariant.withOpacity(0.3)),
        boxShadow: isActive ? const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isActive ? AppColors.surface : AppColors.outline),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isActive ? AppColors.surface : AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DealGridCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final String price;
  final String oldPrice;
  final String badgeText;
  final Color badgeColor;

  const _DealGridCard({
    required this.imageUrl, required this.title, required this.subtitle,
    required this.price, required this.oldPrice, required this.badgeText, required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(32),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    // Using fallback icons since mock image URLs from Tailwind design might be broken links
                    child: const Icon(Icons.shopping_bag, size: 60, color: AppColors.surfaceContainerHighest),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.2), maxLines: 2),
                          const SizedBox(height: 4),
                          Text(subtitle, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant, letterSpacing: 1.0)),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(price, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.primary)),
                          const SizedBox(width: 4),
                          Text(oldPrice, style: const TextStyle(fontSize: 10, decoration: TextDecoration.lineThrough, color: AppColors.outline)),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(12)),
              child: Text(badgeText, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0)),
            ),
          )
        ],
      ),
    );
  }
}
