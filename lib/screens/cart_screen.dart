import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/cake.dart';
import '../models/cart_item.dart';
import '../services/firestore_service.dart';


class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> _cartItems = [];
  Map<String, Cake> _cakesMap = {};
  double _total = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      setState(() => _isLoading = true);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Fluttertoast.showToast(msg: 'Please log in to view cart');
        if (mounted) Navigator.pushReplacementNamed(context, '/auth');
        return;
      }

      final userId = user.uid;
      _cartItems = await FirestoreService().getCart(userId);
      final cakes = await FirestoreService().getCakes();
      _cakesMap = {for (var cake in cakes) cake.id: cake};
      _calculateTotal();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error loading cart: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _calculateTotal() {
    _total = 0.0;
    for (var item in _cartItems) {
      final cake = _cakesMap[item.cakeId];
      if (cake != null) _total += cake.price * item.quantity;
    }
  }

  Future<void> _updateQuantity(CartItem item, int change) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final newQty = item.quantity + change;
      if (newQty < 1) {
        await FirestoreService().removeFromCart(user.uid, item.cakeId);
      } else {
        await FirestoreService().updateCartQuantity(user.uid, item.cakeId, newQty);
      }
      _loadCart();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error updating quantity: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/placeholder.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
                _cartItems.isEmpty
                    ? const Center(
                        child: Text(
                          'Your cart is empty',
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _cartItems.length,
                        itemBuilder: (_, index) {
                          final item = _cartItems[index];
                          final cake = _cakesMap[item.cakeId];
                          return Card(
                            color: Colors.white.withOpacity(0.8),
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: cake != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.asset(
                                        cake.imageUrl,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(Icons.cake, size: 50),
                              title: Text(cake?.name ?? 'Unknown Cake'),
                              subtitle: Text(
                                  'Price: ₹${cake?.price.toStringAsFixed(2) ?? '0.00'}'),
                              trailing: SizedBox(
                                width: 120,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.pinkAccent),
                                      onPressed: () => _updateQuantity(item, -1),
                                    ),
                                    Text(
                                      '${item.quantity}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.add_circle_outline,
                                          color: Colors.pinkAccent),
                                      onPressed: () => _updateQuantity(item, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade400,
              blurRadius: 8,
              offset: const Offset(0, -2),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total: ₹${_total.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: _cartItems.isEmpty
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CheckoutScreen(items: _cartItems, cakesMap: _cakesMap),
                        ),
                      ),
              child: const Text('Checkout'),
            ),
          ],
        ),
      ),
    );
  }
}
