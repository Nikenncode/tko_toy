import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'home_page.dart';

class ProductDetailsPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _SupplyDetailsPageState();
}

class _SupplyDetailsPageState extends State<ProductDetailsPage> {
  int _selectedImageIndex = 0;

  List<String> get _images {
    final raw = widget.product['images'];
    if (raw is List) {
      return raw.whereType<String>().toList();
    }
    return [];
  }

  List<dynamic> get _variants {
    final raw = widget.product['variants'];
    if (raw is List) return raw;
    return [];
  }

  num? get _price {
    for (final v in _variants) {
      if (v is Map<String, dynamic>) {
        final p = v['price'];
        if (p is num) return p;
        if (p is String && p.trim().isNotEmpty) {
          final parsed = num.tryParse(p.trim());
          if (parsed != null) return parsed;
        }
      }
    }
    return null;
  }

  int get _totalInventory {
    int total = 0;
    for (final v in _variants) {
      if (v is Map<String, dynamic>) {
        final inv = v['inventory'];
        if (inv is num) total += inv.toInt();
        if (inv is String) {
          final parsed = int.tryParse(inv);
          if (parsed != null) total += parsed;
        }
      }
    }
    return total;
  }

  String get _plainDescription {
    final raw = (widget.product['description'] ?? '').toString();
    return raw.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  bool _validImage(String? url) {
    if (url == null) return false;
    if (!url.startsWith("http")) return false;
    return true;
  }

  Widget _noImageWidget() {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported,
                size: 50, color: Colors.grey.shade500),
            const SizedBox(height: 6),
            Text("No image",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _thumbnailFallback() {
    return Container(
      color: Colors.grey.shade300,
      child: Icon(Icons.broken_image,
          size: 26, color: Colors.grey.shade600),
    );
  }

  void _shareProductLink() {
    final title = widget.product['title']?.toString() ?? "";
    final url = widget.product['productUrl']?.toString() ?? "";
    final price = _price != null ? "\$${_price!.toStringAsFixed(2)}" : "";

    if (url.isEmpty) {
      Share.share("$title\nPrice: $price");
      return;
    }

    final text = "$title\nPrice: $price\n\n$url";
    Share.share(text);
  }


  @override
  Widget build(BuildContext context) {
    final images = _images;
    final price = _price;
    final title = (widget.product['title'] ?? '').toString();
    final vendor = (widget.product['vendor'] ?? '').toString();
    final category = (widget.product['category'] ?? '').toString();

    final hasImages = images.isNotEmpty;
    final mainImg = hasImages ? images[_selectedImageIndex] : null;

    final totalInventory = _totalInventory;
    final inStock = totalInventory > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0.4,
        backgroundColor: Colors.white,
        title: Text(
          widget.product["parentTab"] ?? "Product",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded, size: 22, color: Colors.black),
            onPressed: _shareProductLink,
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: MediaQuery.of(context).size.width * 0.85,
                width: double.infinity,
                color: Colors.white,
                child: _validImage(mainImg)
                    ? Image.network(
                  mainImg!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => _noImageWidget(),
                )
                    : _noImageWidget(),
              ),
            ),

            const SizedBox(height: 10),

            if (images.length > 1)
              SizedBox(
                height: 85,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final url = images[i];
                    final isValid = _validImage(url);

                    return GestureDetector(
                      onTap: () => setState(() => _selectedImageIndex = i),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: i == _selectedImageIndex
                                ? Colors.black
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey.shade200,
                            child: isValid
                                ? Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _thumbnailFallback(),
                            )
                                : _thumbnailFallback(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                "$vendor • $category",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                softWrap: true,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (price != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Price:",
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        Text("\$${price.toStringAsFixed(2)} CAD",
                            style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Stock:",
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      Text(
                        inStock
                            ? "In Stock ($totalInventory)"
                            : "Out of Stock",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                          inStock ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            //Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("$title added to cart")),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text("Add to Cart",
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text("Buy Now",
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            //Description
            Text("Description",
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              _plainDescription.isNotEmpty
                  ? _plainDescription
                  : "No description available.",
              style: GoogleFonts.poppins(fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
      bottomNavigationBar: TkoBottomNav(
        index: -1,
        onChanged: (newIndex) {
          switch (newIndex) {
            case 0:
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
                    (route) => false,
              );
              break;

            case 1:
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomePage(initialTab: 1)),
                    (route) => false,
              );
              break;

            case 3:
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomePage(initialTab: 3)),
                    (route) => false,
              );
              break;
          }
        },
      ),
    );
  }
}
