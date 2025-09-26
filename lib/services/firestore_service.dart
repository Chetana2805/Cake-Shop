// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cake.dart';
import '../models/cart_item.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetch all cakes
  Future<List<Cake>> getCakes() async {
    QuerySnapshot snapshot = await _db.collection('cakes').get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Cake.fromMap(data, doc.id);
    }).toList();
  }

  // Add a cake to user's cart
  Future<void> addToCart(String userId, String cakeId, int quantity) async {
    DocumentReference cartRef =
        _db.collection('users').doc(userId).collection('carts').doc(cakeId);

    // If cake already exists in cart, update quantity
    DocumentSnapshot doc = await cartRef.get();
    if (doc.exists) {
      int currentQuantity = doc['quantity'] ?? 0;
      await cartRef.update({'quantity': currentQuantity + quantity});
    } else {
      await cartRef.set({'cakeId': cakeId, 'quantity': quantity});
    }
  }

  // Get user's cart items
  Future<List<CartItem>> getCart(String userId) async {
    QuerySnapshot snapshot =
        await _db.collection('users').doc(userId).collection('carts').get();
    return snapshot.docs
        .map((doc) => CartItem(cakeId: doc.id, quantity: doc['quantity']))
        .toList();
  }

  // Remove a specific item from cart
  Future<void> removeFromCart(String userId, String cakeId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('carts')
        .doc(cakeId)
        .delete();
  }

  // Clear all cart items
  Future<void> clearCart(String userId) async {
    QuerySnapshot snapshot =
        await _db.collection('users').doc(userId).collection('carts').get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // Place order with delivery address and payment method only
  Future<void> placeOrder(
    String userId,
    List<CartItem> items,
    double total, {
    required String deliveryAddress,
    required String paymentMethod,
  }) async {
    List<Map<String, dynamic>> orderItems = items.map((item) => item.toMap()).toList();

    await _db.collection('users').doc(userId).collection('orders').add({
      'items': orderItems,
      'total': total,
      'deliveryAddress': deliveryAddress,
      'paymentMethod': paymentMethod,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
