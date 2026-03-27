import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MapViewScreen extends StatelessWidget {
  const MapViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.network(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuAwxaTE4Cq5WARn_Nrf0QaQjTWkjH9aXNVKByT6yGe8z-1LtylOsRg7pVGwtOgIgWodQM04M6317Kel7hewkR936plMtDNvvFIbQbM0Tj-1fMMMZg8HoakwdUliNxcJJ1WGWGZRAG9000hrRY9Qhxdu6sDJPJtFJ0Exm-BiGkt8yKQExRCiiqwoFgHaebImZQP4n5-IkqrflE0iou7y2TuEaFn7iz3_bEPwZ6icRNyOVow78hh1C8jCx3qC5a8PUBvCyZmI_2XuwJw-',
              fit: BoxFit.cover,
            ),
          ),
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.4),
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),

          // User Location Pulse Dot
          Positioned(
            top: MediaQuery.of(context).size.height * 0.45,
            left: MediaQuery.of(context).size.width * 0.5,
            child: const _UserLocationDot(),
          ),

          // Filter Pill Bar
          Positioned(
            top: 20, // Relative to safe area within main dashboard's body usually, but standard UI design uses inset
            left: 16,
            right: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterPill(label: 'Alle Winkels', isActive: false),
                  const SizedBox(width: 8),
                  _FilterPill(label: 'Albert Heijn', isActive: true, hasClose: true),
                  const SizedBox(width: 8),
                  _FilterPill(label: 'Jumbo', isActive: false),
                  const SizedBox(width: 8),
                  _FilterPill(label: 'Lidl', isActive: false),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
          
          // Neighborhood Badge
          Positioned(
            top: 20,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  )
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: AppColors.onSecondaryContainer),
                  const SizedBox(width: 4),
                  Text(
                    'AMSTERDAM CENTRUM',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Action Buttons
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).size.height * 0.35,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'layers_fab',
                  onPressed: () {},
                  backgroundColor: AppColors.surfaceContainerLowest,
                  child: const Icon(Icons.layers, color: AppColors.onSurface),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.small(
                  heroTag: 'location_fab',
                  onPressed: () {},
                  backgroundColor: AppColors.primaryContainer,
                  child: const Icon(Icons.my_location, color: AppColors.onPrimaryContainer),
                ),
              ],
            ),
          ),

          // Bottom Sheet (Static layout mockup)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: const Text('AH', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.onSecondaryContainer)),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Albert Heijn Museumplein', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                              Text('24 actieve aanbiedingen • 400m afstand', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        style: IconButton.styleFrom(backgroundColor: AppColors.surfaceContainerLow),
                        icon: const Icon(Icons.directions, color: AppColors.primary),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Deals Scroller
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _DealCard(
                          title: 'Hollandse Aardbeien - 400g',
                          imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuB7qOCi9UxvN68nJA5ILTvDGVNlXFXDG_rimou-8wsldPoBmWBDV2F0FktBgEFdXh0_Y3oA-EnboBl7vCEk-f3c8Yt3jnQOboS2ru2EO7dGWTrlwrPKuHM5gohtJoIgWl9ytNx_v57-0wWE-QCmUqqwB-rzdWaElr-GxDdeDVAwL6VVnozBgKNOTt7X8TFD8nmi2kj7otr-6SYhMHdCN9Gt4e7GyaaNdO8YmS-0989PQxuz8ShwLbgSOiQOFP7jiRtcNAxicTlrZSyE',
                          oldPrice: '€6.98',
                          newPrice: '€3.49',
                          badge: '1+1 GRATIS',
                        ),
                        const SizedBox(width: 16),
                        _DealCard(
                          title: 'Verse Sinaasappelsap - 1L',
                          imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBrwR2H_8XQ0WlfdTv_uwl490KcxiR6wuzQ1MSbh1sj02uPBRXljzRXRigxkYXp6N4CYqSiLrjhLDVvz7WAqVgtHdlgT2_gY2qE85tz1bGQTV4jI62d1bKBk5adFZOFX833XTjQX7T1NuxRSYYtQNOOKotIwX1-Lt_v9nVwPvkyTWBiqWb-TpFITXXOeez1hhNOHEOrc6J92jJLCb9zqvhsXiOmITmxakdhisetW_dQbNqz-Z4muuONokWmtCVS22Kssj2a3gu6RU1A',
                          oldPrice: '€2.99',
                          newPrice: '€2.24',
                          badge: '-25% KORTING',
                        ),
                        const SizedBox(width: 16),
                        _DealCard(
                          title: 'Brioche Bollen - 4 stuks',
                          imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDKpp9bKrQBHDqkqJmC4I_L5oym-gTC5JD2om76737EbXmpdsLWIIJX3yq51LP1564fhvjZsbRUFjv1NsiTjTwwmvNcex_8xowYksrusjhKFKBhYfiDRVoyCsL8qpvJK9eThKJkiQys92y1t9W9PtJgUVc1RbntyE71BLL_BYvFRcbJU3dcLNvAgX3B59ggyA4d9o4_wTnxLwAW-8TY_6VgxRCn6vXnSK7RrkCxZIWOf3pUQmemiGBB2YzuIODCeUTviCeN14YCu1Cv',
                          oldPrice: '€2.25',
                          newPrice: '€1.50',
                          badge: 'OP = OP',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60), // Space for bottom nav
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool hasClose;

  const _FilterPill({required this.label, required this.isActive, this.hasClose = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.secondaryContainer : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? Colors.transparent : Colors.transparent, width: 2), // The original has a hover effect border
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
              color: isActive ? AppColors.onSecondaryContainer : AppColors.onSurface,
            ),
          ),
          if (hasClose) ...[
            const SizedBox(width: 8),
            const Icon(Icons.close, size: 14, color: AppColors.onSecondaryContainer),
          ]
        ],
      ),
    );
  }
}

class _UserLocationDot extends StatelessWidget {
  const _UserLocationDot();

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(-24, -24), // Center the pulse dot
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              // We'd add an animation controller here for the true pulse effect
            ),
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              alignment: Alignment.center,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String oldPrice;
  final String newPrice;
  final String badge;

  const _DealCard({required this.title, required this.imageUrl, required this.oldPrice, required this.newPrice, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 192,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 128,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Center(child: Image.network(imageUrl, height: 96, fit: BoxFit.contain)),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(badge, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onTertiaryContainer)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(newPrice, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.tertiary)),
              const SizedBox(width: 8),
              Text(oldPrice, style: const TextStyle(fontSize: 10, decoration: TextDecoration.lineThrough, color: AppColors.onSurfaceVariant)),
            ],
          )
        ],
      ),
    );
  }
}
