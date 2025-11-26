import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:simple_icons/simple_icons.dart';

import 'profile_page.dart';
import 'membership_qr_page.dart';
import 'discord_page.dart';
import 'products_page.dart';
import 'discover_page.dart';
import 'notification_service.dart';
import 'notifications_page.dart';
import 'cart_page.dart';
import 'my_orders_page.dart';


const tkoOrange = Color(0xFFFF6A00);
const tkoCream = Color(0xFFF7F2EC);
const tkoBrown = Color(0xFF6A3B1A);
const tkoTeal = Color(0xFF00B8A2);
const tkoGold = Color(0xFFFFD23F);

class HomePage extends StatefulWidget {
  final int initialTab;

  const HomePage({super.key, this.initialTab = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int index;

  @override
  void initState() {
    super.initState();
    index = widget.initialTab;
    _initPushNotifications();
  }

  Future<void> _initPushNotifications() async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await messaging.getToken();
    debugPrint('FCM TOKEN: $token');

    final uid = FirebaseAuth.instance.currentUser?.uid;

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('🔥 FCM onMessage received!');
      final notif = message.notification;

      if (uid != null && notif != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('notifications')
            .add({
          'title': notif.title ?? 'New update',
          'body': notif.body ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (notif != null) {
        await NotificationService.showBasic(
          title: notif.title ?? 'New update',
          body: notif.body ?? '',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _HomeTab(),
      const MembershipQRPage(),
      const _DiscoverTab(),
      const ProfileCardTab(),
    ];

    return Scaffold(
      backgroundColor: tkoCream,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(.96),
        elevation: 0,
        centerTitle: true,
        titleSpacing: 0,
        title: SizedBox(
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
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              );
            },
            icon: const Icon(Icons.notifications_none, color: Colors.black87),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartPage()),
              );
            },
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black87),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.black.withOpacity(.04),
          ),
        ),
      ),
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: TkoBottomNav(
        index: index,
        onChanged: (i) {
          if (i == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const OffersListScreen()),
            );
            return;
          }
          setState(() => index = i.clamp(0, 3));
        },
      ),
    );
  }
}

