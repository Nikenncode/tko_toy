 import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'trading_card_grids_page.dart';
import 'home_page.dart';

class CategoryItem {
  final String title;
  final String firebaseId;
  final List<String> subItems;
  bool isExpanded;

  CategoryItem({
    required this.title,
    required this.firebaseId,
    required this.subItems,
    this.isExpanded = false,
  });
}

class TradingCardsPage extends StatefulWidget {
  const TradingCardsPage({super.key});

  @override
  State<TradingCardsPage> createState() => _TradingCardsPageState();
}

class _TradingCardsPageState extends State<TradingCardsPage> {
  List<String> getAllTabs() {
    List<String> tabs = [];

    for (var cat in categories) {
      for (var sub in cat.subItems) {
        tabs.add("${cat.title} – $sub");
      }
    }

    return tabs;
  }

  Future<String?> loadFirebaseImage(String docId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection("logo")
          .doc(docId)
          .get();

      if (snap.exists && snap.data()!["image"] != null) {
        return snap.data()!["image"];
      }
    } catch (e) {
      print("Error loading image: $e");
    }
    return null;
  }

  List<CategoryItem> categories = [
    CategoryItem(
      title: "One Piece",
      firebaseId: "gGX5LvATntSEeiyXmOid",
      subItems: ["Singles", "Sealed"],
    ),
    CategoryItem(
      title: "Pokemon",
      firebaseId: "o6rb0ZWpvz8PyY53rCTz",
      subItems: ["Singles", "Sealed", "Japanese Sealed"],
    ),
    CategoryItem(
      title: "Magic The Gathering",
      firebaseId: "2VYJVgZ8XSraRLpqbpGf",
      subItems: ["Singles", "Sealed"],
    ),
    CategoryItem(
      title: "Yu-Gi-Oh!",
      firebaseId: "9j8z32HCrTkG4ukho3zX",
      subItems: ["Singles", "Sealed"],
    ),
    CategoryItem(
      title: "Riftbound",
      firebaseId: "fU8kjadlmDsjqPaoZa6K",
      subItems: ["Singles", "Sealed"],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tkoCream,

      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: tkoBrown),
        title: Text(
          'Trading Cards',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: tkoBrown,
          ),
        ),
      ),

      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];

          return Column(
            children: [
              ListTile(
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

                leading: FutureBuilder<String?>(
                  future: loadFirebaseImage(cat.firebaseId),
                  builder: (context, snap) {
                    final img = snap.data;

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        img != null && img.isNotEmpty
                            ? img
                            : "https://via.placeholder.com/60",
                        width: 55,
                        height: 55,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),


                title: Text(
                  cat.title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                trailing: Icon(
                  cat.isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.chevron_right,
                  size: 26,
                ),

                onTap: () {
                  setState(() => cat.isExpanded = !cat.isExpanded);
                },
              ),

              if (cat.isExpanded)
                Container(
                  color: Colors.grey.shade100,
                  child: Column(
                    children: cat.subItems.map((sub) {
                      return Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.only(
                                left: 32, right: 16, top: 4, bottom: 4),
                            title: Text(
                              sub,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: tkoBrown,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              size: 22,
                              color: tkoBrown,
                            ),
                            onTap: () {
                              final allTabs = getAllTabs();
                              final selectedTab = "${cat.title} – $sub";

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CardsGridPage(
                                    selectedTab: selectedTab,
                                    allTabs: allTabs,
                                  ),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                        ],
                      );
                    }).toList(),
                  ),
                ),

              const Divider(height: 1),
            ],
          );
        },
      ),
      bottomNavigationBar: TkoBottomNav(
        index: -1,
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
                MaterialPageRoute(builder: (_) => const HomePage(initialTab: 1)),
                    (route) => false,
              );
              break;

            case 3:
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomePage(initialTab: 3)),
                    (route) => false,
              );
              break;
          }
        },
      ),
    );
  }
}
