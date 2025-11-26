// lib/order_details_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_page.dart'; // for tkoBrown, tkoCream, tkoOrange

class OrderDetailsPage extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const OrderDetailsPage({
    super.key,
    required this.orderId,
    required this.orderData,
  });

  @override
  Widget build(BuildContext context) {
    final orderNumber =
    (orderData['orderNumber'] ?? orderData['orderId'] ?? '').toString();
    final status = (orderData['status'] ?? 'pending').toString();
    final subtotal = (orderData['subtotal'] ?? 0) as num;
    final tax = (orderData['tax'] ?? 0) as num;
    final total = (orderData['total'] ?? 0) as num;
    final items = (orderData['items'] as List?) ?? [];

    final createdAt = orderData['createdAt'];
    String dateText = 'Unknown date';
    if (createdAt != null && createdAt is DateTime) {
      dateText = createdAt.toIso8601String();
    } else if (createdAt != null &&
        createdAt.toString().contains('Timestamp')) {
      // If you want to handle Timestamp properly, you can pass it from MyOrdersPage
      // converted to DateTime into orderData; for now we just skip.
    }

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'pending':
        statusColor = Colors.orange.shade600;
        break;
      case 'completed':
      case 'shipped':
      case 'delivered':
        statusColor = Colors.green.shade700;
        break;
      case 'cancelled':
        statusColor = Colors.red.shade600;
        break;
      default:
        statusColor = Colors.blueGrey.shade600;
    }

    return Scaffold(
      backgroundColor: tkoCream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.4,
        centerTitle: true,
        title: Text(
          orderNumber.isNotEmpty ? orderNumber : 'Order Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: tkoBrown,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          // HEADER CARD
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black.withOpacity(.04)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order status',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black.withOpacity(.7),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          status[0].toUpperCase() + status.substring(1),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Placed on',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black.withOpacity(.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateText,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ITEMS LIST
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: items.length + 1, // +1 for summary at end
              separatorBuilder: (_, index) =>
              index == items.length - 1 ? const SizedBox(height: 14) : const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index == items.length) {
                  // SUMMARY CARD
                  return _OrderSummaryCard(
                    subtotal: subtotal.toDouble(),
                    tax: tax.toDouble(),
                    total: total.toDouble(),
                  );
                }

                final raw = items[index];
                if (raw is! Map) {
                  return const SizedBox.shrink();
                }
                final data = Map<String, dynamic>.from(raw);
                final name = (data['name'] ?? '').toString();
                final price = (data['price'] ?? 0) as num;
                final qty = (data['qty'] ?? 1) as int;
                final imageUrl = (data['imageUrl'] ?? '').toString();
                final category = (data['category'] ?? '').toString();

                final lineTotal = price.toDouble() * qty;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.black.withOpacity(.05),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 60,
                            height: 60,
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
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                              if (category.isNotEmpty)
                                Text(
                                  category,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                                ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Qty: $qty',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    '\$${lineTotal.toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
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
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  final double subtotal;
  final double tax;
  final double total;

  const _OrderSummaryCard({
    required this.subtotal,
    required this.tax,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black.withOpacity(.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order summary',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: tkoBrown,
            ),
          ),
          const SizedBox(height: 8),

          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              Text(
                '\$${subtotal.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Tax
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tax',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              Text(
                '\$${tax.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // TOTAL
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: tkoBrown,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