// ==================== HOME TAB ====================

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  Stream<DocumentSnapshot<Map<String, dynamic>>> _settings$() =>
      FirebaseFirestore.instance.doc('settings/general').snapshots();

  Stream<DocumentSnapshot<Map<String, dynamic>>> _user$() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance.doc('users/$uid').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final name = FirebaseAuth.instance.currentUser?.displayName ??
        (FirebaseAuth.instance.currentUser?.email?.split('@').first ??
            'Member');

    return Stack(
      children: [
        // soft background: cream → white
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  tkoCream,
                  Colors.white,
                ],
              ),
            ),
          ),
        ),
        // soft halo accent
        Positioned(
          top: -40,
          right: -40,
          child: _softHalo(
            size: 160,
            color: tkoTeal.withOpacity(.25),
          ),
        ),

        StreamBuilder(
          stream: _settings$(),
          builder: (context, sSnap) {
            if (!sSnap.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: tkoBrown),
              );
            }
            final settings = sSnap.data!.data() ?? {};

            final tiers = (settings['tiers'] as List? ?? [])
                .map((e) => _Tier.fromMap(Map<String, dynamic>.from(e)))
                .toList()
              ..sort((a, b) => a.min.compareTo(b.min));

            final perks = (settings['perks'] as List? ?? [])
                .map((e) => _Perk.fromMap(Map<String, dynamic>.from(e)))
                .toList();

            final discountsMap =
            Map<String, dynamic>.from(settings['discounts'] ?? {});
            final earnMultipliers =
            Map<String, dynamic>.from(settings['earnMultipliers'] ?? {});

            return StreamBuilder(
              stream: _user$(),
              builder: (context, uSnap) {
                if (!uSnap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: tkoBrown),
                  );
                }
                if (!uSnap.data!.exists) {
                  FirebaseFirestore.instance
                      .doc('users/${FirebaseAuth.instance.currentUser!.uid}')
                      .set(
                    {
                      'tier': 'Featherweight',
                      'yearPoints': 0,
                      'lifetimePts': 0,
                    },
                    SetOptions(merge: true),
                  );
                  return const Center(
                    child: CircularProgressIndicator(color: tkoBrown),
                  );
                }

                final u = uSnap.data!.data()!;
                final yearPts = (u['yearPoints'] ?? 0) as int;
                final curTier = _currentTier(tiers, yearPts);
                final nextThresh = _nextThreshold(tiers, yearPts);
                final toNext = nextThresh == null ? 0 : (nextThresh - yearPts);
                final progress = nextThresh == null
                    ? 1.0
                    : (yearPts / nextThresh).clamp(0, 1).toDouble();
                final earnX =
                ((earnMultipliers[curTier.name] ?? 1.0) as num).toDouble();

                final double posterHeight =
                    (MediaQuery.of(context).size.width - 32) * 0.48;

                return CustomScrollView(
                  slivers: [
                    // greeting
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: TextStyle(
                                color: Colors.black.withOpacity(.55),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$name.',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: tkoBrown,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Tier card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _TierCard(
                          tier: curTier.name,
                          yearPoints: yearPts,
                          toNextPoints: toNext,
                          progress: progress,
                          earnX: earnX,
                          tiers: tiers,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 18)),

                    // Posters
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _PosterCarousel(height: posterHeight),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    // Actions
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _ActionGrid(
                          yearPts: yearPts,
                          tiers: tiers,
                          perks: perks,
                          discountsMap: discountsMap,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}

Widget _softHalo({required double size, required Color color}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withOpacity(.15),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(.35),
          blurRadius: size * 0.6,
          spreadRadius: size * 0.15,
        ),
      ],
    ),
  );
}

// ==================== POSTERS ====================

class _Poster {
  final String id, title, imageUrl, subtitle, ctaText, deeplink;
  final int priority;
  _Poster({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.subtitle,
    required this.ctaText,
    required this.deeplink,
    required this.priority,
  });

  factory _Poster.fromDoc(DocumentSnapshot d) {
    final m = (d.data() as Map<String, dynamic>? ?? {});
    return _Poster(
      id: d.id,
      title: (m['title'] ?? '').toString(),
      imageUrl: (m['imageUrl'] ?? '').toString(),
      subtitle: (m['subtitle'] ?? '').toString(),
      ctaText: (m['ctaText'] ?? '').toString(),
      deeplink: (m['deeplink'] ?? '').toString(),
      priority: (m['priority'] ?? 0) is num
          ? (m['priority'] as num).toInt()
          : 0,
    );
  }
}

class _PosterCarousel extends StatefulWidget {
  final double height;
  const _PosterCarousel({required this.height});

  @override
  State<_PosterCarousel> createState() => _PosterCarouselState();
}

class _PosterCarouselState extends State<_PosterCarousel> {
  final _page = PageController(viewportFraction: 1.0);

