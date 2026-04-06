import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F8), // Background matches surface-bright
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false, // In case it's in a bottom nav
        title: Row(
          children: [
            const Icon(Icons.storefront, color: Color(0xFFE97600)),
            const SizedBox(width: 8),
            const Text(
              'The Digital Marktkraam',
              style: TextStyle(
                color: Color(0xFF2B2F30),
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.grey),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            children: [
              _buildProfileSection(),
              const SizedBox(height: 32),
              _buildStatsSection(),
              const SizedBox(height: 32),
              _buildLoyaltyCards(),
              const SizedBox(height: 32),
              _buildSettingsMenu(),
              const SizedBox(height: 48), // Bottom padding for navbar leeway
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
                image: const DecorationImage(
                  // Example placeholder from HTML image.
                  image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuDR4jcviUmx1x36IJEb4N0KKFnqThU7HvLp7Ixx6Rkiav9vyF58K3zW1LdeJBcjtPzt1EMtPTsMjlnTYxtp2x5RrXnAUaHQF46oYwqXWHiPwMwcP_aioWtFUqDJKAC3h8MY4yH88WgQ1TyeZsujAxsdDsH-vSBL8LCRGS3aiQviMgCA2hK3SX7iycoJHycC99ILJuUdxR_G-rY5c7DsVxHiWkHvwyf58DOI1TMA6TmkGokoxbfnz8oYX3i0EypX69143T50eI0bJQdj'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFD8100), // primary-container
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Sander de Vries',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Color(0xFF2B2F30), // text-on-surface
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFF9288), // tertiary-container
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Bespaard: €142.50',
            style: TextStyle(
              color: Color(0xFF690006), // on-tertiary-container
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatCard(Icons.notifications_active, '12', 'ALERTS'),
        _buildStatCard(Icons.wallet, '4', 'LOYALTY'),
        _buildStatCard(Icons.local_mall, '86', 'DEALS'),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2B2F30).withOpacity(0.06),
              blurRadius: 32,
              offset: const Offset(0, 12),
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFFD8100)), // primary-fixed
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2B2F30),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF585C5D), // on-surface-variant
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoyaltyCards() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mijn Klantenkaarten',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Beheer',
                style: TextStyle(
                  color: Color(0xFF914700), // primary
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 170, // Slightly taller to match HTML layout
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _buildLoyaltyCard(
                'Albert Heijn',
                const Color(0xFF00ADEF),
                '8712345678901',
                barcodeUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDDtlBnt96s7c7vQQ5Bh-LhnIz12L8Hxsg1C6CCWe5yJdoMB10OoR0gy6uGpWB3f37-euN2D8Pmc24kRwa55Zmopvzi_Xk8QfgLkxgkXbo2YgERsnSnfN-oNm1GKtvOTT1CWWV3ZD_MT29MLZqMf5wJWQ0NR_VX_LGp13g7rAlgfDW-N-E75m8yCq4gpp_TeZidynj7cPGrHbMTb0gvZXIPJuT7tmozD1rMIvNwDECqcrM-npoFvooG-vRKvyv9GIwA2mmxGIH0p_AX',
              ),
              const SizedBox(width: 16),
              _buildLoyaltyCard(
                'Jumbo Extra\'s',
                const Color(0xFFEEB700),
                '5432109876543',
                isDark: true,
                barcodeUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCgpyA5f7ix4-Oir61wl5G74cUlJgTnhVmSXd_O3bQdc_XNgQID_e167GyKD_G6n3mZeOOCI5-41MH3m2XYDUez26E3z6Gd6jod8mdCmUfEvvlwCn0iF4mdXvDpJknK7NUyTC-PmJoJNKFQ1ggxRcItvsQs4hYP17MX0xs6Je1S8o7X6oJ0uiR4TUN2fG9J8tKpRUh_xgQVpuQBQwnXoegknFp5SllaW4OjLurIABOTgwbrfbgF0VvPCFlBE7ltmbMvMcpL8qPSE-9c',
              ),
              const SizedBox(width: 16),
              _buildLoyaltyCard(
                'Lidl Plus',
                const Color(0xFF0050AA),
                '1122334455667',
                barcodeUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAG6WV7IrOFoeNfHCK1idP4sTco0adtKR7TQ6_vaQSO-rLkEEZcPiccmP5bKQv9kwAinoyv-HWIwrR6vIVDN8pE982M6ePWQoOqQvSysh668JLiierfIQMmhSAZjOL9c7z2DA6xoLBhrog0LcFvG_MoLyXEv8VLEw0GRG4G64pZaaAFqK0Hk04ic9bdlmsLrgJ--PHA4CXsrq4rrfu_ba95CnGeCvprpuD1JSortykr2mXHFd1gcjdZNhc1n0BEAb4_-NRdnzD0Lw46',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoyaltyCard(
      String name, Color color, String code,
      {bool isDark = false, required String barcodeUrl}) {
    return Container(
      width: 270,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
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
                name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFF2B2F30) : Colors.white,
                ),
              ),
              Icon(
                Icons.contactless,
                color: (isDark ? Colors.black : Colors.white).withOpacity(0.5),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Container(
                  height: 40,
                  width: double.infinity,
                  color: Colors.grey[100],
                  child: Image.network(
                    barcodeUrl,
                    fit: BoxFit.cover,
                    color: Colors.black.withOpacity(0.8), // Equivalent to mix-blend-multiply opacity-80
                    colorBlendMode: BlendMode.dstIn,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  code,
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 3, // tracking-[0.3em]
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A), // slate-900
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Instellingen',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        // Switch Tile
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF1F2), // surface-container-low
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFD8100).withOpacity(0.2), // primary-container/20
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.notification_important, color: Color(0xFFFD8100)),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Watchlist Meldingen',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Ontvang pushberichten voor favorieten',
                      style: TextStyle(fontSize: 12, color: Color(0xFF585C5D)),
                    ),
                  ],
                ),
              ),
              Switch(
                value: true,
                onChanged: (v) {},
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFFFD8100),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Menu list
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: [
              _buildListTile(Icons.store, 'Mijn Winkels', trailingText: 'Utrecht +3'),
              const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFEEF1F2)),
              _buildListTile(Icons.account_circle, 'Accountgegevens'),
              const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFEEF1F2)),
              _buildListTile(Icons.security, 'Beveiliging & Privacy'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Logout
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Uitloggen',
              style: TextStyle(
                color: Color(0xFFB02500), // text-error
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListTile(IconData icon, String title, {String? trailingText}) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF585C5D)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B2F30)),
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText,
                style: const TextStyle(color: Color(0xFF585C5D), fontSize: 14),
              ),
            if (trailingText != null) const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFF585C5D), size: 20),
          ],
        ),
      ),
    );
  }
}
