import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_page.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        "title": "Trading Cards",
        "subtitle": "TCG Singles • Sealed • Decks",
        "icon": Icons.style_rounded,
        "color": Colors.orange,
      },
      {
        "title": "Toys & Beyblades",
        "subtitle": "Beyblade X • Sets",
        "icon": Icons.shield_rounded,
        "color": Colors.green,
      },
      {
        "title": "Supplies & Accessories",
        "subtitle": "Sleeves • Playmats • Storage",
        "icon": Icons.inventory_2_rounded,
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
        centerTitle: false,
        automaticallyImplyLeading: true,
        title: Text(
          "Products",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Colors.black87,
          ),
        ),
      ),

      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, i) {
          final item = items[i];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: (item["color"] as Color).withOpacity(0.18),
                  child: Icon(
                    item["icon"] as IconData,
                    color: item["color"] as Color,
                    size: 30,
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item["title"] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item["subtitle"] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(Icons.chevron_right_rounded,
                    size: 22, color: Colors.black45),
              ],
            ),
          );
        },
      ),
    );
  }
}
