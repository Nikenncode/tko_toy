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

// // HOME TAB
// class _HomeTab extends StatelessWidget {
//   const _HomeTab();
//
//   Stream<DocumentSnapshot<Map<String, dynamic>>> _settings$() =>
//       FirebaseFirestore.instance.doc('settings/general').snapshots();
//
//   Stream<DocumentSnapshot<Map<String, dynamic>>> _user$() {
//     final uid = FirebaseAuth.instance.currentUser!.uid;
//     return FirebaseFirestore.instance.doc('users/$uid').snapshots();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final name = FirebaseAuth.instance.currentUser?.displayName ??
//         (FirebaseAuth.instance.currentUser?.email?.split('@').first ??
//             'Member');
//
//     return Stack(
//       children: [
//         Positioned.fill(
//           child: Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment(-1, -1),
//                 end: Alignment(1, 1),
//                 colors: [Colors.white, tkoCream],
//               ),
//             ),
//           ),
//         ),
//         Positioned(
//           left: -90,
//           top: -80,
//           child: _bubble(220, tkoOrange.withOpacity(.10)),
//         ),
//         Positioned(
//           right: -70,
//           bottom: -40,
//           child: _bubble(180, tkoTeal.withOpacity(.10)),
//         ),
//         Positioned(
//           right: 16,
//           top: 64,
//           child: _bubble(70, tkoGold.withOpacity(.16)),
//         ),
//
//         StreamBuilder(
//           stream: _settings$(),
//           builder: (context, sSnap) {
//             if (!sSnap.hasData) {
//               return const Center(
//                 child: CircularProgressIndicator(color: tkoBrown),
//               );
//             }
//             final settings = sSnap.data!.data() ?? {};
//
//             final tiers = (settings['tiers'] as List? ?? [])
//                 .map((e) => _Tier.fromMap(Map<String, dynamic>.from(e)))
//                 .toList()
//               ..sort((a, b) => a.min.compareTo(b.min));
//
//             final perks = (settings['perks'] as List? ?? [])
//                 .map((e) => _Perk.fromMap(Map<String, dynamic>.from(e)))
//                 .toList();
//
//             final discountsMap =
//             Map<String, dynamic>.from(settings['discounts'] ?? {});
//             final earnMultipliers =
//             Map<String, dynamic>.from(settings['earnMultipliers'] ?? {});
//
//             return StreamBuilder(
//               stream: _user$(),
//               builder: (context, uSnap) {
//                 if (!uSnap.hasData) {
//                   return const Center(
//                     child: CircularProgressIndicator(color: tkoBrown),
//                   );
//                 }
//                 if (!uSnap.data!.exists) {
//                   FirebaseFirestore.instance
//                       .doc('users/${FirebaseAuth.instance.currentUser!.uid}')
//                       .set(
//                     {'tier': 'Featherweight', 'yearPoints': 0, 'lifetimePts': 0},
//                     SetOptions(merge: true),
//                   );
//                   return const Center(
//                     child: CircularProgressIndicator(color: tkoBrown),
//                   );
//                 }
//
//                 final u = uSnap.data!.data()!;
//                 final yearPts = (u['yearPoints'] ?? 0) as int;
//                 final curTier = _currentTier(tiers, yearPts);
//                 final nextThresh = _nextThreshold(tiers, yearPts);
//                 final toNext = nextThresh == null ? 0 : (nextThresh - yearPts);
//                 final progress = nextThresh == null
//                     ? 1.0
//                     : (yearPts / nextThresh).clamp(0, 1).toDouble();
//                 final earnX =
//                 ((earnMultipliers[curTier.name] ?? 1.0) as num).toDouble();
//
//                 final double posterHeight =
//                     (MediaQuery.of(context).size.width - 32) * 0.48;
//
//                 return CustomScrollView(
//                   slivers: [
//                     SliverToBoxAdapter(
//                       child: Padding(
//                         padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Hello,',
//                               style: TextStyle(
//                                 color: Colors.black.withOpacity(.55),
//                                 fontSize: 13,
//                               ),
//                             ),
//                             const SizedBox(height: 2),
//                             Text(
//                               '$name.',
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: const TextStyle(
//                                 fontSize: 22,
//                                 fontWeight: FontWeight.w900,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//
//                     SliverToBoxAdapter(
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 16),
//                         child: _TierCard(
//                           tier: curTier.name,
//                           yearPoints: yearPts,
//                           toNextPoints: toNext,
//                           progress: progress,
//                           earnX: earnX,
//                           tiers: tiers,
//                         ),
//                       ),
//                     ),
//                     const SliverToBoxAdapter(child: SizedBox(height: 14)),
//
//                     SliverToBoxAdapter(
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 16),
//                         child: _PosterCarousel(height: posterHeight),
//                       ),
//                     ),
//                     const SliverToBoxAdapter(child: SizedBox(height: 14)),
//
//                     SliverToBoxAdapter(
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 16),
//                         child: _ActionGrid(
//                           yearPts: yearPts,
//                           tiers: tiers,
//                           perks: perks,
//                           discountsMap: discountsMap,
//                         ),
//                       ),
//                     ),
//                     const SliverToBoxAdapter(child: SizedBox(height: 18)),
//                   ],
//                 );
//               },
//             );
//           },
//         ),
//       ],
//     );
//   }
// }
//
// // Tier/Perk
// class _Tier {
//   final String name;
//   final int min;
//   const _Tier({required this.name, required this.min});
//   factory _Tier.fromMap(Map<String, dynamic> m) =>
//       _Tier(name: m['name'] as String, min: (m['min'] as num).toInt());
// }
//
// class _Perk {
//   final String title;
//   final String description;
//   final String minTierName;
//   const _Perk({
//     required this.title,
//     required this.description,
//     required this.minTierName,
//   });
//   factory _Perk.fromMap(Map<String, dynamic> m) => _Perk(
//     title: m['title'] ?? m['name'] ?? '',
//     description: m['description'] ?? '',
//     minTierName: m['minTier'] ?? m['minTierName'] ?? 'Featherweight',
//   );
// }
//
// _Tier _currentTier(List<_Tier> tiers, int pts) {
//   _Tier cur = tiers.first;
//   for (final t in tiers) {
//     if (pts >= t.min) cur = t;
//   }
//   return cur;
// }
//
// int? _nextThreshold(List<_Tier> tiers, int pts) {
//   for (final t in tiers) {
//     if (pts < t.min) return t.min;
//   }
//   return null;
// }
//
// int _tierIndexByName(List<_Tier> tiers, String name) =>
//     tiers.indexWhere((t) => t.name.toLowerCase() == name.toLowerCase());
//
// //Tier card
// class _TierCard extends StatelessWidget {
//   final String tier;
//   final int yearPoints;
//   final int toNextPoints;
//   final double progress;
//   final double earnX;
//   final List<_Tier> tiers;
//
//   const _TierCard({
//     required this.tier,
//     required this.yearPoints,
//     required this.toNextPoints,
//     required this.progress,
//     required this.earnX,
//     required this.tiers,
//   });
//
//   Color get _tierColor {
//     switch (tier.toLowerCase()) {
//       case 'lightweight':
//         return tkoGold;
//       case 'welterweight':
//         return tkoOrange;
//       case 'heavyweight':
//         return tkoBrown;
//       case 'reigning champion':
//         return tkoTeal;
//       default:
//         return tkoTeal;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final curIdx = _tierIndexByName(tiers, tier);
//     final nextIdx =
//     (curIdx != -1 && curIdx + 1 < tiers.length) ? curIdx + 1 : curIdx;
//     final nextName =
//     (nextIdx > curIdx) ? tiers[nextIdx].name : 'Top tier';
//     final pct = (progress.clamp(0, 1) * 100).round();
//
//     return LayoutBuilder(
//       builder: (_, constraints) {
//         final compact = constraints.maxWidth < 360;
//
//         return Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(24),
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 tkoTeal.withOpacity(.20),
//                 tkoOrange.withOpacity(.18),
//                 Colors.white,
//               ],
//             ),
//             boxShadow: const [
//               BoxShadow(
//                 color: Color(0x22000000),
//                 blurRadius: 22,
//                 offset: Offset(0, 12),
//               ),
//             ],
//           ),
//           child: Column(
//             children: [
//               Row(
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Tiering',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.black.withOpacity(.55),
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           tier,
//                           style: TextStyle(
//                             fontSize: compact ? 18 : 20,
//                             fontWeight: FontWeight.w800,
//                             color: tkoBrown,
//                           ),
//                         ),
//                         const SizedBox(height: 6),
//                         Text(
//                           '$yearPoints pts',
//                           style: TextStyle(
//                             fontSize: compact ? 18 : 20,
//                             fontWeight: FontWeight.w900,
//                             color: Colors.black,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           toNextPoints <= 0
//                               ? 'You’re at the highest tier for this year.'
//                               : 'Get $toNextPoints more points to reach $nextName.',
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.black.withOpacity(.75),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   const SizedBox(width: 16),
//
//                   SizedBox(
//                     width: compact ? 74 : 84,
//                     height: compact ? 74 : 84,
//                     child: Stack(
//                       alignment: Alignment.center,
//                       children: [
//                         Container(
//                           width: compact ? 74 : 84,
//                           height: compact ? 74 : 84,
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             gradient: RadialGradient(
//                               colors: [
//                                 _tierColor.withOpacity(.75),
//                                 _tierColor.withOpacity(.0),
//                               ],
//                             ),
//                           ),
//                         ),
//                         Container(
//                           width: compact ? 58 : 64,
//                           height: compact ? 58 : 64,
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             gradient: LinearGradient(
//                               begin: Alignment.topLeft,
//                               end: Alignment.bottomRight,
//                               colors: [
//                                 Colors.white,
//                                 _tierColor.withOpacity(.8),
//                               ],
//                             ),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: _tierColor.withOpacity(.4),
//                                 blurRadius: 16,
//                                 offset: const Offset(0, 6),
//                               ),
//                             ],
//                           ),
//                           child: ClipOval(
//                             child: Padding(
//                               padding: const EdgeInsets.all(6.0),
//                               child: Image.asset(
//                                 'assets/branding/tko_logo.png',
//                                 fit: BoxFit.contain,
//                                 color: Colors.white,
//                                 colorBlendMode: BlendMode.srcATop,
//                                 errorBuilder: (_, __, ___) => Icon(
//                                   Icons.sports_mma,
//                                   color: Colors.white,
//                                   size: compact ? 26 : 30,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                         const Positioned(
//                           right: 4,
//                           top: 8,
//                           child: Icon(
//                             Icons.auto_awesome,
//                             size: 16,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//
//               const SizedBox(height: 12),
//
//               // progress bar
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         '$pct% to next',
//                         style: TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.w700,
//                           color: _tierColor,
//                         ),
//                       ),
//                       Text(
//                         '${earnX.toStringAsFixed(2)}x pts per \$1',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.black.withOpacity(.7),
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 6),
//                   Container(
//                     height: 14,
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(.9),
//                       borderRadius: BorderRadius.circular(999),
//                     ),
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(999),
//                       child: LinearProgressIndicator(
//                         value: progress.clamp(0, 1),
//                         backgroundColor: Colors.transparent,
//                         valueColor:
//                         AlwaysStoppedAnimation<Color>(_tierColor),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         tier,
//                         style: const TextStyle(
//                           fontSize: 11,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       Text(
//                         nextName,
//                         style: const TextStyle(
//                           fontSize: 11,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
//
// // Action area
// class _ActionGrid extends StatelessWidget {
//   final int yearPts;
//   final List<_Tier> tiers;
//   final List<_Perk> perks;
//   final Map<String, dynamic> discountsMap;
//
//   const _ActionGrid({
//     required this.yearPts,
//     required this.tiers,
//     required this.perks,
//     required this.discountsMap,
//   });
//
//   void _openBenefits(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (_) => _BenefitsSheet(
//         currentPoints: yearPts,
//         tiers: tiers,
//         perks: perks,
//         discountsMap: discountsMap,
//       ),
//     );
//   }
//
//   void _openQuickScan(BuildContext context) {
//     final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
//     final code = 'TKO:$uid';
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       backgroundColor: Colors.white,
//       builder: (_) => Padding(
//         padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 40,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: Colors.black12,
//                 borderRadius: BorderRadius.circular(20),
//               ),
//             ),
//             const SizedBox(height: 12),
//             const Text(
//               'Quick Scan',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
//             ),
//             const SizedBox(height: 12),
//             QrImageView(data: code, size: 200),
//             const SizedBox(height: 8),
//             const Text(
//               'Show this at checkout to earn or redeem points.',
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         GridView.count(
//           crossAxisCount: 2,
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           crossAxisSpacing: 12,
//           mainAxisSpacing: 12,
//           childAspectRatio: 1.5,
//           children: [
//             _PrimaryActionCard(
//               icon: Icons.workspace_premium_rounded,
//               label: 'Benefits',
//               subtitle: 'See what you’ve unlocked',
//               startColor: tkoOrange.withOpacity(.20),
//               endColor: tkoGold.withOpacity(.65),
//               onTap: () => _openBenefits(context),
//             ),
//             _PrimaryActionCard(
//               icon: Icons.shopping_bag_outlined,
//               label: 'Order',
//               subtitle: 'Place or view orders',
//               startColor: tkoTeal.withOpacity(.18),
//               endColor: tkoTeal.withOpacity(.60),
//               onTap: () {
//                 // TODO: navigate to order screen
//               },
//             ),
//             _PrimaryActionCard(
//               icon: Icons.qr_code_scanner_rounded,
//               label: 'Scan',
//               subtitle: 'Earn & redeem fast',
//               startColor: tkoOrange.withOpacity(.22),
//               endColor: tkoBrown.withOpacity(.55),
//               onTap: () => _openQuickScan(context),
//             ),
//             _PrimaryActionCard(
//               icon: SimpleIcons.discord,
//               label: 'Discord',
//               subtitle: 'Connect with the community',
//               startColor: tkoTeal.withOpacity(.16),
//               endColor: tkoTeal.withOpacity(.55),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => const DiscordPage()),
//                 );
//               },
//             ),
//           ],
//         ),
//         const SizedBox(height: 14),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: const [
//             _PillAction(
//               icon: Icons.history,
//               label: 'Activity',
//             ),
//             SizedBox(width: 10),
//             _PillAction(
//               icon: Icons.support_agent,
//               label: 'Support',
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }
//
// class _PrimaryActionCard extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final String subtitle;
//   final Color startColor;
//   final Color endColor;
//   final VoidCallback? onTap;
//
//   const _PrimaryActionCard({
//     required this.icon,
//     required this.label,
//     required this.subtitle,
//     required this.startColor,
//     required this.endColor,
//     this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(18),
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(18),
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               Colors.white,
//               startColor,
//               endColor,
//             ],
//           ),
//           boxShadow: const [
//             BoxShadow(
//               color: Color(0x19000000),
//               blurRadius: 12,
//               offset: Offset(0, 6),
//             )
//           ],
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 32,
//               height: 32,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: Colors.white.withOpacity(.92),
//               ),
//               child: Icon(icon, size: 18, color: tkoBrown),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     label,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: const TextStyle(
//                       fontWeight: FontWeight.w800,
//                       color: Colors.white,
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     subtitle,
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       fontSize: 11,
//                       color: Colors.white.withOpacity(.94),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class _PillAction extends StatelessWidget {
//   final IconData icon;
//   final String label;
//
//   const _PillAction({required this.icon, required this.label});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(999),
//         boxShadow: const [
//           BoxShadow(
//             color: Colors.black12,
//             blurRadius: 8,
//             offset: Offset(0, 3),
//           )
//         ],
//       ),
//       child: Row(
//         children: [
//           Icon(icon, size: 18, color: tkoBrown),
//           const SizedBox(width: 6),
//           Text(
//             label,
//             style: const TextStyle(
//               fontWeight: FontWeight.w600,
//               fontSize: 12,
//               color: tkoBrown,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// Widget _bubble(double size, Color c) => Container(
//   width: size,
//   height: size,
//   decoration: BoxDecoration(color: c, shape: BoxShape.circle),
// );


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
            // _NavItem(
            //   icon: Icons.auto_awesome_outlined,
            //   activeIcon: Icons.auto_awesome,
            //   label: 'Discover',
            // ),
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
