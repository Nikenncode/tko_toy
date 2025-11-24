import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'trading_card_page.dart';
import 'toys_page.dart';
import 'supplies_page.dart';

class Poster {
  final String id;
  final String imageUrl;

  Poster({
    required this.id,
    required this.imageUrl,
  });

  factory Poster.fromDoc(DocumentSnapshot d) {
    final m = (d.data() as Map<String, dynamic>? ?? {});
    return Poster(
      id: d.id,
      imageUrl: (m['image'] ?? '').toString(),
    );
  }
}

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_SimpleCategory> categories = [
      _SimpleCategory(
        icon: Icons.style,
        title: "Trading Cards",
        page: const TradingCardsPage(),
      ),
      _SimpleCategory(
        icon: Icons.sports_esports,
        title: "Toys & Beyblades",
        page: const ToysPage(),
      ),
      _SimpleCategory(
        icon: Icons.inventory_2_outlined,
        title: "Supplies & Accessories",
        page: const SuppliesPage(),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.4,
        title: Text(
          "Products",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
      ),

      bottomNavigationBar: TkoBottomNav(
        index: -1,
        onChanged: (newIndex) {
          if (newIndex == 0) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HomePage()));
          }
        },
      ),

      body: ListView(
        children: [
          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('posters').limit(1).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SizedBox(
                  height: 120,
                  child: Center(child: Text("No banner found")),
                );
              }

              final doc = snapshot.data!.docs.first;
              final imageUrl = (doc.data() as Map<String, dynamic>)['image'];

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Image.network(
                  imageUrl,
                  height: 130,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.center,
                ),
              );
            },
          ),

          const SizedBox(height: 0),

          ...categories.map(
                (cat) => Column(
              children: [
                _CategoryRow(category: cat),
                const Divider(height: 1, thickness: 0.8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleCategory {
  final IconData icon;
  final String title;
  final Widget page;

  _SimpleCategory({
    required this.icon,
    required this.title,
    required this.page,
  });
}

class _CategoryRow extends StatelessWidget {
  final _SimpleCategory category;

  const _CategoryRow({required this.category});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      leading: Icon(category.icon, size: 32, color: Colors.black54),
      title: Text(
        category.title,
        style: GoogleFonts.poppins(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.black54, size: 24),

      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => category.page),
        );
      },
    );
  }
}
