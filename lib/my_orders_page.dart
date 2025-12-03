// lib/my_orders_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'order_tracking_page.dart';
import 'home_page.dart';


class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _ordersStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
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
    return Scaffold(
      backgroundColor: tkoCream,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: tkoBrown),
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

          final orders = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = orders[index];
              final data = doc.data();

              final orderId   = doc.id;
              final createdAt = data['createdAt'] as Timestamp?;
              final total     = (data['total'] ?? 0) as num;
              final itemCount = (data['itemCount'] ?? (data['items'] as List?)?.length ?? 0) as int;
              final status    = (data['status'] ?? 'pending') as String;

              String dateText = '';
              if (createdAt != null) {
                final dt = createdAt.toDate();
                dateText =
                '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
                    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
              }

              // small one-line address preview
              String addressLine = '';
              final rawAddr = data['address'];
              if (rawAddr is Map) {
                final addrMap = Map<String, dynamic>.from(rawAddr);
                addressLine =
                    (addrMap['fullAddress'] ?? addrMap['address'] ?? '')
                        .toString();
              }

              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderTrackingPage(
                        orderId: orderId,
                        orderData: data,
                      ),
                    ),
                  );
                },
                child: _OrderCard(
                  orderId: orderId,
                  dateText: dateText,
                  total: total.toDouble(),
                  itemCount: itemCount,
                  status: status,
                  addressLine: addressLine,
                ),
              );
            },
          );
        },
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
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: tkoBrown,
            ),
            const SizedBox(height: 14),
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
              'Your past orders will show up here once you place something.',
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

class _OrderCard extends StatelessWidget {
  final String orderId;
  final String dateText;
  final double total;
  final int itemCount;
  final String status;
  final String addressLine;

  const _OrderCard({
    required this.orderId,
    required this.dateText,
    required this.total,
    required this.itemCount,
    required this.status,
    required this.addressLine,
  });

  Color get _statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade700;
      case 'confirmed':
        return Colors.blueGrey.shade700;
      case 'processing':
        return Colors.blue.shade700;
      case 'shipped':
      case 'out_for_delivery':
        return Colors.deepPurple.shade700;
      case 'delivered':
        return Colors.green.shade700;
      case 'cancelled':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tkoBrown.withOpacity(.08),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: tkoBrown,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #$orderId',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: tkoBrown,
                  ),
                ),
                if (dateText.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    dateText,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.black.withOpacity(.55),
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  '$itemCount item${itemCount == 1 ? '' : 's'} · \$${total.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black.withOpacity(.75),
                  ),
                ),
                if (addressLine.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    addressLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.black.withOpacity(.55),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status[0].toUpperCase() + status.substring(1),
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
