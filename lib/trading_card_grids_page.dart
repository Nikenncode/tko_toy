import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Product_description.dart';
import 'home_page.dart';
import 'like_service.dart';

class CardsGridPage extends StatefulWidget {
  final String selectedTab;
  final List<String> allTabs;

  const CardsGridPage({
    super.key,
    required this.selectedTab,
    required this.allTabs,
  });

  @override
  State<CardsGridPage> createState() => _CardsGridPageState();
}

class CardSearchDelegate extends SearchDelegate {
  final String collection;

  CardSearchDelegate(this.collection);

  List<Map<String, dynamic>> allProducts = [];
  bool isLoaded = false;

  Future<void> _loadProducts() async {
    final snap = await FirebaseFirestore.instance.collection(collection).get();
    allProducts = snap.docs.map((d) => d.data()).toList();
    isLoaded = true;
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder(
      future: isLoaded ? Future.value() : _loadProducts(),
      builder: (_, __) {
        if (!isLoaded) return const Center(child: CircularProgressIndicator());

        final lowerQuery = query.toLowerCase();

        final results = allProducts.where((p) {
          final title = (p["title"] ?? "").toString().toLowerCase();
          return title.contains(lowerQuery);
        }).toList();

        if (results.isEmpty) {
          return const Center(child: Text("No results"));
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (_, i) {
            final item = results[i];
            return ListTile(
              title: Text(item["title"] ?? ""),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailsPage(product: item),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = "",
      )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }
}

class _CardsGridPageState extends State<CardsGridPage>
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

  List<QueryDocumentSnapshot> _applySortAndFilters(List<QueryDocumentSnapshot> docs) {
    List<QueryDocumentSnapshot> sorted = List.from(docs);

    if (selectedSort == "Price: Low–High") {
      sorted.sort((a, b) {
        final pa = _getPrice(a["variants"]) ?? 0;
        final pb = _getPrice(b["variants"]) ?? 0;
        return pa.compareTo(pb);
      });
    }
    else if (selectedSort == "Price: High–Low") {
      sorted.sort((a, b) {
        final pa = _getPrice(a["variants"]) ?? 0;
        final pb = _getPrice(b["variants"]) ?? 0;
        return pb.compareTo(pa);
      });
    }
    else if (selectedSort == "Newest") {
      sorted = List.from(docs.reversed);
    }

    bool priceFilterActive = priceFilters.containsValue(true);

    if (priceFilterActive) {
      sorted = sorted.where((doc) {
        final p = _getPrice(doc["variants"]) ?? 0;

        if (priceFilters["\$1 - \$10"] == true && p >= 1 && p <= 10) return true;
        if (priceFilters["\$10 - \$50"] == true && p >= 10 && p <= 50) return true;
        if (priceFilters["\$50 - \$100"] == true && p >= 50 && p <= 100) return true;
        if (priceFilters["\$100+"] == true && p >= 100) return true;

        return false;
      }).toList();
    }

    return sorted;
  }

  String? _getFirebaseCollection() {
    final t = activeTab.toLowerCase().trim();

    if (t.contains("one piece") && t.contains("singles")) return "one_piece_singles";
    if (t.contains("one piece") && t.contains("sealed")) return "one_piece_sealed";

    if (t.contains("pokemon") && t.contains("singles")) return "pokemon_singles";
    if (t.contains("pokemon") && t.contains("japanese")) return "pokemon_japanese_sealed";
    if (t.contains("pokemon") && t.contains("sealed")) return "pokemon_sealed";

    if (t.contains("magic") && t.contains("singles")) return "mtg_singles";
    if (t.contains("magic") && t.contains("sealed")) return "mtg_sealed";

    if (t.contains("yu-gi-oh") && t.contains("singles")) return "yu_gi_oh_singles";
    if (t.contains("yu-gi-oh") && t.contains("sealed")) return "yu_gi_oh_sealed";

    if (t.contains("riftbound") && t.contains("singles")) return "riftbound_singles";
    if (t.contains("riftbound") && t.contains("sealed")) return "riftbound_sealed";

    return null;
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

  int _getTotalInventory(List? variants) {
    int total = 0;
    if (variants == null) return 0;

    for (final v in variants) {
      if (v is Map<String, dynamic>) {
        final inv = v['inventory'];
        if (inv is num) total += inv.toInt();
        if (inv is String) {
          final parsed = int.tryParse(inv);
          if (parsed != null) total += parsed;
        }
      }
    }
    return total;
  }

  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    if (!url.startsWith("http")) return false;
    return true;
  }

  String? selectedSort = "Featured";

  Map<String, bool> priceFilters = {
    "\$1 - \$10": false,
    "\$10 - \$50": false,
    "\$50 - \$100": false,
    "\$100+": false,
  };

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            Widget buildRadioOption(String label) {
              return Row(
                children: [
                  Radio<String>(
                    value: label,
                    groupValue: selectedSort,
                    onChanged: (value) {
                      modalSetState(() {
                        selectedSort = value;
                      });
                    },
                  ),
                  Text(label, style: GoogleFonts.poppins(fontSize: 15)),
                ],
              );
            }

            Widget buildCheckbox(String label) {
              return Row(
                children: [
                  Checkbox(
                    value: priceFilters[label],
                    onChanged: (value) {
                      modalSetState(() {
                        priceFilters[label] = value ?? false;
                      });
                    },
                  ),
                  Text(label, style: GoogleFonts.poppins(fontSize: 15)),
                ],
              );
            }

            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.85,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Filter",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Sort By",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  buildRadioOption("Featured"),
                  buildRadioOption("Newest"),
                  buildRadioOption("Price: Low–High"),
                  buildRadioOption("Price: High–Low"),

                  const Divider(height: 30),

                  Text(
                    "Price Range",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  buildCheckbox("\$1 - \$10"),
                  buildCheckbox("\$10 - \$50"),
                  buildCheckbox("\$50 - \$100"),
                  buildCheckbox("\$100+"),

                  const Spacer(),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              selectedSort = "Featured";
                              priceFilters.updateAll((key, value) => false);
                            });
                            Navigator.pop(context);
                          },

                          style: OutlinedButton.styleFrom(
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            "Reset",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {});
                          },

                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            "Apply",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _noImageBox() {
    return Container(
      height: 150,
      width: double.infinity,
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported,
                size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 4),
            Text(
              "No image",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firebaseCollection = _getFirebaseCollection();

    return Scaffold(
      backgroundColor: tkoCream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.4,
        automaticallyImplyLeading: true,
        title: Text(
          "Trading Cards",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded,
                size: 24, color: Colors.black),
            onPressed: () => _openFilterSheet(context),
          ),
          IconButton(
              icon: const Icon(Icons.search,
                  size: 24, color: Colors.black),
              onPressed: () {
                final col = _getFirebaseCollection();
                if (col != null) {
                  showSearch(
                    context: context,
                    delegate: CardSearchDelegate(col),
                  );
                }
              }

          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
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
            child: firebaseCollection == null
                ? const Center(child: Text("No category found"))
                : _buildFirebaseGrid(firebaseCollection),
          ),
        ],
      ),
      bottomNavigationBar: StreamBuilder<QuerySnapshot>(
        stream: LikeService.likedItemsStream(),
        builder: (context, snap) {
          final wishlistCount = snap.data?.docs.length ?? 0;

          return TkoBottomNav(
            index: -1,
            wishlistCount: wishlistCount,
            onChanged: (newIndex) {
              if (newIndex == 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePage()),
                );
              }
              if (newIndex == 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const HomePage(initialTab: 1)),
                );
              }
              if (newIndex == 3) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const HomePage(initialTab: 3)),
                );
              }
            },
          );
        },
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

        var docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final variants = data['variants'] as List?;
          final totalInv = _getTotalInventory(variants);
          return totalInv > 0;
        }).toList();

        docs = _applySortAndFilters(docs);

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 18,
            crossAxisSpacing: 14,
            childAspectRatio: 0.67,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data =
            docs[index].data() as Map<String, dynamic>;

            final title = data['title'] ?? "";
            final price = _getPrice(data['variants']);
            final images = (data['images'] as List?)
                ?.whereType<String>()
                .toList() ??
                [];
            final imageUrl =
            images.isNotEmpty ? images.first : null;

            bool isLiked = false;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailsPage(
                      product: {...data, "parentTab": activeTab},
                    ),
                  ),
                );
              },
              child: StatefulBuilder(
                builder: (context, setStateTile) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.grey.shade300, width: 1),
                      color: Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius:
                              const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                              child: Container(
                                height: 150,
                                width: double.infinity,
                                color: Colors.white,
                                child: _isValidUrl(imageUrl)
                                    ? Image.network(
                                  imageUrl!,
                                  fit: BoxFit.contain,
                                  errorBuilder:
                                      (_, __, ___) =>
                                      _noImageBox(),
                                )
                                    : _noImageBox(),
                              ),
                            ),

                            Positioned(
                              top: 10,
                              right: 10,
                              child: StatefulBuilder(
                                builder: (context, setState) {
                                  return FutureBuilder<bool>(
                                    future: LikeService.isLiked(data["id"] ?? data["title"]),
                                    builder: (context, snap) {
                                      bool isLiked = snap.data ?? false;
                                      final productId = data["id"] ?? data["title"];

                                      return GestureDetector(
                                        onTap: () async {
                                          if (isLiked) {
                                            await LikeService.unlikeProduct(productId);
                                          } else {
                                            await LikeService.likeProduct({...data, "id": productId});
                                          }

                                          setState(() {});
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
                                            isLiked ? Icons.favorite : Icons.favorite_border,
                                            size: 20,
                                            color: isLiked ? Colors.red : Colors.black,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
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
                          padding: const EdgeInsets.fromLTRB(
                              10, 10, 10, 0),
                          child: Text(
                            price != null
                                ? "\$${price.toStringAsFixed(2)}"
                                : "",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding:
                          const EdgeInsets.symmetric(
                              horizontal: 10),
                          child: Text(
                            "$title...",
                            maxLines: 2,
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
