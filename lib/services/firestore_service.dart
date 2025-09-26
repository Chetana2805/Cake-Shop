import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cake.dart';
import '../models/cart_item.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ------------------- User -------------------
  Future<void> createUser(String uid, String email, {String? name, String? photoUrl}) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'name': name ?? '',
      'photoUrl': photoUrl ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUser(String uid) async {
    DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
    return doc.data() as Map<String, dynamic>?;
  }

  Future<void> updateUserName(String uid, String name) async {
    await _db.collection('users').doc(uid).update({
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUserPhoto(String uid, String photoUrl) async {
    await _db.collection('users').doc(uid).update({
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ------------------- Cakes -------------------
  Future<List<Cake>> getCakes() async {
    QuerySnapshot snapshot = await _db.collection('cakes').get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Cake.fromMap(data, doc.id);
    }).toList();
  }

  Stream<List<Cake>> getCakesStream() {
    return _db.collection('cakes').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Cake.fromMap(data, doc.id);
      }).toList();
    });
  }

  Future<void> addCake(Cake cake) async {
    await _db.collection('cakes').doc(cake.id).set(cake.toMap());
  }

  Future<void> updateCake(Cake cake) async {
    await _db.collection('cakes').doc(cake.id).update(cake.toMap());
  }

  Future<void> deleteCake(String cakeId) async {
    await _db.collection('cakes').doc(cakeId).delete();
  }

  // ------------------- Cart -------------------
  Future<void> addToCart(String userId, String cakeId, int quantity) async {
    DocumentReference cartRef = _db.collection('users').doc(userId).collection('carts').doc(cakeId);

    DocumentSnapshot cartDoc = await cartRef.get();

    if (cartDoc.exists) {
      // increment quantity
      int existingQty = cartDoc['quantity'];
      await cartRef.update({'quantity': existingQty + quantity});
    } else {
      await cartRef.set({'cakeId': cakeId, 'quantity': quantity});
    }
  }

  Future<List<CartItem>> getCart(String userId) async {
    QuerySnapshot snapshot = await _db.collection('users').doc(userId).collection('carts').get();
    return snapshot.docs.map((doc) => CartItem(cakeId: doc.id, quantity: doc['quantity'])).toList();
  }

  Stream<List<CartItem>> getCartStream(String userId) {
    return _db.collection('users').doc(userId).collection('carts').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => CartItem(cakeId: doc.id, quantity: doc['quantity'])).toList();
    });
  }

  Future<void> removeFromCart(String userId, String cakeId) async {
    await _db.collection('users').doc(userId).collection('carts').doc(cakeId).delete();
  }

  Future<void> clearCart(String userId) async {
    QuerySnapshot snapshot = await _db.collection('users').doc(userId).collection('carts').get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> updateCartQuantity(String userId, String cakeId, int quantity) async {
    final cartRef = _db.collection('users').doc(userId).collection('carts').doc(cakeId);

    await cartRef.update({
      'quantity': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ------------------- Orders -------------------
  Future<void> placeOrder(String userId, List<CartItem> items, double total) async {
    List<Map<String, dynamic>> orderItems = items.map((item) => item.toMap()).toList();
    await _db.collection('users').doc(userId).collection('orders').add({
      'items': orderItems,
      'total': total,
      'status': 'pending', // ✅ added
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

 Future<List<Map<String, dynamic>>> getOrdersWithCakes(String userId) async {
  final snapshot = await _db
      .collection('users')
      .doc(userId)
      .collection('orders')
      .orderBy('timestamp', descending: true)
      .get();

  List<Map<String, dynamic>> orders = [];

  for (var doc in snapshot.docs) {
    final data = doc.data() as Map<String, dynamic>;
    final items = data['items'] as List;

    // fetch cake details for each item
    List<Map<String, dynamic>> detailedItems = [];
    for (var item in items) {
      final cakeDoc = await _db.collection('cakes').doc(item['cakeId']).get();
      if (cakeDoc.exists) {
        detailedItems.add({
          'name': cakeDoc['name'],
          'imageUrl': cakeDoc['imageUrl'],
          'quantity': item['quantity'],
        });
      }
    }

    orders.add({
      'total': data['total'],
      'timestamp': data['timestamp'],
      'items': detailedItems,
    });
  }

  return orders;
}
  Future<List<Map<String, dynamic>>> getOrders(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('orders')
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'total': data['total'],
        'timestamp': data['timestamp'],
        'items': List<Map<String, dynamic>>.from(data['items'] ?? []),
      };
    }).toList();
  } 
}