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
      'fullName': name ?? '',
      'photoUrl': photoUrl ?? '',
      'address': '',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUser(String uid) async {
    DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
    return doc.data() as Map<String, dynamic>?;
  }

  Future<void> updateUserName(String uid, String newName) async {
    await _db.collection('users').doc(uid).update({'fullName': newName});
  }

  Future<void> updateUserPhoto(String uid, String photoUrl) async {
    await _db.collection('users').doc(uid).update({
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUserAddress(String uid, String address) async {
    await _db.collection('users').doc(uid).update({
      'address': address,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String?> getUserAddress(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data() as Map<String, dynamic>?;
    return data?['address'] as String?;
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
  // Fetch orders with cake details
  Future<List<Map<String, dynamic>>> getOrdersWithCakes(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('orders')
        .orderBy('timestamp', descending: true)
        .get();

    return await Future.wait(snapshot.docs.map((doc) async {
      final data = doc.data() as Map<String, dynamic>;
      final items = data['items'] as List;

      List<Map<String, dynamic>> detailedItems = [];
      for (var item in items) {
        final cakeDoc = await _db.collection('cakes').doc(item['cakeId']).get();
        if (cakeDoc.exists) {
          final imageUrl = cakeDoc['imageUrl'] ?? 'assets/images/cake-1.webp';
          detailedItems.add({
            'cakeId': cakeDoc.id,
            'name': cakeDoc['name'] ?? 'Unknown Cake',
            'imageUrl': imageUrl,
            'quantity': item['quantity'] ?? 1,
            'price': cakeDoc['price'] ?? 0.0,
          });
        }
      }

      return {
        'id': doc.id, // Include order ID for cancellation
        'total': data['total'] ?? 0.0,
        'timestamp': data['timestamp'],
        'items': detailedItems,
      };
    }).toList());
  }
  
  // Place Order
  Future<void> placeOrder(String userId, List<CartItem> items, double total) async {
    final orderRef = _db.collection('users').doc(userId).collection('orders').doc();

    final orderData = {
      'total': total,
      'timestamp': FieldValue.serverTimestamp(),
      'items': items.map((item) => {'cakeId': item.cakeId, 'quantity': item.quantity}).toList(),
    };

    await orderRef.set(orderData);
  }

   //Cancel Order
  Future<void> cancelOrder(String userId, String orderId) async {
    final orderRef = _db.collection('users').doc(userId).collection('orders').doc(orderId);
    final orderDoc = await orderRef.get();
    if (!orderDoc.exists) {
      throw Exception('Order not found');
    }

    final data = orderDoc.data() as Map<String, dynamic>;
    final timestamp = data['timestamp'] as Timestamp?;
    if (timestamp == null) {
      throw Exception('Order timestamp not available');
    }

    final now = Timestamp.now();
    final difference = now.toDate().difference(timestamp.toDate()).inMinutes;
    if (difference <= 5) {
      await orderRef.delete();
    } else {
      throw Exception('Cannot cancel order after 5 minutes');
    }
  }
  
  // fetch orders without cake details
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
        'id': doc.id,
        'total': data['total'],
        'timestamp': data['timestamp'],
        'items': List<Map<String, dynamic>>.from(data['items'] ?? []),
      };
    }).toList();
  }
}