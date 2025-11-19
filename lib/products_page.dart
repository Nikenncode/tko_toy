import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_page.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_ProductCategory> categories = [
      _ProductCategory(
        title: "Trading Cards",
        subtitle: "TCG Singles • Sealed • Decks",
        gradientStart: const Color(0xFFFFDCA8),
        gradientEnd: const Color(0xFFFFB973),
        icon: Icons.style,
      ),
      _ProductCategory(
        title: "Toys & Beyblades",
        subtitle: "Beyblade X • Sets",
        gradientStart: const Color(0xFFFFE6C8),
        gradientEnd: const Color(0xFFF4C38F),
        icon: Icons.shield_sharp,
      ),
      _ProductCategory(
        title: "Supplies & Accessories",
        subtitle: "Sleeves • Playmats • Storage",
        gradientStart: const Color(0xFFFFE6C8),
        gradientEnd: const Color(0xFFF4C38F),
        icon: Icons.inventory_2_outlined,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: true,
        centerTitle: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 1),
          child: Text(
            "Products",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
        ),
      ),
      bottomNavigationBar: TkoBottomNav(
        index: -1,
        onChanged: (newIndex) {
          if (newIndex == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          }
        },
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.separated(
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (_, i) {
            final cat = categories[i];
            return _CategoryCard(category: cat);
          },
        ),
      ),
    );
  }
}

class _ProductCategory {
  final String title;
  final String subtitle;
  final Color gradientStart;
  final Color gradientEnd;
  final IconData icon;

  _ProductCategory({
    required this.title,
    required this.subtitle,
    required this.gradientStart,
    required this.gradientEnd,
    required this.icon,
  });
}

class _CategoryCard extends StatelessWidget {
  final _ProductCategory category;
  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        // TODO: Navigate to that category list
      },
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              category.gradientStart,
              category.gradientEnd,
              Colors.white
            ],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(.90),
              ),
              child: Icon(
                category.icon,
                color: Colors.black87,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    category.title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category.subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 22,
              color: Colors.black45,
            ),
          ],
        ),
      ),
    );
  }
}