  Stream<List<_Poster>> _posters$() {
    final now = Timestamp.now();

    return FirebaseFirestore.instance
        .collection('posters')
        .orderBy('priority', descending: true)
        .snapshots()
        .map(
          (s) {
        return s.docs
            .where((d) {
          final m = (d.data() as Map<String, dynamic>? ?? {});
          final Timestamp? startsAt = m['startsAt'];
          final Timestamp? endsAt = m['endsAt'];
          final afterStart =
              (startsAt == null) || (startsAt.compareTo(now) <= 0);
          final beforeEnd =
              (endsAt == null) || (endsAt.compareTo(now) >= 0);
          return afterStart && beforeEnd;
        })
            .map(_Poster.fromDoc)
            .where((p) => p.title.isNotEmpty && p.imageUrl.isNotEmpty)
            .toList();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<_Poster>>(
      stream: _posters$(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return SizedBox(
            height: widget.height,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        final list = snap.data!;
        if (list.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: widget.height,
          width: double.infinity,
          child: PageView.builder(
            controller: _page,
            padEnds: false,
            itemCount: list.length,
            itemBuilder: (_, i) => _PosterCard(item: list[i]),
          ),
        );
      },
    );
  }
}

class _PosterCard extends StatelessWidget {
  final _Poster item;
  const _PosterCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: item.imageUrl,
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(.55),
                    Colors.black.withOpacity(.05),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 12,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (item.subtitle.isNotEmpty)
                        Text(
                          item.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(.85),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(.25),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  onPressed: () {
                    // TODO: open item.deeplink or route
                  },
                  child: Text(
                    item.ctaText.isEmpty ? 'Details' : item.ctaText,
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

// ==================== DISCOVER TAB (simple list) ====================

class _DiscoverTab extends StatelessWidget {
  const _DiscoverTab();

  @override
  Widget build(BuildContext context) {
    final items = List.generate(
      8,
          (i) => ('Bonus ${100 + i * 25} pts', 'On selected items this week'),
    );
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return ListTile(
          leading: const Icon(Icons.local_offer_outlined),
          title: Text(
            item.$1,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(item.$2),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 1),
    );
  }
}

// ==================== TIER / PERKS MODEL ====================

class _Tier {
  final String name;
  final int min;
  const _Tier({required this.name, required this.min});
  factory _Tier.fromMap(Map<String, dynamic> m) =>
      _Tier(name: m['name'] as String, min: (m['min'] as num).toInt());
}

class _Perk {
  final String title;
  final String description;
  final String minTierName;
  const _Perk({
    required this.title,
    required this.description,
    required this.minTierName,
  });
  factory _Perk.fromMap(Map<String, dynamic> m) => _Perk(
    title: m['title'] ?? m['name'] ?? '',
    description: m['description'] ?? '',
    minTierName: m['minTier'] ?? m['minTierName'] ?? 'Featherweight',
  );
}

_Tier _currentTier(List<_Tier> tiers, int pts) {
  _Tier cur = tiers.first;
  for (final t in tiers) {
    if (pts >= t.min) cur = t;
  }
  return cur;
}

int? _nextThreshold(List<_Tier> tiers, int pts) {
  for (final t in tiers) {
    if (pts < t.min) return t.min;
  }
  return null;
}

int _tierIndexByName(List<_Tier> tiers, String name) =>
    tiers.indexWhere((t) => t.name.toLowerCase() == name.toLowerCase());

// ==================== TIER CARD (lux solid style) ====================

class _TierCard extends StatelessWidget {
  final String tier;
  final int yearPoints;
  final int toNextPoints;
  final double progress;
  final double earnX;
  final List<_Tier> tiers;

  const _TierCard({
    required this.tier,
    required this.yearPoints,
    required this.toNextPoints,
    required this.progress,
    required this.earnX,
    required this.tiers,
  });

  Color get _tierColor {
    switch (tier.toLowerCase()) {
      case 'lightweight':
        return tkoGold;
      case 'welterweight':
        return tkoOrange;
      case 'heavyweight':
        return tkoBrown;
      case 'reigning champion':
        return tkoTeal;
      default:
        return tkoTeal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final curIdx = _tierIndexByName(tiers, tier);
    final nextIdx =
    (curIdx != -1 && curIdx + 1 < tiers.length) ? curIdx + 1 : curIdx;
    final nextName =
    (nextIdx > curIdx) ? tiers[nextIdx].name : 'Top tier';
    final pct = (progress.clamp(0, 1) * 100).round();

    return LayoutBuilder(
      builder: (_, constraints) {
        final compact = constraints.maxWidth < 360;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.black.withOpacity(.04),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x16000000),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              // LEFT: text + progress
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // small pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _tierColor.withOpacity(.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.workspace_premium_outlined,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tier,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$yearPoints pts',
                      style: TextStyle(
                        fontSize: compact ? 18 : 20,
                        fontWeight: FontWeight.w900,
                        color: tkoBrown,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      toNextPoints <= 0
                          ? 'You’re at the highest tier for this year.'
                          : 'Get $toNextPoints more points to reach $nextName.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withOpacity(.72),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // progress bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(.04),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: progress.clamp(0, 1),
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _tierColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$pct% to next',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _tierColor,
                              ),
                            ),
                            Text(
                              '${earnX.toStringAsFixed(2)}x pts / \$1',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.black.withOpacity(.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // RIGHT: emblem only (🔻 Upgrade button removed)
              _TierEmblem(
                accent: _tierColor,
                compact: compact,
              ),
            ],
          ),
        );
      },
    );
  }
}


class _TierEmblem extends StatelessWidget {
  final Color accent;
  final bool compact;

  const _TierEmblem({required this.accent, required this.compact});

  @override
  Widget build(BuildContext context) {
    final double outer = compact ? 64 : 72;
    final double inner = compact ? 46 : 52;

    return SizedBox(
      width: outer,
      height: outer,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: outer,
            height: outer,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(.10),
            ),
          ),
          Container(
            width: inner,
            height: inner,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  accent.withOpacity(.9),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(.55),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== ACTION GRID ====================

class _ActionGrid extends StatelessWidget {
  final int yearPts;
  final List<_Tier> tiers;
  final List<_Perk> perks;
  final Map<String, dynamic> discountsMap;

  const _ActionGrid({
    required this.yearPts,
    required this.tiers,
    required this.perks,
    required this.discountsMap,
  });

  void _openBenefits(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BenefitsSheet(
        currentPoints: yearPts,
        tiers: tiers,
        perks: perks,
        discountsMap: discountsMap,
      ),
    );
  }

  void _openQuickScan(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final code = 'TKO:$uid';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Quick Scan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            QrImageView(data: code, size: 200),
            const SizedBox(height: 8),
            const Text(
              'Show this at checkout to earn or redeem points.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _PrimaryActionCard(
              icon: Icons.workspace_premium_rounded,
              label: 'Benefits',
              subtitle: 'See what you’ve unlocked',
              accent: tkoOrange,
              onTap: () => _openBenefits(context),
            ),
            _PrimaryActionCard(
              icon: Icons.shopping_bag_outlined,
              label: 'Order',
              subtitle: 'Place or view orders',
              accent: tkoTeal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProductsPage()),
                );
              },
            ),
            _PrimaryActionCard(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Scan',
              subtitle: 'Earn & redeem fast',
              accent: tkoBrown,
              onTap: () => _openQuickScan(context),
            ),
            _PrimaryActionCard(
              icon: SimpleIcons.discord,
              label: 'Discord',
              subtitle: 'Connect with the community',
              accent: tkoTeal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DiscordScreen()),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PillAction(
              icon: Icons.history,
              label: 'Activity',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyOrdersPage(),
                  ),
                );
              },
            ),
            const SizedBox(width: 10),
            _PillAction(
              icon: Icons.support_agent,
              label: 'Support',
              onTap: () {
                // TODO: later add support page / email
              },
            ),
          ],
        ),

      ],
    );
  }
}

