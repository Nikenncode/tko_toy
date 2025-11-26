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
        title: Text("Order Tracking",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: tkoBrown,
            )),
        centerTitle: true,
      ),

      body: StreamBuilder(
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
            return Center(child: Text("Order not found"));
          }

          final status = data["status"] ?? "pending";
          final total = data["total"] ?? 0.0;
          final items = (data["items"] as List? ?? []);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔥 STATUS BAR
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

                ...items.map((item) => _itemCard(item)),

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

  Widget _itemCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: item['imageUrl'] != null && item['imageUrl'] != ""
                ? Image.network(item['imageUrl'], width: 60, height: 60, fit: BoxFit.cover)
                : Container(
              width: 60,
              height: 60,
              color: Colors.grey.shade300,
            ),
          ),

          const SizedBox(width: 10),

          // NAME + QTY
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item["name"] ?? "",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    )),
                Text("Qty: ${item["qty"]}",
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.black45)),
              ],
            ),
          ),

          Text(
            "\$${item['lineTotal'].toStringAsFixed(2)}",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          )
        ],
      ),
    );
  }

  /// 🔥 Animated Status Tracker
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
