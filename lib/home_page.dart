// lib/home_page.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';


// Brand colors (TKO)
const tkoOrange = Color(0xFFFF6A00);
const tkoCream  = Color(0xFFF7F2EC);
const tkoBrown  = Color(0xFF6A3B1A);
const tkoTeal   = Color(0xFF00B8A2);
const tkoGold   = Color(0xFFFFD23F);

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[

    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,

        title: index == 1
            ? const SizedBox.shrink()
            : SizedBox(
          height: 36,
          child: Image.asset(
            'assets/branding/tko_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Text(
              'TKO TOY CO.',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
                color: tkoBrown,
              ),
            ),
          ),
        ),

        actions: index == 1
            ? const []
            : [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none,
              color: Colors.black87,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.account_circle_outlined,
              color: Colors.black87,
            ),
          ),
        ],
      ),

      body: SafeArea(child: pages[index]),

      bottomNavigationBar: TkoBottomNav(
        index: index,
        onChanged: (i) => setState(() => index = i),
      ),
      backgroundColor: Colors.white,
    );
  }
}


// BRAND BOTTOM NAV
class TkoBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const TkoBottomNav({
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        decoration: const BoxDecoration(
          color: tkoCream,
          boxShadow: [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 14,
              offset: Offset(0, -6),
            )
          ],
        ),
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Home',
              isActive: index == 0,
              onTap: () => onChanged(0),
            ),
            _NavItem(
              icon: Icons.qr_code_2_outlined,
              activeIcon: Icons.qr_code_2,
              label: 'Scan',
              isActive: index == 1,
              onTap: () => onChanged(1),
            ),
            _NavItem(
              icon: Icons.auto_awesome_outlined,
              activeIcon: Icons.auto_awesome,
              label: 'Discover',
            ),
            _NavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Profile',
              isActive: index == 3,
              onTap: () => onChanged(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: isActive
                ? const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              )
            ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: isActive ? 22 : 20,
                color: isActive ? tkoBrown : Colors.black54,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? tkoBrown : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
