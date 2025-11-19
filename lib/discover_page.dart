import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_page.dart';

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
      bottomNavigationBar: TkoBottomNav(
        index: -1,
        onChanged: (newIndex) {
          if (newIndex == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          }
        },
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: true,
        centerTitle: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 0),
          child: Text(
            "Current Offers",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
        ),
      ),

      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
        itemCount: offers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, i) {
          final offer = offers[i];

          return Container(
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
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              leading: CircleAvatar(
                radius: 26,
                backgroundColor: (offer["color"] as Color).withOpacity(0.15),
                child: Icon(
                  offer["icon"] as IconData,
                  color: offer["color"] as Color,
                  size: 26,
                ),
              ),
              title: Text(
                offer["title"] as String,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                offer["subtitle"] as String,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.black45),
              onTap: () {
                // TODO: navigate to detailed offer page
              },
            ),
          );
        },
      ),
    );
  }
}
