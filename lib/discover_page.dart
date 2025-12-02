import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';   // 👈 add to pubspec.yaml

import 'home_page.dart'; // for TkoBottomNav + colors

class OffersListScreen extends StatelessWidget {
  const OffersListScreen({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _offersStream() {
    return FirebaseFirestore.instance
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  IconData _iconFromName(String? name) {
    switch ((name ?? '').toLowerCase()) {
      case 'gift':
        return Icons.card_giftcard;
      case 'fire':
        return Icons.local_fire_department_rounded;
      case 'discount':
        return Icons.discount_outlined;
      case 'celebration':
        return Icons.celebration;
      case 'news':
        return Icons.campaign_outlined;
      case 'product':
        return Icons.toys_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  Color _colorFromHex(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.blueAccent;
    var value = hex.replaceAll('#', '');
    if (value.length == 6) value = 'FF$value';
    final intColor = int.tryParse(value, radix: 16) ?? 0xFF2196F3;
    return Color(intColor);
  }

  Future<void> _openDeeplink(String? deeplink) async {
    if (deeplink == null || deeplink.isEmpty) return;

    // simplest: treat as web URL for now
    final uri = Uri.tryParse(deeplink);
    if (uri == null) return;

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      bottomNavigationBar: TkoBottomNav(
        index: 2,
        onChanged: (newIndex) {
          switch (newIndex) {
            case 0:
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
                    (route) => false,
              );
              break;
            case 1:
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const HomePage(initialTab: 1)),
                    (route) => false,
              );
              break;
            case 3:
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const HomePage(initialTab: 3)),
                    (route) => false,
              );
              break;
          }
        },
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: false,
        title: Text(
          "Discover",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _offersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Failed to load announcements"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.campaign_outlined,
                        size: 50, color: Colors.grey),
                    const SizedBox(height: 10),
                    Text(
                      "No announcements yet",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "New events, product drops and offers\nwill show up here.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (_, i) {
              final data = docs[i].data();

              final title       = (data['title'] ?? '') as String;
              final subtitle    = (data['subtitle'] ?? '') as String;
              final type        = (data['type'] ?? '') as String;
              final iconName    = data['icon'] as String?;
              final colorHex    = data['color'] as String?;
              final imageUrl    = data['imageUrl'] as String?;   // 👈 NEW
              final deeplink    = data['deeplink'] as String?;   // 👈 NEW
              final buttonLabel = data['buttonLabel'] as String?; // 👈 NEW

              final icon  = _iconFromName(iconName);
              final color = _colorFromHex(colorHex);

              final chip = type.isEmpty
                  ? null
                  : Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  type.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              );

              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _openDeeplink(deeplink),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // top row
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundColor: color.withOpacity(0.15),
                          child: Icon(icon, color: color, size: 26),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            if (chip != null) chip,
                          ],
                        ),
                        subtitle: Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ),

                      // optional image banner
                      if (imageUrl != null && imageUrl.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(14),
                            bottomRight: Radius.circular(14),
                          ),
                          child: Image.network(
                            imageUrl,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 160,
                              color: Colors.grey[200],
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                      ],

                      // optional CTA button
                      if (deeplink != null && deeplink.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: OutlinedButton(
                            onPressed: () => _openDeeplink(deeplink),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: color),
                              foregroundColor: color,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 8,
                              ),
                            ),
                            child: Text(
                              buttonLabel ?? 'View details',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
