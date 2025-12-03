import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_page.dart';

class OrderDetailsPage extends StatelessWidget {
  final String orderId;
  const OrderDetailsPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: tkoCream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Order Tracking",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: tkoBrown,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .collection("orders")
            .doc(orderId)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data!.data();
          if (data == null) {
            return const Center(child: Text("Order not found"));
          }

          final status = data["status"] ?? "pending";
          final total = (data["total"] ?? 0.0) as num;
          final items = (data["items"] as List? ?? const []);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statusTracker(status),

                const SizedBox(height: 20),

                Text(
                  "Order Items",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),

                ...items
                    .whereType<Map<String, dynamic>>()
                    .map((item) => _itemCard(item))
                    .toList(),

                const SizedBox(height: 20),

                Text(
                  "Total Paid: \$${total.toStringAsFixed(2)}",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: tkoBrown,
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // DISPLAY
  Widget _itemCard(Map<String, dynamic> item) {
    final name = (item["name"] ?? "").toString();
    final qty = (item["qty"] ?? 1) as int;

    final price = (item["price"] ?? 0) as num;

    final lineSubtotal = (item["lineSubtotal"] ?? (price * qty)) as num;
    final lineTotal = (item["lineTotal"] ?? lineSubtotal) as num;
    final discountAmount = (item["discountAmount"] ?? 0) as num;
    final discountPercent = (item["discountPercent"] ?? 0) as num;

    final hasDiscount =
        discountAmount > 0 && discountPercent > 0 && lineTotal < lineSubtotal;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: (item['imageUrl'] != null &&
                item['imageUrl'].toString().isNotEmpty)
                ? Image.network(
              item['imageUrl'],
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            )
                : Container(
              width: 60,
              height: 60,
              color: Colors.grey.shade300,
              child: Icon(
                Icons.image_not_supported,
                color: Colors.grey.shade500,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Qty: $qty",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black45,
                  ),
                ),
                const SizedBox(height: 4),
                if (hasDiscount) ...[
                  Text(
                    "Before discount: \$${lineSubtotal.toStringAsFixed(2)}",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  Text(
                    "You saved \$${discountAmount.toStringAsFixed(2)} (${discountPercent.toStringAsFixed(0)}%)",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),

          Text(
            "\$${lineTotal.toStringAsFixed(2)}",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusTracker(String status) {
    final steps = [
      "pending",
      "confirmed",
      "processing",
      "shipped",
      "out_for_delivery",
      "delivered",
    ];

    int activeStep = steps.indexOf(status);
    if (activeStep == -1) activeStep = 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: List.generate(steps.length, (i) {
          final isDone = i <= activeStep;
          final label = steps[i].replaceAll("_", " ").toUpperCase();

          return Column(
            children: [
              Row(
                children: [
                  Icon(
                    isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isDone ? tkoBrown : Colors.grey,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: isDone ? tkoBrown : Colors.grey,
                    ),
                  ),
                ],
              ),
              if (i != steps.length - 1)
                Container(
                  margin: const EdgeInsets.only(left: 14),
                  height: 20,
                  width: 2,
                  color: i < activeStep ? tkoBrown : Colors.grey.shade300,
                ),
            ],
          );
        }),
      ),
    );
  }
}
