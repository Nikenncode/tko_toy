// lib/cart_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartService {
  CartService._();
  static final CartService instance = CartService._();

  CollectionReference<Map<String, dynamic>> _cartRef() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> cartStream() {
    return _cartRef().snapshots();
  }

  String _inferBucketFromCategory(dynamic raw) {
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

  Future<void> addToCart({
    required String productId,
    required String name,
    required num price,
    String imageUrl = '',
    String category = '',
    String? discountBucket,
    int qty = 1,
  }) async {
    final ref = _cartRef();

    String bucket =
    (discountBucket?.trim().isNotEmpty == true)
        ? discountBucket!.trim()
        : _inferBucketFromCategory(category);

    if (bucket.isEmpty) bucket = 'other';

    final existing =
    await ref.where('productId', isEqualTo: productId).limit(1).get();

    if (existing.docs.isNotEmpty) {
      final doc = existing.docs.first;
      final data = doc.data();
      final currentQty = (data['qty'] ?? 1) as int;

      final Map<String, dynamic> updateData = {
        'qty': currentQty + qty,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final existingBucket = (data['discountBucket'] ?? '').toString();
      if (existingBucket.isEmpty && bucket.isNotEmpty) {
        updateData['discountBucket'] = bucket;
      }

      await doc.reference.update(updateData);
    } else {
      await ref.add({
        'productId': productId,
        'name': name,
        'price': price,
        'qty': qty,
        'imageUrl': imageUrl,
        'category': category,
        'discountBucket': bucket,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> decreaseQty({required String productId}) async {
    final ref = _cartRef();

    final existing =
    await ref.where('productId', isEqualTo: productId).limit(1).get();

    if (existing.docs.isEmpty) return;

    final doc = existing.docs.first;
    final currentQty = (doc.data()['qty'] ?? 1) as int;

    if (currentQty > 1) {
      await doc.reference.update({
        'qty': currentQty - 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await doc.reference.delete();
    }
  }

  Future<double> getCartTotal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    final snap = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("cart")
        .get();

    if (snap.docs.isEmpty) return 0;

    double subtotal = 0;

    for (final doc in snap.docs) {
      final data = doc.data();
      final price = (data["price"] ?? 0).toDouble();
      final qty = (data["qty"] ?? 1) as int;

      subtotal += price * qty;
    }

    return subtotal;
  }

  Future<void> updateQty(String cartDocId, int qty) async {
    if (qty <= 0) {
      await removeFromCart(cartDocId);
    } else {
      await _cartRef().doc(cartDocId).update({
        'qty': qty,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> removeFromCart(String cartDocId) async {
    await _cartRef().doc(cartDocId).delete();
  }

  Future<void> clearCart() async {
    final ref = _cartRef();
    final snap = await ref.get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }
}