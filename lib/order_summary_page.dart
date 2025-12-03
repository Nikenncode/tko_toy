import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'payment_page.dart';
import 'cart_service.dart';
import 'home_page.dart' show tkoOrange, tkoCream, tkoBrown, HomePage;


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

double _earnMultiplierForTier(
    Map<String, dynamic> settings,
    String tierName,
    ) {
  final earnMap =
  Map<String, dynamic>.from(settings['earnMultipliers'] ?? {});
  final raw = earnMap[tierName];
  if (raw is num) return raw.toDouble();
  return 1.0;
}

String _inferBucket(dynamic raw) {
  final text = raw?.toString().toLowerCase() ?? '';

  if (text.contains('single')) return 'singles';
  if (text.contains('sealed')) return 'sealed';
  if (text.contains('supply') || text.contains('accessor')) {
    return 'supplies';
  }
  if (text.contains('toy') || text.contains('beyblade')) {
    return 'toys';
  }
  return '';
}

double _categoryDiscountPercent({
  required Map<String, dynamic> settings,
  required String tierName,
  required String bucket,
}) {
  Map<String, dynamic>? tierMap;

  final discountsRoot = settings['discounts'];
  if (discountsRoot is Map<String, dynamic> &&
      discountsRoot[tierName] is Map<String, dynamic>) {
    tierMap = Map<String, dynamic>.from(discountsRoot[tierName]);
  }

  if (tierMap == null && settings[tierName] is Map<String, dynamic>) {
    tierMap = Map<String, dynamic>.from(settings[tierName]);
  }

  if (tierMap == null) return 0.0;

  final bucketLower = bucket.toLowerCase();
  String? matchedKey;

  for (final k in tierMap.keys) {
    final lk = k.toString().toLowerCase();
    if (lk == bucketLower ||
        bucketLower.contains(lk) ||
        lk.contains(bucketLower)) {
      matchedKey = k;
      break;
    }
  }

  if (matchedKey == null) return 0.0;
  final v = tierMap[matchedKey];
  if (v is num) return v.toDouble();
  return 0.0;
}

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
                  const _SectionTitle('Shipping details'),
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

                  const _SectionTitle('Items in your cart'),
                  const SizedBox(height: 8),
                  const _CartPreviewBox(),
                  const SizedBox(height: 22),

                  const _SectionTitle('Payment summary'),
                  const SizedBox(height: 8),
                  const _SummaryTotalsBox(),
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
                  onPressed: _isPlacing
                      ? null
                      : () async {
                    if (_nameCtrl.text.trim().isEmpty ||
                        _phoneCtrl.text.trim().isEmpty ||
                        _addressCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all address fields.')),
                      );
                      return;
                    }

                    final cartTotal = await CartService.instance.getCartTotal();

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentPage(
                          amount: cartTotal,
                          name: _nameCtrl.text.trim(),
                          phone: _phoneCtrl.text.trim(),
                          fullAddress: _addressCtrl.text.trim(),
                        ),
                      ),
                    );
                  },


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
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.black,
                      ),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              BorderSide(color: Colors.black.withOpacity(.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              BorderSide(color: Colors.black.withOpacity(.12)),
            ),
          ),
        ),
      ],
    );
  }
}

class _CartPreviewBox extends StatelessWidget {
  const _CartPreviewBox();

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
              for (int i = 0; i < docs.length && i < 3; i++) ...[
                _CartPreviewRow(data: docs[i].data()),
                if (i != docs.length - 1 && i < 2)
                  const Divider(height: 12),
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

class _SummaryTotalsBox extends StatelessWidget {
  const _SummaryTotalsBox();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadSettingsAndTier(),
      builder: (context, settingsSnap) {
        if (settingsSnap.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child:
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final settings =
            settingsSnap.data?['settings'] as Map<String, dynamic>? ??
                <String, dynamic>{};
        final tierName =
        (settingsSnap.data?['tierName'] ?? 'Featherweight') as String;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: CartService.instance.cartStream(),
          builder: (context, snapshot) {
            double subtotal = 0;
            double discountTotal = 0;

            if (snapshot.hasData) {
              for (final d in snapshot.data!.docs) {
                final data = d.data();
                final price = (data['price'] ?? 0) as num;
                final qty = (data['qty'] ?? 1) as int;
                final baseLine = price.toDouble() * qty;

                String bucket =
                (data['discountBucket'] ?? _inferBucket(data['category']))
                    .toString();
                if (bucket.trim().isEmpty) {
                  bucket = 'other';
                }

                final discPct = _categoryDiscountPercent(
                  settings: settings,
                  tierName: tierName,
                  bucket: bucket,
                );

                final lineDiscount = baseLine * (discPct / 100.0);
                final lineTotal = baseLine - lineDiscount;

                subtotal += baseLine;
                discountTotal += lineDiscount;
              }
            }

            const shipping = 0.0;
            final totalBeforeDiscount = subtotal + shipping;
            final totalAfterDiscount = totalBeforeDiscount - discountTotal;

            const double hstRate = 0.13;
            final hst = totalAfterDiscount * hstRate;

            final grandTotal = totalAfterDiscount + hst;

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _row('Subtotal (before discount)', subtotal),
                  const SizedBox(height: 6),
                  _row('Discount', -discountTotal),
                  const SizedBox(height: 6),
                  _row('Shipping', shipping),
                  const SizedBox(height: 6),
                  _row('HST (13%)', hst),
                  const Divider(height: 18),
                  _row('Grand Total', grandTotal, isBold: true),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _row(String label, double value, {bool isBold = false}) {
    final display =
    (label == 'Discount' && value != 0) ? '-\$${value.abs().toStringAsFixed(2)}'
        : '\$${value.toStringAsFixed(2)}';

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
          display,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
