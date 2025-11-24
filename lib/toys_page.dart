import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'toys_grid_page.dart';

class _Item {
  final String name;
  final String image;
  final String? firebaseId;

  _Item({
    required this.name,
    required this.image,
    this.firebaseId,
  });
}

class ToysPage extends StatelessWidget {
  const ToysPage({super.key});

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
      print("Error loading image for $docId → $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final List<_Item> items = [
      _Item(name: "BeybladeX",
        image: "",
        firebaseId: "beyblade_logo",
      ),
      _Item(name: "Funko Figures",
        image: "",
        firebaseId: "funko_logo_logo",
      ),
      _Item(name: "Backpacks",
        image: "",
        firebaseId: "backpack_logo",
      ),
    ];

    final List<String> allTabs = items.map((e) => e.name).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.4,
        title: Text(
          "Toys and Action Figures",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),

      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),

        itemBuilder: (context, i) {
          final item = items[i];

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ToysGridPage(
                    selectedTab: item.name,
                    allTabs: allTabs,
                  ),
                ),
              );
            },

            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  if (item.firebaseId != null)
                    FutureBuilder<String?>(
                      future: loadFirebaseImage(item.firebaseId!),
                      builder: (context, snap) {
                        final img = snap.data ?? item.image;

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            img.isNotEmpty ? img : "https://via.placeholder.com/70",
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    )
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        item.image,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Text(
                      item.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  const Icon(Icons.chevron_right, color: Colors.black54),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


