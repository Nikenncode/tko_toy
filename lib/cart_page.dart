import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'my_orders_page.dart';
import 'cart_service.dart';
import 'home_page.dart';
import 'order_summary_page.dart';

Future<Map<String, dynamic>> _loadSettings() async {
  final snap =
  await FirebaseFirestore.instance.doc('settings/general').get();
  return snap.data() ?? <String, dynamic>{};
}

Future<Map<String, dynamic>> _loadUserDoc(User user) async {
  final snap = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();
  return snap.data() ?? <String, dynamic>{};
}

double _categoryDiscountPercent({
  required Map<String, dynamic> settings,
  required String tierName,
  required String categoryBucket,
}) {
  final discounts = settings['discounts'];
  if (discounts is Map<String, dynamic>) {
    final byTier = Map<String, dynamic>.from(discounts[tierName] ?? {});
    final raw = byTier[categoryBucket];
    if (raw is num) return raw.toDouble();
  }

  final rawTier = settings[tierName];
  if (rawTier is Map<String, dynamic>) {
    final value = rawTier[categoryBucket];
    if (value is num) return value.toDouble();
  }
  return 0.0;
}

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  Future<Map<String, dynamic>> _loadSettingsAndTier() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {
        'settings': <String, dynamic>{},
        'tierName': 'Featherweight',
      };
    }
    final settings = await _loadSettings();
    final userDoc = await _loadUserDoc(user);
    final tierName = (userDoc['tier'] ?? 'Featherweight') as String;
    return {
      'settings': settings,
      'tierName': tierName,
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'My Cart',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: tkoBrown,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Text(
            'Please log in to see your cart.',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: tkoCream,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white.withOpacity(.96),
        centerTitle: true,
        title: Text(
          'My Cart',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: tkoBrown,
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.history,
              color: tkoBrown,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MyOrdersPage(),
                ),
              );
            },
          ),
        ],
      ),

      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadSettingsAndTier(),
        builder: (context, settingsSnap) {
          if (settingsSnap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: tkoBrown),
            );
          }

          final settings =
              settingsSnap.data?['settings'] as Map<String, dynamic>? ?? {};
          final tierName =
          (settingsSnap.data?['tierName'] ?? 'Featherweight') as String;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
              double totalDiscount = 0;

              for (final d in docs) {
                final data = d.data();
                final price = (data['price'] ?? 0) as num;
                final qty = (data['qty'] ?? 1) as int;
                final baseLine = price.toDouble() * qty;

                final bucket =
                (data['discountBucket'] ?? data['category'] ?? 'other')
                    .toString();

                final discPct = _categoryDiscountPercent(
                  settings: settings,
                  tierName: tierName,
                  categoryBucket: bucket,
                );

                final lineDiscount = baseLine * (discPct / 100.0);
                final lineTotal = baseLine - lineDiscount;

                total += lineTotal;
                totalDiscount += lineDiscount;
              }

              return Column(
                children: [
                  const SizedBox(height: 12),

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

                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data();

                        final name = (data['name'] ?? '') as String;
                        final price = (data['price'] ?? 0) as num;
                        final qty = (data['qty'] ?? 1) as int;
                        final imageUrl = (data['imageUrl'] ?? '') as String;
                        final category =
                        (data['category'] ?? '') as String;
                        final bucket =
                        (data['discountBucket'] ?? data['category'] ?? 'other')
                            .toString();

                        final baseLine = price.toDouble() * qty;
                        final discPct = _categoryDiscountPercent(
                          settings: settings,
                          tierName: tierName,
                          categoryBucket: bucket,
                        );
                        final lineDiscount =
                            baseLine * (discPct / 100.0);
                        final lineTotal = baseLine - lineDiscount;

                        return _CartItemCard(
                          docId: doc.id,
                          name: name,
                          unitPrice: price.toDouble(),
                          qty: qty,
                          imageUrl: imageUrl,
                          category: category,
                          discountPercent: discPct,
                          lineDiscount: lineDiscount,
                          lineTotal: lineTotal,
                          fullData: data,
                        );
                      },
                    ),
                  ),

                  _CartTotalBar(
                    total: total,
                    totalDiscount: totalDiscount,
                  ),
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: TkoBottomNav(
        index: -1,
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
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final String docId;
  final String name;
  final double unitPrice;
  final int qty;
  final String imageUrl;
  final String category;
  final double discountPercent;
  final double lineDiscount;
  final double lineTotal;
  final Map<String, dynamic> fullData;

  const _CartItemCard({
    required this.docId,
    required this.name,
    required this.unitPrice,
    required this.qty,
    required this.imageUrl,
    required this.category,
    required this.discountPercent,
    required this.lineDiscount,
    required this.lineTotal,
    required this.fullData,
  });

  @override
  Widget build(BuildContext context) {
    final baseLine = unitPrice * qty;

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
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: (imageUrl == null || imageUrl.isEmpty)
                    ? Container(
                  color: Colors.grey.shade200,
                )
                    : Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Expanded(
                        child: Text(
                          name,
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

                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 20,
                        ),
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

                  if (category.isNotEmpty)
                    Text(
                      category,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.black.withOpacity(.55),
                      ),
                    ),

                  const SizedBox(height: 6),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$${unitPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),

                          if (discountPercent > 0)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total: \$${lineTotal.toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                Text(
                                  'Saving \$${lineDiscount.toStringAsFixed(2)} (${discountPercent.toStringAsFixed(0)}%)',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              'Total: \$${baseLine.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.black.withOpacity(.60),
                              ),
                            ),
                        ],
                      ),

                      Row(
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              size: 20,
                            ),
                            onPressed: () async {
                              try {
                                await CartService.instance.decreaseQty(
                                  productId: fullData['productId'] ?? docId,
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            },
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
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

                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 20,
                            ),
                            onPressed: () async {
                              try {
                                await CartService.instance.addToCart(
                                  productId:
                                  fullData['productId'] ?? docId,
                                  name: name,
                                  price: unitPrice,
                                  imageUrl: imageUrl,
                                  category: category,
                                  discountBucket:
                                  fullData['discountBucket'],
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
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
  final double totalDiscount;

  const _CartTotalBar({
    required this.total,
    required this.totalDiscount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (totalDiscount > 0)
                    Text(
                      'You’re saving \$${totalDiscount.toStringAsFixed(2)} on this order.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.green.shade700,
                      ),
                    ),
                  if (totalDiscount > 0) const SizedBox(height: 2),
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
                  padding: const EdgeInsets.symmetric(horizontal: 24),
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
  const _EmptyCartState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
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
              'Add some items to see them here.',
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