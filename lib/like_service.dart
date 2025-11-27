import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LikeService {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _likedRef(String uid) {
    return _db.collection("users").doc(uid).collection("liked");
  }

  static Future<void> likeProduct(Map<String, dynamic> product) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final id = product["id"].toString().replaceAll("/", "_");

    await _likedRef(uid).doc(id).set(product);
  }

  static Future<void> unlikeProduct(String id) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    id = id.replaceAll("/", "_");

    await _likedRef(uid).doc(id).delete();
  }

  static Future<bool> isLiked(String id) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    id = id.replaceAll("/", "_");

    final doc = await _likedRef(uid).doc(id).get();
    return doc.exists;
  }

  static Stream<QuerySnapshot> likedItemsStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _likedRef(uid).snapshots();
  }
}
