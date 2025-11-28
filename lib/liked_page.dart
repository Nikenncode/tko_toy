import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'like_service.dart';
import 'Product_description.dart';
import 'home_page.dart';
import 'cart_page.dart';
import 'cart_service.dart';
import 'notifications_page.dart';

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

class LikedPage extends StatelessWidget {
  const LikedPage({super.key});

  Future<void> _addToCart(BuildContext context, Map<String, dynamic> product) async {
    try {
      final price = _getPrice(product["variants"]);
      if (price == null) return;

      final title = product["title"]?.toString() ?? "";
      final images = (product["images"] ?? []) as List;
      final imageUrl = images.isNotEmpty ? images.first : "";
      final category =
          product["category"]?.toString() ??
              product["parentTab"]?.toString() ??
              "";

      final productId = product["docId"]?.toString() ??
          product["id"]?.toString() ??
          product["title"]?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString();

      await CartService.instance.addToCart(
        productId: productId,
        name: title,
        price: price,
        imageUrl: imageUrl,
        category: category,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Added to cart ✓"),
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 900),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error adding to cart: $e"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.4,
        title: Text(
          "Favourites",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              );
            },
            icon: const Icon(Icons.notifications_none, color: Colors.black87),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartPage()),
                  );
                },
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black87),
              ),

              Positioned(
                right: 4,
                top: 4,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("users")
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .collection("cart")
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();

                    final count = snapshot.data!.docs.length;
                    if (count == 0) return const SizedBox();

                    return Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          )
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: LikeService.likedItemsStream(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Text(
                "No liked items yet",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
                child: Text(
                  "${docs.length} ITEMS",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              ),

              Expanded(
                child: ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade300),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final id = data["id"];
                    final images = (data["images"] ?? []) as List;
                    final imageUrl = images.isNotEmpty ? images.first : null;

                    final productPrice = _getPrice(data["variants"]);

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ProductDetailsPage(product: data)),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 12,
                              spreadRadius: 1,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [

                            Container(
                              width: 75,
                              height: 75,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: imageUrl == null
                                  ? Icon(
                                Icons.image_not_supported,
                                size: 28,
                                color: Colors.grey.shade400,
                              )
                                  : Image.network(
                                imageUrl,
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                              ),
                            ),

                            const SizedBox(width: 16),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [

                                      Expanded(
                                        child: Text(
                                          data["title"] ?? "",
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: tkoBrown,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 10),

                                      GestureDetector(
                                        onTap: () async {
                                          try {
                                            await LikeService.unlikeProduct(id);

                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text("Removed from wishlist"),
                                                duration: Duration(milliseconds: 900),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text("Error removing item: $e"),
                                                duration: Duration(milliseconds: 1200),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        },
                                        child: const Icon(
                                          Icons.delete_outline,
                                          size: 22,
                                          color: Colors.black45,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [

                                      Text(
                                        "C\$ ${(productPrice ?? 0).toStringAsFixed(2)}",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),

                                      GestureDetector(
                                        onTap: () async {
                                          await _addToCart(context, data);

                                          await LikeService.unlikeProduct(id);

                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text("Added to cart ✓"),
                                                duration: Duration(milliseconds: 900),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        },

                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.black87,
                                            borderRadius: BorderRadius.circular(30),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              )
                                            ],
                                          ),
                                          child: Text(
                                            "Add to Cart",
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),

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
                MaterialPageRoute(builder: (_) => const HomePage(initialTab: 1)),
                    (route) => false,
              );
              break;

            case 2:
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


