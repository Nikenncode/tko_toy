import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartService {
  CartService._();
  static final CartService instance = CartService._();

  // reference to current user's cart collection
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

  // stream of cart items
  Stream<QuerySnapshot<Map<String, dynamic>>> cartStream() {
    return _cartRef().snapshots();
  }

  // add item (or increase qty if already exists)
  Future<void> addToCart({
    required String productId,
    required String name,
    required num price,
    String imageUrl = '',
    String category = '',
    int qty = 1,
  }) async {
    final ref = _cartRef();

    // try to find existing cart row by productId
    final existing =
    await ref.where('productId', isEqualTo: productId).limit(1).get();

    if (existing.docs.isNotEmpty) {
      final doc = existing.docs.first;
      final currentQty = (doc.data()['qty'] ?? 1) as int;
      await doc.reference.update({
        'qty': currentQty + qty,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.add({
        'productId': productId,
        'name': name,
        'price': price,
        'qty': qty,
        'imageUrl': imageUrl,
        'category': category,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // optional: update quantity directly
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

  // remove one cart row
  Future<void> removeFromCart(String cartDocId) async {
    await _cartRef().doc(cartDocId).delete();
  }

  // 🔥 clear entire cart (USED BY OrderSummaryPage)
  Future<void> clearCart() async {
    final ref = _cartRef();
    final snap = await ref.get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }
}
