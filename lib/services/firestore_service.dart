// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cake.dart';
import '../models/cart_item.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------- Cakes ----------
  Future<List<Cake>> getCakes() async {
    QuerySnapshot snapshot = await _db.collection('cakes').get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Cake.fromMap(data, doc.id);
    }).toList();
  }

  // New method for price range
  Future<List<Cake>> getCakesByPrice(double minPrice, double maxPrice) async {
    QuerySnapshot snapshot = await _db
        .collection('cakes')
        .where('price', isGreaterThanOrEqualTo: minPrice)
        .where('price', isLessThanOrEqualTo: maxPrice)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Cake.fromMap(data, doc.id);
    }).toList();
  }

  // ---------- Cart ----------
  Future<void> addToCart(String userId, String cakeId, int quantity) async {
    DocumentReference cartRef =
        _db.collection('users').doc(userId).collection('carts').doc(cakeId);
    await cartRef.set({'cakeId': cakeId, 'quantity': quantity});
  }

  Future<List<CartItem>> getCart(String userId) async {
    QuerySnapshot snapshot =
        await _db.collection('users').doc(userId).collection('carts').get();
    return snapshot.docs
        .map((doc) => CartItem(cakeId: doc.id, quantity: doc['quantity']))
        .toList();
  }

  Future<void> removeFromCart(String userId, String cakeId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('carts')
        .doc(cakeId)
        .delete();
  }

  Future<void> clearCart(String userId) async {
    QuerySnapshot snapshot =
        await _db.collection('users').doc(userId).collection('carts').get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> placeOrder(String userId, List<CartItem> items, double total) async {
    List<Map<String, dynamic>> orderItems = items.map((item) => item.toMap()).toList();
    await _db.collection('users').doc(userId).collection('orders').add({
      'items': orderItems,
      'total': total,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ---------- Wishlist (Favorites) ----------
  // Helper to get wishlist collection ref for a user
  CollectionReference<Map<String, dynamic>> _userWishlistRef(String userId) {
    return _db.collection('users').doc(userId).collection('wishlist').withConverter<Map<String, dynamic>>(
      fromFirestore: (snap, _) => snap.data() ?? <String, dynamic>{},
      toFirestore: (data, _) => data,
    );
  }

  /// Add a cake to user's wishlist (stores cake data under doc id == cake.id)
  Future<void> addToWishlist(String userId, Cake cake) async {
    final favRef = _db.collection('users').doc(userId).collection('wishlist').doc(cake.id);
    final data = Map<String, dynamic>.from(cake.toMap());
    // store id & isFavorite flag to make reading easier
    data['id'] = cake.id;
    data['isFavorite'] = true;
    await favRef.set(data);
  }

  /// Remove a cake from user's wishlist
  Future<void> removeFromWishlist(String userId, String cakeId) async {
    final favRef = _db.collection('users').doc(userId).collection('wishlist').doc(cakeId);
    await favRef.delete();
  }

  /// Check if a cake is present in user's wishlist
  Future<bool> isCakeInWishlist(String userId, String cakeId) async {
    final doc = await _db.collection('users').doc(userId).collection('wishlist').doc(cakeId).get();
    return doc.exists;
  }

  /// Toggle favorite (keeps for backward compatibility; uses add/remove internally)
  Future<void> toggleFavorite(String userId, Cake cake) async {
    final favRef = _db.collection('users').doc(userId).collection('wishlist').doc(cake.id);
    final doc = await favRef.get();

    if (doc.exists) {
      await favRef.delete();
    } else {
      final data = Map<String, dynamic>.from(cake.toMap());
      data['id'] = cake.id;
      data['isFavorite'] = true;
      await favRef.set(data);
    }
  }

  /// Get all wishlist cakes for a user
  Future<List<Cake>> getWishlist(String userId) async {
    QuerySnapshot snapshot = await _db.collection('users').doc(userId).collection('wishlist').get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Cake.fromMap(data, doc.id)..isFavorite = true;
    }).toList();
  }
}
