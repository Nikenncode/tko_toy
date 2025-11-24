import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Product_description.dart';

class SuppliesGridPage extends StatefulWidget {
  final String selectedTab;
  final List<String> allTabs;

  const SuppliesGridPage({
    super.key,
    required this.selectedTab,
    required this.allTabs,
  });

  @override
  State<SuppliesGridPage> createState() => _SuppliesGridPageState();
}

class _SuppliesGridPageState extends State<SuppliesGridPage>
    with SingleTickerProviderStateMixin {

  late TabController tabController;
  late String activeTab;

  @override
  void initState() {
    super.initState();

    activeTab = widget.selectedTab;

    tabController = TabController(
      length: widget.allTabs.length,
      vsync: this,
      initialIndex: widget.allTabs.indexOf(widget.selectedTab),
    );

    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        setState(() {
          activeTab = widget.allTabs[tabController.index];
        });
      }
    });
  }

  String _getFirebaseCollection() {
    final t = activeTab.toLowerCase();

    if (t.contains("binder")) return "binders";
    if (t.contains("deck boxes")) return "deck_boxes";
    if (t.contains("playmats")) return "playmats";
    if (t.contains("boxes")) return "boxes_and_supplies";
    if (t.contains("card")) return "Card_sleeves";

    return "Card_sleeves";
  }

  String _getImage(Map<String, dynamic> data) {
    final list = (data['images'] as List?)?.whereType<String>().toList() ?? [];
    if (list.isNotEmpty) return list.first;
    return "https://via.placeholder.com/300x300?text=No+Image";
  }

  num? _getPrice(List? variants) {
    if (variants == null) return null;
    for (final v in variants) {
      if (v is Map && v['price'] != null) {
        final p = v['price'];
        if (p is num) return p;
        if (p is String) return num.tryParse(p);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final firebaseCollection = _getFirebaseCollection();

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.4,
        title: Text(
          "Accessories",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),

      body: Column(
        children: [
          Container(
            height: 50,
            child: TabBar(
              controller: tabController,
              isScrollable: true,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.black,
              tabs: widget.allTabs.map((t) => Tab(text: t)).toList(),
            ),
          ),

          Expanded(
            child: _buildFirebaseGrid(firebaseCollection),
          ),
        ],
      ),
    );
  }

  Widget _buildFirebaseGrid(String collection) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No products found"));
        }

        final docs = snapshot.data!.docs;

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 18,
            crossAxisSpacing: 14,
            childAspectRatio: 0.67,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;

            final title = data['title'] ?? "";
            final variants = (data['variants'] as List?) ?? [];
            final price = _getPrice(variants);

            final images = (data['images'] as List?)?.whereType<String>().toList() ?? [];
            final imageUrl = images.isNotEmpty && images.first.startsWith("http")
                ? images.first
                : null;

            bool isLiked = false;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailsPage(
                      product: {
                        ...data,
                        "parentTab": activeTab,
                      },
                    ),
                  ),
                );
              },

              child: StatefulBuilder(
                builder: (context, setState) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      color: Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                              child: Container(
                                height: 150,
                                width: double.infinity,
                                color: Colors.white,
                                child: imageUrl == null
                                    ? Center(
                                  child: Column(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_not_supported,
                                          size: 40,
                                          color: Colors.grey.shade400),
                                      const SizedBox(height: 4),
                                      Text(
                                        "No image",
                                        style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                )
                                    : Image.network(
                                  imageUrl,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),

                            Positioned(
                              top: 10,
                              right: 10,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    isLiked = !isLiked;
                                  });
                                },
                                child: Container(
                                  height: 34,
                                  width: 34,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 20,
                                    color: isLiked ? Colors.red : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        Container(
                          height: 1,
                          width: double.infinity,
                          color: Colors.grey.shade300,
                        ),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                          child: Text(
                            price != null ? "\$${price.toStringAsFixed(2)}" : "",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
