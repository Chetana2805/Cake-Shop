import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cake.dart';
import '../models/cart_item.dart';
import '../services/firestore_service.dart';
import 'home_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> items;
  final Map<String, Cake> cakesMap;

  const CheckoutScreen({
    super.key,
    required this.items,
    required this.cakesMap,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  // Delivery Info (name, phone, address)
  String _address = '';

  // Payment method
  String _selectedPayment = 'Cash on Delivery';

  double get total {
    double sum = 0.0;
    for (var item in widget.items) {
      final cake = widget.cakesMap[item.cakeId];
      if (cake != null) {
        sum += cake.price * item.quantity;
      }
    }
    return sum;
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      Fluttertoast.showToast(msg: 'Please login to place order');
      return;
    }

    await FirestoreService().placeOrder(
      userId,
      widget.items,
      total,
      deliveryAddress: _address,
      paymentMethod: _selectedPayment,
    );

    await FirestoreService().clearCart(userId);
    Fluttertoast.showToast(msg: 'Order Placed Successfully!');
    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: isWeb
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _deliveryAndPaymentSection()),
                    const SizedBox(width: 24),
                    Expanded(child: _orderSummarySection()),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _deliveryAndPaymentSection(),
                    const SizedBox(height: 24),
                    _orderSummarySection(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _deliveryAndPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery Information',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Address
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Delivery Address',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Enter delivery address' : null,
          onSaved: (value) => _address = value!.trim(),
        ),
        const SizedBox(height: 24),

        // Payment
        const Text(
          'Payment Options',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Column(
          children: ['Cash on Delivery', 'UPI', 'Card'].map((method) {
            return RadioListTile<String>(
              value: method,
              groupValue: _selectedPayment,
              title: Text(method),
              onChanged: (value) {
                if (value != null) setState(() => _selectedPayment = value);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _orderSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Summary',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            children: widget.items.map((item) {
              final cake = widget.cakesMap[item.cakeId];
              return Column(
                children: [
                  ListTile(
                    leading: cake?.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              cake!.imageUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.cake, size: 50, color: Colors.pink),
                    title: Text(cake?.name ?? 'Unknown Cake'),
                    subtitle: Text(
                        'Quantity: ${item.quantity}\nPrice: ₹${(cake?.price ?? 0) * item.quantity}'),
                  ),
                  const Divider(), // Add space between items
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('₹${total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.items.isEmpty ? null : _placeOrder,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.pinkAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Place Order',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
