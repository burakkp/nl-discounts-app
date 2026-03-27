import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/app_providers.dart';
import 'services/notification_service.dart';

// Screens
import 'screens/home_feed_screen.dart';
import 'screens/map_view_screen.dart';
import 'screens/watchlist_screen.dart';
import 'screens/ai_scan_screen.dart';
import 'screens/profile_screen.dart';

// Theme
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Skip Firebase initialization on Linux Desktop because the native plugin isn't supported.
  if (kIsWeb || !Platform.isLinux) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    print('⚠️ Running on Linux Desktop. Firebase initialization skipped.');
  }

  runApp(const ProviderScope(child: NederlandDiscountsApp()));
}

class NederlandDiscountsApp extends StatelessWidget {
  const NederlandDiscountsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NL Discounts',
      theme: AppTheme.lightTheme,
      home: (!kIsWeb && Platform.isLinux)
          ? const MainDashboard()
          : (FirebaseAuth.instance.currentUser == null
              ? const LoginScreen()
              : const MainDashboard()),
    );
  }
}

class MainDashboard extends ConsumerStatefulWidget {
  const MainDashboard({super.key});

  @override
  ConsumerState<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends ConsumerState<MainDashboard> {

  @override
  void initState() {
    super.initState();
    // Fire and forget the notification handshake
    NotificationService().initializeAndSaveToken();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navIndexProvider);

    final screens = [
      const HomeFeedScreen(),
      const MapViewScreen(),
      const WatchlistScreen(),
      const AIScanScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true, // Crucial for floating/transparent bottom nav overlaying content
      body: screens[currentIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.onSurface.withOpacity(0.95), // Floating dark pill
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 5))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavBarIcon(icon: Icons.home_filled, index: 0, currentIndex: currentIndex, label: 'Feed', ref: ref),
            _NavBarIcon(icon: Icons.map, index: 1, currentIndex: currentIndex, label: 'Kaart', ref: ref),
            _NavBarIcon(icon: Icons.add_circle, index: 3, currentIndex: currentIndex, label: 'Scan', isSpecial: true, ref: ref),
            _NavBarIcon(icon: Icons.favorite, index: 2, currentIndex: currentIndex, label: 'Lijst', ref: ref),
            _NavBarIcon(icon: Icons.person, index: 4, currentIndex: currentIndex, label: 'Profiel', ref: ref),
          ],
        ),
      ),
    );
  }
}

class _NavBarIcon extends StatelessWidget {
  final IconData icon;
  final int index;
  final int currentIndex;
  final String label;
  final bool isSpecial;
  final WidgetRef ref;

  const _NavBarIcon({
    required this.icon, required this.index, required this.currentIndex, required this.label, this.isSpecial = false, required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;

    if (isSpecial) {
      return GestureDetector(
        onTap: () => ref.read(navIndexProvider.notifier).state = index,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.onPrimaryContainer, size: 28),
        ),
      );
    }

    return GestureDetector(
      onTap: () => ref.read(navIndexProvider.notifier).state = index,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? Colors.white : AppColors.outlineVariant, size: 24),
          if (isSelected) ...[
            const SizedBox(height: 4),
            Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.tertiaryContainer, shape: BoxShape.circle)),
          ]
        ],
      ),
    );
  }
}
