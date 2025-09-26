import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/cake.dart';
import '../models/cart_item.dart';
import '../services/firestore_service.dart';
import 'checkout_screen.dart';

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
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/auth');
        }
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _calculateTotal() {
    _total = 0.0;
    for (var item in _cartItems) {
      final cake = _cakesMap[item.cakeId];
      if (cake != null) {
        _total += cake.price * item.quantity;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
              ? const Center(child: Text('Your cart is empty'))
              : ListView.builder(
                  itemCount: _cartItems.length,
                  itemBuilder: (_, index) {
                    final item = _cartItems[index];
                    final cake = _cakesMap[item.cakeId];
                    return ListTile(
                      title: Text(cake?.name ?? 'Unknown Cake'),
                      subtitle: Text(
                          'Qty: ${item.quantity} | Price: \$${cake?.price.toStringAsFixed(2) ?? '0.00'}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) return;
                          try {
                            await FirestoreService().removeFromCart(user.uid, item.cakeId);
                            Fluttertoast.showToast(msg: 'Item removed from cart');
                            _loadCart();
                          } catch (e) {
                            Fluttertoast.showToast(msg: 'Error removing item: $e');
                          }
                        },
                      ),
                    );
                  },
                ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total: \$${_total.toStringAsFixed(2)}'),
            ElevatedButton(
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