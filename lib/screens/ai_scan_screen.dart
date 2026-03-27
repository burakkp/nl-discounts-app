import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';

class AIScanScreen extends ConsumerWidget {
  const AIScanScreen({super.key});

  Future<void> _takePhotoAndUpload(BuildContext context, WidgetRef ref, {bool fromGallery = false}) async {
    final locationAsync = ref.read(locationProvider);

    if (!locationAsync.hasValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot upload: GPS location not found yet.')),
      );
      return;
    }

    final position = locationAsync.value!;
    final ImagePicker picker = ImagePicker();

    ImageSource source = fromGallery ? ImageSource.gallery : ImageSource.camera;
    if (!kIsWeb && Platform.isLinux && !fromGallery) {
      print('💻 Linux detected. Opening File Explorer instead of camera...');
      source = ImageSource.gallery;
    }

    final XFile? photo = await picker.pickImage(source: source);

    if (photo != null) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        File imageFile = File(photo.path);
        final apiService = ref.read(apiServiceProvider);

        // using user id 1 for mock purposes as before
        final result = await apiService.uploadCrowdsourceDeal(
          1, position.latitude, position.longitude, imageFile
        );

        if (context.mounted) Navigator.pop(context); // Close dialog

        final aiData = result['deal_added'];
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ AI Found: ${aiData['product_name']} at €${aiData['price']}!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
          ref.invalidate(discountsProvider);
        }
      } catch (e) {
        if (context.mounted) Navigator.pop(context);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Upload failed: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 100, bottom: 120, left: 16, right: 16),
        child: Column(
          children: [
            // Neighborhood Badge
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, size: 14, color: AppColors.onSecondaryContainer),
                    const SizedBox(width: 8),
                    Text(
                      'YOUR LOCAL AMSTERDAM STORE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.onSecondaryContainer, fontSize: 10, letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Header
            Text('Vision Agent', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text(
              'Capture "ghost" discounts the official leaflets missed.',
              style: TextStyle(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),

            // Scanner Area (Mockup visual)
            AspectRatio(
              aspectRatio: 4 / 5,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
                  border: Border.all(color: Colors.white, width: 4),
                  image: const DecorationImage(
                    image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuCLSt2566idiDewdnZWGyUa8ZOllOnYUxcfTAH9e7yJ9RaEcDgrGCuFd9L7Y5J1VVzbvooC4TvNohNkVCcSuj87dYoEi-i7fgyt7d0B1Md7MHGHd6Gdz9PNfz_HzhLkbJAvoNrmlRuSdJFiq4UkrI2Y9XuRhJes1ueZU1-RVMhw9pw5Bvr7BHkdXe9JpRJDVopEdsjvHcK-QOSuH9XklsPMbIppGzsxw1jLUmnh6iN2tjNCPU5HYQTtgBWg7w-nYI6gfE2l2lle_KM0'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Container(color: Colors.black12),
                    // Scanner Line
                    Positioned(
                      top: MediaQuery.of(context).size.width * 0.5,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Colors.transparent, AppColors.primaryContainer, Colors.transparent]),
                          boxShadow: [BoxShadow(color: AppColors.primaryContainer.withOpacity(0.5), blurRadius: 15, spreadRadius: 2)],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 24,
                      left: 24,
                      right: 24,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(16)),
                                  child: const Text('AI EXTRACTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onPrimaryContainer, letterSpacing: 1.2)),
                                ),
                                const Row(
                                  children: [
                                    Icon(Icons.bolt, size: 12),
                                    Text(' PROCESSING...', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant, letterSpacing: 1.2)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('PRODUCT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant)),
                                    Text('Organic Red Bell Peppers (3ct)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Icon(Icons.check_circle, color: AppColors.primary),
                              ],
                            ),
                            const Divider(),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('STORE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant)),
                                    Text('Albert Heijn - Dam Square', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Icon(Icons.check_circle, color: AppColors.primary),
                              ],
                            ),
                            const Divider(),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('EXTRACTED PRICE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant)),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('€ 1,89', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.tertiary)),
                                        SizedBox(width: 8),
                                        Text('€ 2,95', style: TextStyle(fontSize: 14, decoration: TextDecoration.lineThrough, color: AppColors.onSurfaceVariant)),
                                      ],
                                    ),
                                  ],
                                ),
                                ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryContainer,
                                    foregroundColor: AppColors.onPrimaryContainer,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                  child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Main Scan Action
            InkWell(
              onTap: () => _takePhotoAndUpload(context, ref, fromGallery: false),
              borderRadius: BorderRadius.circular(32),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 20)],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(color: Colors.white30, shape: BoxShape.circle),
                      child: const Icon(Icons.photo_camera, size: 36, color: AppColors.onPrimaryContainer),
                    ),
                    const SizedBox(height: 12),
                    Text('Scan Receipt or Price Tag', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Options
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _takePhotoAndUpload(context, ref, fromGallery: true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload, color: AppColors.onSurfaceVariant),
                          SizedBox(width: 8),
                          Text('Gallery', style: TextStyle(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, color: AppColors.onSurfaceVariant),
                          SizedBox(width: 8),
                          Text('Drafts', style: TextStyle(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Recent Contributions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Contributions', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const Text('View All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                _GalleryCard(
                  imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCt4BI84qCvXebM2VPTzGObatvHKLZZyO5y9ePmLfcEQ5SwHcxQrCBOr1KkmaUDcFQ_1DlMleY6pKO4ED9FefWPfQB9htrIfnkswDifWv_N67weXuY32vU2EVCNHJ7Dft3arLsh7hBFIwKOg9D50_KBUhydALyZE2h9HZ-YxonPunkiv2kUu_mko3YafG9WrMDXyJ7poEUgcecfkiONf9y9kjAjNbWmU4B3iO8zCtAO742AGdcxGUKz73onxhoiqH4fYKoY1KWwYhh2',
                  title: 'Weekly Groceries',
                  subtitle: 'JUMBO • 2h ago',
                  verified: true,
                ),
                const SizedBox(width: 16),
                _GalleryCard(
                  imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuA6QZ2lwbreY1ff9TAp6xcs0XtcZZHVQVlXImZeBr2VLezsnyHUmBSaKTK753Vl1CEM33QTxmu5RtucgimhgFA6TnXKjkTEPjK2QC5zfxwwZRhzl7NyUQVsv4F4dRo2Lz7ykYBfxlOLkWxhypxiO5xwLVlO2t-zdHG3xthY1WJg66sUpFrmQBzpS6EZjkzET4CFCqRAntAxEpX2qx3-QPl3h2TVlac8YITJZPqIXzD9suvVq2hJapfAlIZRDllu2dKBbv76gc77QCK6',
                  title: 'Lidl Price Drop',
                  subtitle: 'LIDL • 5h ago',
                  verified: false,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _GalleryCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final bool verified;

  const _GalleryCard({required this.imageUrl, required this.title, required this.subtitle, required this.verified});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: verified ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(verified ? 'VERIFIED' : 'PROCESSING', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
