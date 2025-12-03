import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_page.dart';
import 'order_details_page.dart';
import 'cart_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentPage extends StatelessWidget {
  final double amount;

  final String name;
  final String phone;
  final String fullAddress;

  const PaymentPage({
    super.key,
    required this.amount,
    required this.name,
    required this.phone,
    required this.fullAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: tkoBrown),
        title: Text(
          'Payment',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: tkoBrown,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              "Choose a payment method",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 20),

            _PaymentOption(
              icon: Icons.account_balance_wallet_rounded,
              label: "PayPal (Demo)",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _SuccessPage(
                      method: "PayPal",
                      amount: amount,
                      name: name,
                      phone: phone,
                      fullAddress: fullAddress,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            _PaymentOption(
              icon: Icons.credit_card_rounded,
              label: "Credit / Debit Card",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _CardPaymentPage(
                      amount: amount,
                      name: name,
                      phone: phone,
                      fullAddress: fullAddress,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            _PaymentOption(
              icon: Icons.apple_rounded,
              label: "Apple Pay (Demo)",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _SuccessPage(
                      method: "Apple Pay",
                      amount: amount,
                      name: name,
                      phone: phone,
                      fullAddress: fullAddress,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x15000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Colors.black87),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}

class _ModernInputField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;

  const _ModernInputField({
    required this.label,
    required this.hint,
    required this.icon,
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
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.black45),
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.black26,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }
}

class _CardPaymentPage extends StatelessWidget {
  final double amount;
  final String name;
  final String phone;
  final String fullAddress;

  const _CardPaymentPage({
    super.key,
    required this.amount,
    required this.name,
    required this.phone,
    required this.fullAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: tkoBrown),
        title: Text(
          'Card Payment',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: tkoBrown,
          ),
        ),
      ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Enter Card Details",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: tkoBrown,
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _ModernInputField(
                      label: "Card Number",
                      hint: "1234 5678 9012 3456",
                      icon: Icons.credit_card_rounded,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _ModernInputField(
                            label: "Expiry",
                            hint: "MM/YY",
                            icon: Icons.calendar_today_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ModernInputField(
                            label: "CVV",
                            hint: "123",
                            icon: Icons.lock_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tkoBrown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _SuccessPage(
                          method: "Card Payment",
                          amount: amount,
                          name: name,
                          phone: phone,
                          fullAddress: fullAddress,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    "Pay \$${amount.toStringAsFixed(2)}",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

class _SuccessPage extends StatelessWidget {
  final String method;
  final double amount;
  final String name;
  final String phone;
  final String fullAddress;

  const _SuccessPage({
    super.key,
    required this.method,
    required this.amount,
    required this.name,
    required this.phone,
    required this.fullAddress,
  });

  Future<void> _placeOrder(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final now = Timestamp.now();

    try {
      final settingsSnap = await FirebaseFirestore.instance
          .collection("settings")
          .doc("discounts")
          .get();
      final settings = settingsSnap.data() ?? {};

      final userDocSnap = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();
      final userDoc = userDocSnap.data() ?? {};

      final tierName = (userDoc['tier'] ?? 'Featherweight') as String;

      final generalSnap = await FirebaseFirestore.instance
          .collection("settings")
          .doc("general")
          .get();

      final generalData = generalSnap.data() ?? {};
      final multipliers = generalData["earnMultipliers"] ?? {};
      final earnX = (multipliers[tierName] ?? 1).toDouble();

      final cartRef = FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("cart");

      final cSnap = await cartRef.get();
      if (cSnap.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Cart is empty.")));
        return;
      }

      double subtotal = 0;
      double discountTotal = 0;

      List<Map<String, dynamic>> items = [];

      for (final d in cSnap.docs) {
        final data = d.data();

        final price = (data['price'] ?? 0) as num;
        final qty = (data['qty'] ?? 1) as int;

        final baseLine = price.toDouble() * qty;

        String bucket =
        (data['discountBucket'] ?? data['category'] ?? "other").toString();

        if (bucket.trim().isEmpty) bucket = "other";

        final discPct = (settings['categories']?[bucket]?[tierName] ?? 0)
            .toDouble();

        final lineDiscount = baseLine * (discPct / 100);
        final lineTotal = baseLine - lineDiscount;

        subtotal += baseLine;
        discountTotal += lineDiscount;

        items.add({
          'productId': data['productId'] ?? d.id,
          'name': data['name'] ?? '',
          'price': price.toDouble(),
          'qty': qty,
          'imageUrl': data['imageUrl'] ?? '',
          'category': data['category'] ?? '',
          'discountBucket': bucket,
          'lineSubtotal': baseLine,
          'discountPercent': discPct,
          'discountAmount': lineDiscount,
          'lineTotal': lineTotal,
        });
      }

      const shipping = 0.0;

      final totalBeforeDiscount = subtotal + shipping;
      final total = totalBeforeDiscount - discountTotal;

      final address = {
        "name": name,
        "phone": phone,
        "fullAddress": fullAddress,
      };

      final userOrderRef = FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("orders");

      final orderDoc = await userOrderRef.add({
        'createdAt': now,
        'status': 'pending',
        'items': items,
        'subtotal': subtotal,
        'shipping': shipping,
        'discountTotal': discountTotal,
        'total': total,
        'tierAtPurchase': tierName,
        'address': address,
      });

      await FirebaseFirestore.instance
          .collection("orders_master")
          .add({
        "userId": uid,
        "userEmail": user.email,
        "userOrderId": orderDoc.id,
        "createdAt": now,
        "status": "pending",
        "items": items,
        "subtotal": subtotal,
        "shipping": shipping,
        "discountTotal": discountTotal,
        "total": total,
        "tierAtPurchase": tierName,
        "address": address,
      });

      final pointsEarned = (total * earnX).floor();

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(userDocSnap.reference);
        final data = snap.data() ?? {};

        final currentYear = (data['yearPoints'] ?? 0) as int;
        final currentLife = (data['lifetimePts'] ?? 0) as int;

        tx.update(userDocSnap.reference, {
          'yearPoints': currentYear + pointsEarned,
          'lifetimePts': currentLife + pointsEarned,
        });
      });

      for (final doc in cSnap.docs) {
        await doc.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Order placed! +$pointsEarned pts")),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(initialTab: 0),
        ),
            (route) => false,
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            Text(
              "Payment Successful!",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text("Paid via $method", style: GoogleFonts.poppins()),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () async {
                await _placeOrder(context);
              },
              child: const Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }
}
