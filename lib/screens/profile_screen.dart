import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

// ─── STORE BRAND HELPERS ─────────────────────────────────────────────────────

const _loyaltyCards = [
  _LoyaltyCardData(
    name: 'Albert Heijn',
    color: Color(0xFF00A0E2),
    code: '8712 3456 7890 1',
    isDark: false,
  ),
  _LoyaltyCardData(
    name: "Jumbo Extra's",
    color: Color(0xFFFFD800),
    code: '5432 1098 7654 3',
    isDark: true,
  ),
  _LoyaltyCardData(
    name: 'Lidl Plus',
    color: Color(0xFF0050AA),
    code: '1122 3344 5566 7',
    isDark: false,
  ),
];

class _LoyaltyCardData {
  final String name;
  final Color color;
  final String code;
  final bool isDark;
  const _LoyaltyCardData({
    required this.name,
    required this.color,
    required this.code,
    required this.isDark,
  });
}

// ─── SCREEN ──────────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notificationsEnabled = true;
  bool _fcmExpanded = false;
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _loadFcmToken();
  }

  Future<void> _loadFcmToken() async {
    // Only load FCM on supported platforms
    if (!kIsWeb && Platform.isLinux) return;
    try {
      final svc = NotificationService();
      // Re-use the token stored during init; triggers init if needed
      await svc.initializeAndSaveToken();
      // We cannot read the token back without modifying NotificationService,
      // so show a placeholder that shows it was registered
      if (mounted) setState(() => _fcmToken = 'Geregistreerd bij FCM ✓');
    } catch (_) {
      if (mounted) setState(() => _fcmToken = 'Niet beschikbaar op dit platform');
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Uitloggen?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'Je watchlist en instellingen blijven bewaard. '
          'Je kunt altijd opnieuw inloggen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuleren'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Uitloggen'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authServiceProvider).signOut();
      // Reset nav to Feed tab
      ref.read(navIndexProvider.notifier).setIndex(0);
      // On mobile, navigate to login screen
      if (!kIsWeb && !Platform.isLinux && mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync      = ref.watch(currentUserProvider);
    final watchlistAsync = ref.watch(watchlistNotifierProvider);

    // Compute live stats from providers
    final watchlistCount = watchlistAsync.value?.length ?? 0;
    final dealCount      = watchlistAsync.value
            ?.where((i) => i.hasActiveDeal)
            .length ??
        0;

    // Resolve user identity
    final user = userAsync.value;
    final isAnonymous = user?.isAnonymous ?? true;
    final displayName = user?.displayName ?? 'Anonieme Gebruiker';
    final email       = user?.email ?? '';
    final photoUrl    = user?.photoURL;
    final uid         = user?.uid ?? 'Niet beschikbaar';

    // Linux desktop bypass label
    final isLinuxDesktop = !kIsWeb && Platform.isLinux;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 80, bottom: 120),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header title ───────────────────────────────────────────
              Text(
                'Profiel',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.onSurface,
                    ),
              ),
              const SizedBox(height: 24),

              // ── Identity card ──────────────────────────────────────────
              _IdentityCard(
                displayName: displayName,
                email: email,
                photoUrl: photoUrl,
                isAnonymous: isAnonymous,
                isLinuxDesktop: isLinuxDesktop,
                uid: uid,
              ),
              const SizedBox(height: 24),

              // ── Live stats ─────────────────────────────────────────────
              _StatsRow(
                watchlistCount: watchlistCount,
                dealCount: dealCount,
              ),
              const SizedBox(height: 32),

              // ── Loyalty cards ──────────────────────────────────────────
              _SectionHeader(title: 'Mijn Klantenkaarten', onAction: () {}),
              const SizedBox(height: 16),
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: _loyaltyCards.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, i) =>
                      _LoyaltyCardWidget(data: _loyaltyCards[i]),
                ),
              ),
              const SizedBox(height: 32),

              // ── Settings ───────────────────────────────────────────────
              _SectionHeader(title: 'Instellingen'),
              const SizedBox(height: 16),

              // Notification toggle
              _SettingsTile(
                icon: Icons.notifications_active_rounded,
                iconColor: AppColors.primary,
                title: 'Watchlist Meldingen',
                subtitle: 'Ontvang pushberichten voor favorieten',
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: (v) =>
                      setState(() => _notificationsEnabled = v),
                  activeTrackColor: AppColors.primary,
                  thumbColor: WidgetStateProperty.all(Colors.white),
                ),
              ),
              const SizedBox(height: 12),

              // FCM Token section
              _FcmTokenTile(
                token: _fcmToken,
                expanded: _fcmExpanded,
                onToggle: () =>
                    setState(() => _fcmExpanded = !_fcmExpanded),
              ),
              const SizedBox(height: 16),

              // Menu items
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _MenuItem(
                      icon: Icons.store_mall_directory_rounded,
                      label: 'Mijn Winkels',
                      trailing: 'Amsterdam +2',
                    ),
                    _Divider(),
                    _MenuItem(
                      icon: Icons.account_circle_rounded,
                      label: 'Accountgegevens',
                      trailing: isAnonymous ? 'Anoniem' : email,
                    ),
                    _Divider(),
                    _MenuItem(
                      icon: Icons.security_rounded,
                      label: 'Beveiliging & Privacy',
                    ),
                    _Divider(),
                    _MenuItem(
                      icon: Icons.info_outline_rounded,
                      label: 'Over de app',
                      trailing: 'v1.0.0',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Sign-out button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isLinuxDesktop ? null : _confirmSignOut,
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.error,
                  ),
                  label: Text(
                    isLinuxDesktop ? 'Uitloggen (niet beschikbaar op Linux)' : 'Uitloggen',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    side: BorderSide(
                      color: AppColors.error.withAlpha(isLinuxDesktop ? 80 : 180),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── IDENTITY CARD ───────────────────────────────────────────────────────────

class _IdentityCard extends StatelessWidget {
  final String displayName;
  final String email;
  final String? photoUrl;
  final bool isAnonymous;
  final bool isLinuxDesktop;
  final String uid;

  const _IdentityCard({
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.isAnonymous,
    required this.isLinuxDesktop,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.orange600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  color: Colors.white.withAlpha(40),
                ),
                child: ClipOval(
                  child: photoUrl != null
                      ? Image.network(photoUrl!, fit: BoxFit.cover)
                      : Container(
                          color: Colors.white.withAlpha(60),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              // Anonymous / Google badge
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isAnonymous
                        ? AppColors.outlineVariant
                        : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    isAnonymous
                        ? Icons.person_outline_rounded
                        : Icons.gpp_good_rounded,
                    size: 14,
                    color: isAnonymous
                        ? Colors.white
                        : const Color(0xFF4285F4), // Google blue
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),

          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              email,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withAlpha(200),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Status badges row
          Wrap(
            spacing: 8,
            children: [
              _Badge(
                label: isLinuxDesktop
                    ? 'LINUX DESKTOP'
                    : isAnonymous
                        ? 'ANONIEM'
                        : 'GOOGLE',
                color: Colors.white.withAlpha(40),
                textColor: Colors.white,
              ),
              _Badge(
                label: 'UID: ${uid.length > 8 ? uid.substring(0, 8) : uid}…',
                color: Colors.white.withAlpha(30),
                textColor: Colors.white.withAlpha(200),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _Badge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// ─── STATS ROW ───────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int watchlistCount;
  final int dealCount;

  const _StatsRow({
    required this.watchlistCount,
    required this.dealCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          icon: Icons.favorite_rounded,
          value: '$watchlistCount',
          label: 'WATCHLIST',
          color: AppColors.tertiary,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.local_offer_rounded,
          value: '$dealCount',
          label: 'ACTIEVE DEALS',
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.savings_rounded,
          value: '€--',
          label: 'BESPAARD',
          color: const Color(0xFF2E7D32),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                value,
                key: ValueKey(value),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SECTION HEADER ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.onSurface,
          ),
        ),
        if (onAction != null)
          TextButton(
            onPressed: onAction,
            child: const Text(
              'Beheer',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── LOYALTY CARD ────────────────────────────────────────────────────────────

class _LoyaltyCardWidget extends StatelessWidget {
  final _LoyaltyCardData data;
  const _LoyaltyCardWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    final textColor = data.isDark ? AppColors.onSurface : Colors.white;
    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: data.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Icon(
                Icons.contactless_rounded,
                color: textColor.withAlpha(130),
                size: 22,
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                // Barcode placeholder
                Container(
                  height: 36,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      30,
                      (i) => Container(
                        width: i.isEven ? 2 : 1,
                        color: i.isEven ? Colors.black87 : Colors.black38,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data.code,
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 2.5,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
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

// ─── SETTINGS TILE ───────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

// ─── FCM TOKEN TILE ──────────────────────────────────────────────────────────

class _FcmTokenTile extends StatelessWidget {
  final String? token;
  final bool expanded;
  final VoidCallback onToggle;

  const _FcmTokenTile({
    required this.token,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: expanded
              ? Border.all(color: AppColors.primary.withAlpha(80))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_rounded,
                    color: AppColors.secondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FCM Push Token',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        'Tik om de status te bekijken',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: expanded ? 0.5 : 0,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.outline,
                  ),
                ),
              ],
            ),
            if (expanded) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.outlineVariant.withAlpha(80),
                  ),
                ),
                child: SelectableText(
                  token ?? 'Laden...',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: token != null
                      ? () {
                          Clipboard.setData(ClipboardData(text: token!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Token gekopieerd!'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Kopieer'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── MENU ITEM ───────────────────────────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;

  const _MenuItem({required this.icon, required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.onSurfaceVariant, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.outlineVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 56,
      endIndent: 16,
      color: AppColors.surfaceContainerLow,
    );
  }
}
