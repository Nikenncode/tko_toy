// lib/cart_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'cart_service.dart';
import 'home_page.dart';
import 'order_summary_page.dart';


class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Cart'),
        ),
        body: const Center(
          child: Text('Please log in to see your cart.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: tkoCream,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white.withOpacity(.96),
        title: Text(
          'My Cart',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: tkoBrown,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: CartService.instance.cartStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: tkoBrown),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _EmptyCartState();
          }

          final docs = snapshot.data!.docs;

          double total = 0;
          for (final d in docs) {
            final data = d.data();
            final price = (data['price'] ?? 0) as num;
            final qty = (data['qty'] ?? 1) as int;
            total += price.toDouble() * qty;
          }

          return Column(
            children: [
              const SizedBox(height: 12),

              // Hint / summary
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'You have ${docs.length} item${docs.length == 1 ? '' : 's'} in your cart.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.black.withOpacity(.65),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // CART LIST
              Expanded(
                child: ListView.separated(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();

                    final name = (data['name'] ?? '') as String;
                    final price = (data['price'] ?? 0) as num;
                    final qty = (data['qty'] ?? 1) as int;
                    final imageUrl = (data['imageUrl'] ?? '') as String;
                    final category = (data['category'] ?? '') as String;

                    return _CartItemCard(
                      docId: doc.id,
                      name: name,
                      price: price.toDouble(),
                      qty: qty,
                      imageUrl: imageUrl,
                      category: category,
                      fullData: data,
                    );
                  },
                ),
              ),

              // TOTAL + CHECKOUT
              _CartTotalBar(total: total),
            ],
          );
        },
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final String docId;
  final String name;
  final double price;
  final int qty;
  final String imageUrl;
  final String category;
  final Map<String, dynamic> fullData;

  const _CartItemCard({
    required this.docId,
    required this.name,
    required this.price,
    required this.qty,
    required this.imageUrl,
    required this.category,
    required this.fullData,
  });

  @override
  Widget build(BuildContext context) {
    final lineTotal = price * qty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(.04)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 70,
                height: 70,
                color: Colors.grey.shade100,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.image_not_supported,
                    color: Colors.grey.shade400,
                  ),
                )
                    : Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.grey.shade400,
                  size: 30,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // NAME, CATEGORY, QTY, PRICE
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NAME
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: tkoBrown,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // CATEGORY
                  if (category.isNotEmpty)
                    Text(
                      category,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.black.withOpacity(.55),
                      ),
                    ),

                  const SizedBox(height: 6),

                  // PRICE + QTY ROW
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // price x qty
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$${price.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Line total: \$${lineTotal.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.black.withOpacity(.60),
                            ),
                          ),
                        ],
                      ),

                      // QTY + ACTIONS
                      Row(
                        children: [
                          // QTY CHIP
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: tkoCream,
                            ),
                            child: Text(
                              'Qty: $qty',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: tkoBrown,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // + BUTTON (add one more)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.add_circle_outline, size: 20),
                            onPressed: () async {
                              try {
                                await CartService.instance.addToCart(
                                  productId: docId,
                                  name: name,
                                  price: price,
                                  imageUrl: imageUrl,
                                  category: category,
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            },
                          ),

                          // DELETE
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () async {
                              await CartService.instance.removeFromCart(docId);
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Removed from cart'),
                                ),
                              );
                            },
                          ),
                        ],
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
  }
}

class _CartTotalBar extends StatelessWidget {
  final double total;

  const _CartTotalBar({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // TOTAL TEXT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.black.withOpacity(.60),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: tkoBrown,
                    ),
                  ),
                ],
              ),
            ),

            // CHECKOUT BUTTON
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OrderSummaryPage(),
                    ),
                  );
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: tkoOrange,
                  foregroundColor: Colors.black,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  'Checkout',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCartState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 42,
                color: tkoBrown,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your cart is empty',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: tkoBrown,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add some toys and supplies to see them here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.black.withOpacity(.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
