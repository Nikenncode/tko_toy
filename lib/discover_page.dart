import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OffersListScreen extends StatelessWidget {
  const OffersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final offers = [
      {
        "title": "Bonus 150 Points",
        "subtitle": "On all Beyblade X starter packs",
        "icon": Icons.card_giftcard,
        "color": Colors.orange,
      },
      {
        "title": "Double Points Day!",
        "subtitle": "Earn 2x rewards on all purchases this Wednesday",
        "icon": Icons.local_fire_department_rounded,
        "color": Colors.redAccent,
      },
      {
        "title": "5% Off Supplies",
        "subtitle": "Exclusive discount for Loyalty Members",
        "icon": Icons.discount_outlined,
        "color": Colors.green,
      },
      {
        "title": "Free Poster",
        "subtitle": "Get a free Beyblade poster with every purchase over \$50",
        "icon": Icons.celebration,
        "color": Colors.blueAccent,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Current Offers",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: offers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final offer = offers[i];
          return ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: (offer["color"] as Color).withOpacity(0.15),
              child: Icon(
                offer["icon"] as IconData,
                color: offer["color"] as Color,
                size: 26,
              ),
            ),
            title: Text(
              offer["title"] as String,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            subtitle: Text(
              offer["subtitle"] as String,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.black45),
            onTap: () {
              // TODO: Navigate to offer details or redemption page
            },
          );
        },
      ),
    );
  }
}
