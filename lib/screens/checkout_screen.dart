import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/cart_item.dart';
import '../services/firestore_service.dart';
import 'home_screen.dart';

class CheckoutScreen extends StatelessWidget {
  final double total;
  final List<CartItem> items;

  CheckoutScreen({required this.total, required this.items});

  void _placeOrder(BuildContext context) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    await FirestoreService().placeOrder(userId, items, total);
    await FirestoreService().clearCart(userId);
    Fluttertoast.showToast(msg: 'Order Placed!');
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Checkout')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Total: \$$total'),
            ElevatedButton(onPressed: () => _placeOrder(context), child: Text('Buy Now')),
          ],
        ),
      ),
    );
  }
}