// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cake.dart';
import '../models/cart_item.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

// ------------------- Cakes -------------------
  Future<List<Cake>> getCakes() async {
    QuerySnapshot snapshot = await _db.collection('cakes').get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Cake.fromMap(data, doc.id);
    }).toList();
  }

  Future<void> addCake(Cake cake) async {
    await _db.collection('cakes').doc(cake.id).set({
      'name': cake.name,
      'description': cake.description,
      'price': cake.price,
      'imageUrl': cake.imageUrl,
      'ingredients': cake.ingredients, 
    });
  }

  Future<void> updateCake(Cake cake) async {
    await _db.collection('cakes').doc(cake.id).update({
      'name': cake.name,
      'description': cake.description,
      'price': cake.price,
      'imageUrl': cake.imageUrl,
      'ingredients': cake.ingredients, 
    });
  }

  // ------------------- Cart -------------------
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

  Future<void> updateCartQuantity(
      String userId, String cakeId, int quantity) async {
    final cartRef = _db
        .collection('users')
        .doc(userId)
        .collection('carts')
        .doc(cakeId);

    await cartRef.update({
      'quantity': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ------------------- Orders -------------------
  Future<void> placeOrder(
      String userId, List<CartItem> items, double total) async {
    List<Map<String, dynamic>> orderItems =
        items.map((item) => item.toMap()).toList();
    await _db.collection('users').doc(userId).collection('orders').add({
      'items': orderItems,
      'total': total,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
