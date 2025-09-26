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
  String _address = '';
  String _selectedPayment = 'Cash on Delivery';

  double get total {
    double sum = 0.0;
    for (var item in widget.items) {
      final cake = widget.cakesMap[item.cakeId];
      if (cake != null) sum += cake.price * item.quantity;
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
                    Expanded(flex: 2, child: _deliveryAndPaymentSection()),
                    const SizedBox(width: 24),
                    Expanded(flex: 3, child: _orderSummarySection()),
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Information',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Delivery Address',
                hintText: 'Enter your full address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              maxLines: 3,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Enter delivery address' : null,
              onSaved: (value) => _address = value!.trim(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Options',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Column(
              children: ['Cash on Delivery', 'UPI', 'Card'].map((method) {
                return RadioListTile<String>(
                  value: method,
                  groupValue: _selectedPayment,
                  title: Text(method, style: const TextStyle(fontSize: 16)),
                  activeColor: Colors.pinkAccent,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedPayment = value);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderSummarySection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...widget.items.map((item) {
              final cake = widget.cakesMap[item.cakeId];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: cake?.imageUrl != null
                          ? Image.network(
                              cake!.imageUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: Icon(Icons.broken_image,
                                      color: Colors.grey, size: 60),
                                );
                              },
                            )
                          : const SizedBox(
                              width: 60,
                              height: 60,
                              child: Icon(Icons.cake, size: 60, color: Colors.pink),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cake?.name ?? 'Unknown Cake',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text('Quantity: ${item.quantity}',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Text(
                      '₹${(cake?.price ?? 0) * item.quantity}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
            const Divider(thickness: 1.2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('₹${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.items.isEmpty ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.pinkAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                child: const Text(
                  'Place Order',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
