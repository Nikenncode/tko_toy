import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';

import 'home_page.dart';
import 'cart_service.dart';
import 'cart_page.dart';

class ProductDetailsPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int _selectedImageIndex = 0;

  // ---- loyalty / discounts ----
  double? _discountPct;      // e.g. 8% for toys
  double? _earnMultiplier;   // e.g. 1.5x pts / $1
  bool _loadingMeta = true;

  @override
  void initState() {
    super.initState();
    _loadLoyaltyMeta();
  }

  // ---------- helpers for product fields ----------

  List<String> get _images {
    final raw = widget.product['images'];
    if (raw is List) return raw.whereType<String>().toList();
    return [];
  }

  List<dynamic> get _variants {
    final raw = widget.product['variants'];
    if (raw is List) return raw;
    return [];
  }

  num? get _price {
    for (final v in _variants) {
      if (v is Map<String, dynamic> && v['price'] != null) {
        if (v['price'] is num) return v['price'];
        if (v['price'] is String) {
          return num.tryParse(v['price']);
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
        if (inv is String) total += int.tryParse(inv) ?? 0;
      }
    }
    return total;
  }

  String get _plainDescription {
    final raw = widget.product['description']?.toString() ?? "";
    return raw.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  // figure out category key for discount map
  String _discountCategoryKey(Map<String, dynamic> p) {
    final parentTab = (p['parentTab'] ?? '').toString().toLowerCase();
    final cat = (p['category'] ?? '').toString().toLowerCase();
    final text = '$parentTab $cat';

    if (text.contains('sealed')) return 'sealed';
    if (text.contains('single')) return 'singles';
    if (text.contains('supply')) return 'supplies';
    if (text.contains('accessor')) return 'supplies';
    return 'toys'; // default bucket
  }

  // nice label for UI
  String _categoryLabel(String key) {
    switch (key) {
      case 'sealed':
        return 'sealed products';
      case 'singles':
        return 'singles';
      case 'supplies':
        return 'supplies & accessories';
      case 'toys':
      default:
        return 'toys';
    }
  }

  // ---------- load tier + discount / earnX from Firestore ----------

  Future<void> _loadLoyaltyMeta() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userTier =
      (userDoc.data()?['tier'] ?? 'Featherweight').toString();

      final settingsDoc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('general')
          .get();

      final settings = settingsDoc.data() ?? {};

      // earnMultipliers: {Featherweight: 1, Heavyweight: 1.5, ...}
      final earnMap =
      Map<String, dynamic>.from(settings['earnMultipliers'] ?? {});
      double earnX = 1.0;
      final rawEarn = earnMap[userTier];
      if (rawEarn is num) earnX = rawEarn.toDouble();

      // discounts: support both structures
      // 1) settings.general.discounts.{Tier}.{category}
      // 2) settings.general.{Tier}.{category}   (your screenshot)
      Map<String, dynamic> tierDisc = {};

      final discountsRoot = settings['discounts'];
      if (discountsRoot is Map) {
        final map = Map<String, dynamic>.from(discountsRoot);
        final t = map[userTier];
        if (t is Map) {
          tierDisc = Map<String, dynamic>.from(t);
        }
      }

      if (tierDisc.isEmpty) {
        final t = settings[userTier];
        if (t is Map) {
          tierDisc = Map<String, dynamic>.from(t);
        }
      }

      final catKey = _discountCategoryKey(widget.product);
      double discPct = 0.0;
      final rawDisc = tierDisc[catKey];
      if (rawDisc is num) discPct = rawDisc.toDouble();

      if (!mounted) return;
      setState(() {
        _earnMultiplier = earnX;
        _discountPct = discPct;
      });
    } catch (_) {
      // fail silently – product page should still work
    } finally {
      if (mounted) {
        setState(() => _loadingMeta = false);
      }
    }
  }

  // ---------------- UTILITIES ----------------

  bool _validImage(String? url) => url != null && url.startsWith("http");

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

  void _shareProduct() {
    final title = widget.product['title'] ?? "";
    final url = widget.product['productUrl'] ?? "";
    final price = _price != null ? "\$${_price!.toStringAsFixed(2)}" : "";

    if (url.isEmpty) {
      Share.share("$title\nPrice: $price");
    } else {
      Share.share("$title\nPrice: $price\n$url");
    }
  }

  Future<void> _addToCart() async {
    final price = _price;
    if (price == null) return;

    final title = widget.product['title']?.toString() ?? "";

    // 1) image
    final images = _images;
    final imageUrl = images.isNotEmpty ? images.first : "";

    // 2) human-readable category for UI
    final displayCategory =
        widget.product['category']?.toString() ??
            widget.product['parentTab']?.toString() ??
            '';

    // 3) discount bucket: singles / sealed / supplies / toys / other
    String bucket =
    (widget.product['discountBucket'] ?? '').toString().toLowerCase();

    final parentTab =
        widget.product['parentTab']?.toString().toLowerCase() ?? '';
    final rawCategory =
        widget.product['category']?.toString().toLowerCase() ?? '';

    final combined = '$parentTab $rawCategory';

    if (bucket.isEmpty) {
      if (combined.contains('single')) {
        bucket = 'singles';
      } else if (combined.contains('sealed')) {
        bucket = 'sealed';
      } else if (combined.contains('supply')) {
        bucket = 'supplies';
      } else if (combined.contains('toy')) {
        bucket = 'toys';
      }
    }
    if (bucket.isEmpty) bucket = 'other';

    // 4) productId
    final productId = widget.product['docId']?.toString() ??
        widget.product['id']?.toString() ??
        widget.product['title']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();

    try {
      await CartService.instance.addToCart(
        productId: productId,
        name: title,
        price: price,
        imageUrl: imageUrl,
        category: displayCategory,   // what you show in UI
        discountBucket: bucket,      // what we use for % off
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Added to cart ✓")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }


  // -----------------------------------------------

  @override
  Widget build(BuildContext context) {
    final images = _images;
    final mainImg = images.isNotEmpty ? images[_selectedImageIndex] : null;

    final title = widget.product['title']?.toString() ?? "";
    final vendor = widget.product['vendor']?.toString() ?? "";
    final category = widget.product['category']?.toString() ??
        widget.product['parentTab']?.toString() ??
        "";
    final totalStock = _totalInventory;
    final inStock = totalStock > 0;
    final price = _price;
    final basePrice = price?.toDouble();

    final catKey = _discountCategoryKey(widget.product);
    final catLabel = _categoryLabel(catKey);
    final disc = (_discountPct ?? 0).clamp(0, 100);
    final hasDiscount = basePrice != null && disc > 0;

    final discountedPrice =
    hasDiscount ? basePrice! * (1 - disc / 100.0) : basePrice;

    // approximate points earned on ONE unit
    int? ptsEarn;
    if (discountedPrice != null && _earnMultiplier != null) {
      ptsEarn = (discountedPrice * _earnMultiplier!).floor();
    }

    return Scaffold(
      backgroundColor: Colors.white,

      // ---------------- APPBAR ----------------
      appBar: AppBar(
        title: Text(
          widget.product["parentTab"] ?? "Product",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        elevation: 0.4,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: _shareProduct,
          ),
        ],
      ),

      // ---------------- BODY ----------------
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MAIN IMAGE
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

            // THUMBNAILS
            if (images.length > 1)
              SizedBox(
                height: 85,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final url = images[i];

                    return GestureDetector(
                      onTap: () => setState(() => _selectedImageIndex = i),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (i == _selectedImageIndex)
                                ? Colors.black
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            height: 70,
                            width: 70,
                            child: _validImage(url)
                                ? Image.network(
                              url,
                              fit: BoxFit.cover,
                            )
                                : Container(
                              color: Colors.grey.shade300,
                              child: Icon(Icons.broken_image,
                                  color: Colors.grey.shade700),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 18),

            // TITLE
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // VENDOR + CATEGORY
            Text(
              "$vendor • $category",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 20),

            // PRICE BOX (+ discount & points info)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (basePrice != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Price:",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (hasDiscount) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "\$${basePrice.toStringAsFixed(2)} CAD",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "\$${discountedPrice!.toStringAsFixed(2)} CAD",
                                style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Text(
                            "\$${basePrice.toStringAsFixed(2)} CAD",
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (hasDiscount)
                      Text(
                        "You save ${disc.toStringAsFixed(0)}% on $catLabel.",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (ptsEarn != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        "Earn ~$ptsEarn pts on this item.",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black.withOpacity(.75),
                        ),
                      ),
                    ],
                    if (_loadingMeta)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          "Loading tier benefits…",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Stock:",
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(
                        inStock ? "In Stock ($totalStock)" : "Out of Stock",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: inStock ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ---------------- BUTTONS ----------------
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _addToCart();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Add to Cart",
                      style:
                      GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await _addToCart();
                      if (!mounted) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CartPage(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Buy Now",
                      style:
                      GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ---------------- DESCRIPTION ----------------
            Text(
              "Description",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _plainDescription.isNotEmpty
                  ? _plainDescription
                  : "No description available.",
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),

      // ---------------- BOTTOM NAV ----------------
      bottomNavigationBar: TkoBottomNav(
        index: -1,
        onChanged: (newIndex) {
          if (newIndex == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          }
          if (newIndex == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const HomePage(initialTab: 1)),
            );
          }
          if (newIndex == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const HomePage(initialTab: 3)),
            );
          }
        },
      ),
    );
  }
}
