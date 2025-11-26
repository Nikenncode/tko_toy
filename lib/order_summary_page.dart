// lib/order_summary_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_page.dart' show tkoOrange, tkoCream, tkoBrown, HomePage;
import 'cart_service.dart';

class OrderSummaryPage extends StatefulWidget {
  const OrderSummaryPage({super.key});

  @override
  State<OrderSummaryPage> createState() => _OrderSummaryPageState();
}

class _OrderSummaryPageState extends State<OrderSummaryPage> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  bool _isPlacing = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first.')),
      );
      return;
    }

    if (_nameCtrl.text.trim().isEmpty ||
        _phoneCtrl.text.trim().isEmpty ||
        _addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all address fields.')),
      );
      return;
    }

    setState(() => _isPlacing = true);

    try {
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart');

      final cartSnap = await cartRef.get();
      if (cartSnap.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your cart is empty.')),
        );
        setState(() => _isPlacing = false);
        return;
      }

      // ---------- build line items & totals ----------
      double subtotal = 0;
      final List<Map<String, dynamic>> items = [];

      for (final d in cartSnap.docs) {
        final data = d.data();
        final price = (data['price'] ?? 0) as num;
        final qty = (data['qty'] ?? 1) as int;
        final lineTotal = price.toDouble() * qty;

        subtotal += lineTotal;

        items.add({
          'productId': data['productId'] ?? d.id,
          'name': data['name'] ?? '',
          'price': price.toDouble(),
          'qty': qty,
          'imageUrl': data['imageUrl'] ?? '',
          'category': data['category'] ?? '',
          'lineTotal': lineTotal,
        });
      }

      final shippingCost = 0.0; // change later if needed
      final total = subtotal + shippingCost;
      final itemCount = items.length;
      final now = Timestamp.now();

      // 👇 shipping map that MyOrdersPage can show
      final shipping = {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'fullAddress': _addressCtrl.text.trim(),
      };

      // ---------- 1) user orders collection ----------
      final userOrderRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('orders');

      final userOrderDoc = await userOrderRef.add({
        'createdAt': now,
        'status': 'Placed',        // matches MyOrdersPage colour logic
        'items': items,
        'itemCount': itemCount,    // 👈 used in MyOrdersPage
        'subtotal': subtotal,
        'shippingCost': shippingCost,
        'total': total,
        'shipping': shipping,      // 👈 MyOrdersPage reads this
      });

      // ---------- 2) master orders collection ----------
      final masterRef =
      FirebaseFirestore.instance.collection('orders_master');

      await masterRef.add({
        'userId': user.uid,
        'userEmail': user.email,
        'userOrderId': userOrderDoc.id,
        'createdAt': now,
        'status': 'Placed',
        'items': items,
        'itemCount': itemCount,
        'subtotal': subtotal,
        'shippingCost': shippingCost,
        'total': total,
        'shipping': shipping,
      });

      // ---------- 3) update points (yearPoints / lifetimePts) ----------
      final pointsEarned = total.floor(); // 1 pt per $1
      final userDocRef =
      FirebaseFirestore.instance.collection('users').doc(user.uid);

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(userDocRef);
        final data = snap.data() ?? {};
        final currentYear = (data['yearPoints'] ?? 0) as int;
        final currentLife = (data['lifetimePts'] ?? 0) as int;

        tx.update(userDocRef, {
          'yearPoints': currentYear + pointsEarned,
          'lifetimePts': currentLife + pointsEarned,
        });
      });

      // ---------- 4) clear cart ----------
      await CartService.instance.clearCart();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );

      // ---------- 5) go back to home ----------
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage(initialTab: 0)),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error placing order: $e')),
      );
    } finally {
      if (mounted) setState(() => _isPlacing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tkoCream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Order Summary',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: tkoBrown,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle('Shipping details'),
                  const SizedBox(height: 8),
                  _TextField(
                    controller: _nameCtrl,
                    label: 'Full name',
                    hint: 'John Doe',
                  ),
                  const SizedBox(height: 10),
                  _TextField(
                    controller: _phoneCtrl,
                    label: 'Phone',
                    hint: '+1 555 555 5555',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 10),
                  _TextField(
                    controller: _addressCtrl,
                    label: 'Address',
                    hint: 'Street, city, province, postal code',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 22),

                  _SectionTitle('Items in your cart'),
                  const SizedBox(height: 8),
                  _CartPreviewBox(),
                  const SizedBox(height: 22),

                  _SectionTitle('Payment summary'),
                  const SizedBox(height: 8),
                  _SummaryTotalsBox(),
                ],
              ),
            ),
          ),

          // bottom button
          SafeArea(
            top: false,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 16,
                    offset: Offset(0, -6),
                  )
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isPlacing ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tkoOrange,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: _isPlacing
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                      : Text(
                    'Place order',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// small section title
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: tkoBrown,
      ),
    );
  }
}

/// styled text field
class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;

  const _TextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.black.withOpacity(.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.black.withOpacity(.12)),
            ),
          ),
        ),
      ],
    );
  }
}

/// shows a short list of cart items
class _CartPreviewBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: CartService.instance.cartStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Your cart is empty.',
              style: GoogleFonts.poppins(),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              for (final d in docs.take(3)) ...[
                _CartPreviewRow(data: d.data()),
                if (d != docs.last) const Divider(height: 12),
              ],
              if (docs.length > 3) ...[
                const SizedBox(height: 6),
                Text(
                  '+ ${docs.length - 3} more item(s)',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black.withOpacity(.6),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CartPreviewRow extends StatelessWidget {
  final Map<String, dynamic> data;
  const _CartPreviewRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final name = (data['name'] ?? '') as String;
    final qty = (data['qty'] ?? 1) as int;
    final price = (data['price'] ?? 0) as num;
    final line = price.toDouble() * qty;

    return Row(
      children: [
        Expanded(
          child: Text(
            '$name × $qty',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '\$${line.toStringAsFixed(2)}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

/// totals box (subtotal / shipping / total)
class _SummaryTotalsBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: CartService.instance.cartStream(),
      builder: (context, snapshot) {
        double subtotal = 0;
        if (snapshot.hasData) {
          for (final d in snapshot.data!.docs) {
            final data = d.data();
            final price = (data['price'] ?? 0) as num;
            final qty = (data['qty'] ?? 1) as int;
            subtotal += price.toDouble() * qty;
          }
        }
        final shipping = 0.0;
        final total = subtotal + shipping;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _row('Subtotal', subtotal),
              const SizedBox(height: 6),
              _row('Shipping', shipping),
              const Divider(height: 18),
              _row('Total', total, isBold: true),
            ],
          ),
        );
      },
    );
  }

  Widget _row(String label, double value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