class _PrimaryActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color accent;
  final VoidCallback? onTap;

  const _PrimaryActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(.04)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(.10),
              ),
              child: Icon(icon, size: 18, color: accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: tkoBrown,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black.withOpacity(.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _PillAction({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: tkoBrown),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: tkoBrown,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ==================== BENEFITS SHEET ====================

class _BenefitsSheet extends StatefulWidget {
  final int currentPoints;
  final List<_Tier> tiers;
  final List<_Perk> perks;
  final Map<String, dynamic> discountsMap;
  const _BenefitsSheet({
    required this.currentPoints,
    required this.tiers,
    required this.perks,
    required this.discountsMap,
  });

  @override
  State<_BenefitsSheet> createState() => _BenefitsSheetState();
}

class _BenefitsSheetState extends State<_BenefitsSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  Widget build(BuildContext context) {
    final curTier = _currentTier(widget.tiers, widget.currentPoints);
    final curIdx = widget.tiers.indexOf(curTier);

    final perkItems = widget.perks.map((p) {
      final needIdx = _tierIndexByName(widget.tiers, p.minTierName);
      final unlocked = (needIdx != -1 && needIdx <= curIdx);

      int? pointsLeft;
      if (!unlocked && needIdx != -1) {
        pointsLeft = (widget.tiers[needIdx].min - widget.currentPoints)
            .clamp(0, 1 << 31);
      }

      return {
        'perk': p,
        'unlocked': unlocked,
        'pointsLeft': pointsLeft,
      };
    }).toList();

    perkItems.sort((a, b) {
      final ua = a['unlocked'] as bool;
      final ub = b['unlocked'] as bool;
      if (ua != ub) return ua ? -1 : 1;
      final pa = (a['pointsLeft'] as int?) ?? 0;
      final pb = (b['pointsLeft'] as int?) ?? 0;
      return pa.compareTo(pb);
    });

    return DraggableScrollableSheet(
      initialChildSize: 0.90,
      minChildSize: 0.50,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your Benefits',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          TabBar(
            controller: _tab,
            indicatorColor: tkoOrange,
            labelColor: Colors.black,
            tabs: const [Tab(text: 'Perks'), Tab(text: 'Discounts')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  itemCount: perkItems.length,
                  itemBuilder: (_, i) {
                    final item = perkItems[i];
                    final _Perk perk = item['perk'] as _Perk;
                    final bool unlocked = item['unlocked'] as bool;
                    final int? pointsLeft = item['pointsLeft'] as int?;
                    return _PerkTile(
                      perk: perk,
                      unlocked: unlocked,
                      pointsLeft: pointsLeft,
                    );
                  },
                ),

                // Discounts
                ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _DiscountsPanel(
                      tierName: curTier.name,
                      discountsMap: widget.discountsMap,
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

class _PerkTile extends StatelessWidget {
  final _Perk perk;
  final bool unlocked;
  final int? pointsLeft;
  const _PerkTile({
    required this.perk,
    required this.unlocked,
    this.pointsLeft,
  });

  @override
  Widget build(BuildContext context) {
    final c = unlocked ? Colors.green : Colors.orange;
    final status = unlocked
        ? 'Unlocked'
        : (pointsLeft != null ? '$pointsLeft pts to unlock' : 'Locked');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.withOpacity(.12),
            ),
            child: Icon(
              unlocked ? Icons.verified_rounded : Icons.lock_clock_rounded,
              color: c,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  perk.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (perk.description.isNotEmpty)
                  Text(
                    perk.description,
                    style: TextStyle(
                      color: Colors.black.withOpacity(.7),
                    ),
                  ),
                Text(
                  status,
                  style: TextStyle(
                    color: c,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _DiscountsPanel extends StatelessWidget {
  final String tierName;
  final Map<String, dynamic> discountsMap;
  const _DiscountsPanel({
    required this.tierName,
    required this.discountsMap,
  });

  @override
  Widget build(BuildContext context) {
    final tierDisc = Map<String, dynamic>.from(discountsMap[tierName] ?? {});
    final rows = <Widget>[];

    final entries = tierDisc.entries.toList()
      ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));

    for (final e in entries) {
      final key = e.key.toString();
      final v = e.value;
      final valueText = v is num ? v.toStringAsFixed(0) : v.toString();

      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 18,
                color: tkoBrown,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(key)),
              Text(
                '$valueText%',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      );
      rows.add(const Divider(height: 1));
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$tierName Discounts',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          ...rows,
        ],
      ),
    );
  }
}

// ==================== BRAND BOTTOM NAV ====================

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
              isActive: index == 2,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OffersListScreen(),
                  ),
                );
              },
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
