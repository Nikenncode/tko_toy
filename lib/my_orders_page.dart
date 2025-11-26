// lib/my_orders_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_page.dart';           // for tkoBrown, tkoCream, tkoOrange
import 'order_details_page.dart';  // we'll create this next

class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _ordersStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // return empty stream if no user
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
        ),
        body: const Center(
          child: Text('Please log in to view your orders.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: tkoCream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.4,
        centerTitle: true,
        title: Text(
          'My Orders',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: tkoBrown,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _ordersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: tkoBrown),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const _EmptyOrdersState();
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final orderNumber =
              (data['orderNumber'] ?? data['orderId'] ?? '').toString();
              final status = (data['status'] ?? 'pending').toString();
              final total = (data['total'] ?? 0) as num;
              final createdAt = data['createdAt'] as Timestamp?;
              final items = (data['items'] as List?) ?? [];

              final dateText = createdAt != null
                  ? _formatDateTime(createdAt.toDate())
                  : 'Unknown date';

              return _OrderCard(
                orderId: doc.id,
                orderNumber: orderNumber,
                status: status,
                total: total.toDouble(),
                dateText: dateText,
                itemCount: items.length,
                fullData: data,
              );
            },
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    // Simple: Jan 24, 2025 • 3:42 PM
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final m = months[dt.month - 1];
    final day = dt.day;
    final year = dt.year;

    final hour12 = dt.hour == 0
        ? 12
        : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';

    return '$m $day, $year • $hour12:$minute $ampm';
  }
}

class _OrderCard extends StatelessWidget {
  final String orderId;
  final String orderNumber;
  final String status;
  final double total;
  final String dateText;
  final int itemCount;
  final Map<String, dynamic> fullData;

  const _OrderCard({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.total,
    required this.dateText,
    required this.itemCount,
    required this.fullData,
  });

  Color _statusColor() {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade600;
      case 'completed':
      case 'shipped':
      case 'delivered':
        return Colors.green.shade700;
      case 'cancelled':
        return Colors.red.shade600;
      default:
        return Colors.blueGrey.shade600;
    }
  }

  String _statusLabel() {
    final s = status.toLowerCase();
    if (s == 'pending') return 'Pending';
    if (s == 'completed') return 'Completed';
    if (s == 'shipped') return 'Shipped';
    if (s == 'delivered') return 'Delivered';
    if (s == 'cancelled') return 'Cancelled';
    return status;
  }

  @override
  Widget build(BuildContext context) {
    final c = _statusColor();

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailsPage(
              orderId: orderId,
              orderData: fullData,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(.04)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x16000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP ROW: Order ID + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    orderNumber.isNotEmpty
                        ? orderNumber
                        : 'Order $orderId',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: tkoBrown,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.withOpacity(.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _statusLabel(),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: c,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // DATE + ITEMS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateText,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black.withOpacity(.65),
                  ),
                ),
                Text(
                  '$itemCount item${itemCount == 1 ? '' : 's'}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black.withOpacity(.65),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // TOTAL + ARROW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: tkoBrown,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    size: 22, color: Colors.black54),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyOrdersState extends StatelessWidget {
  const _EmptyOrdersState();

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
                Icons.receipt_long_rounded,
                size: 42,
                color: tkoBrown,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No orders yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: tkoBrown,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'When you place an order, it will show up here.',
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
