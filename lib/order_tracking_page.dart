// lib/order_tracking_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_page.dart';

class OrderTrackingPage extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const OrderTrackingPage({
    super.key,
    required this.orderId,
    required this.orderData,
  });

  // ---- SAFE helpers ----

  List<Map<String, dynamic>> get _items {
    final raw = orderData['items'];
    final List<Map<String, dynamic>> list = [];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          list.add(e);
        } else if (e is Map) {
          list.add(Map<String, dynamic>.from(e));
        }
      }
    }
    return list;
  }

  double get _total {
    final v = orderData['total'];
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  String get _status => (orderData['status'] ?? 'pending').toString();

  String get _addressLine {
    final raw = orderData['address'];
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      return (m['fullAddress'] ?? m['address'] ?? '').toString();
    }
    return '';
  }

  int get _currentStepIdx {
    final s = _status.toLowerCase();
    const order = [
      'pending',
      'confirmed',
      'processing',
      'shipped',
      'out_for_delivery',
      'delivered',
    ];
    final idx = order.indexOf(s);
    return idx == -1 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final total = _total;
    final statusIndex = _currentStepIdx;

    const steps = [
      'PENDING',
      'CONFIRMED',
      'PROCESSING',
      'SHIPPED',
      'OUT FOR DELIVERY',
      'DELIVERED',
    ];

    return Scaffold(
      backgroundColor: tkoCream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: tkoBrown),
        title: Text(
          'Order Tracking',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: tkoBrown,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #$orderId',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: tkoBrown,
                    ),
                  ),
                  if (_addressLine.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _addressLine,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.black.withOpacity(.65),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  // timeline
                  Column(
                    children: List.generate(steps.length, (i) {
                      final active = i <= statusIndex;
                      return _StatusRow(
                        label: steps[i],
                        isActive: active,
                        isLast: i == steps.length - 1,
                      );
                    }),
                  )
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ----- Items -----
            Text(
              'Order Items',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: tkoBrown,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x16000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  for (final item in items) ...[
                    _ItemRow(item: item),
                    if (item != items.last) const Divider(height: 16),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 18),

            Text(
              'Total Paid: \$${total.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: tkoBrown,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isLast;

  const _StatusRow({
    required this.label,
    required this.isActive,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? tkoBrown : Colors.black38;

    return SizedBox(
      height: 40,
      child: Row(
        children: [
          // left timeline column
          Column(
            children: [
              // circle
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? color : Colors.transparent,
                  border: Border.all(color: color, width: 2),
                ),
                child: isActive
                    ? const Icon(Icons.check, size: 10, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.only(top: 2),
                    color: Colors.black.withOpacity(.15),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final title = (item['name'] ?? '').toString();
    final qty   = (item['qty'] ?? 1) as int;
    final price = (item['price'] ?? 0) as num;
    final imageUrl = (item['imageUrl'] ?? '').toString();

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 52,
            height: 52,
            color: Colors.grey.shade200,
            child: imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.image_not_supported,
                      color: Colors.grey.shade400),
            )
                : Icon(Icons.image_outlined, color: Colors.grey.shade400),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Qty: $qty',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.black.withOpacity(.6),
                ),
              ),
            ],
          ),
        ),
        Text(
          '\$${price.toStringAsFixed(2)}',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
