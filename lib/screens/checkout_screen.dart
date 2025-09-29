// lib/screens/checkout_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cake.dart';
import '../models/cart_item.dart';
import '../services/firestore_service.dart';
import 'home_screen.dart';
import 'mock_payment_pages.dart'; // Mock UPI & Card pages

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> items;
  final Map<String, Cake> cakesMap;

  const CheckoutScreen({super.key, required this.items, required this.cakesMap});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  String _selectedPayment = 'Cash on Delivery';

  double get total {
    double sum = 0;
    for (var item in widget.items) {
      final cake = widget.cakesMap[item.cakeId];
      if (cake != null) sum += cake.price * item.quantity;
    }
    return sum;
  }

  /// Save order to Firestore
  Future<void> _saveOrder(String paymentMethod) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await FirestoreService().placeOrder(
        userId,
        widget.items,
        total,
        deliveryAddress: _addressController.text.trim(),
        paymentMethod: paymentMethod,
      );
      await FirestoreService().clearCart(userId);

      Fluttertoast.showToast(msg: 'Order Placed Successfully!');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error placing order: $e');
    }
  }

  /// Handle Place Order button
  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.items.isEmpty) {
      Fluttertoast.showToast(msg: 'Cart is empty');
      return;
    }

    if (_selectedPayment == 'Cash on Delivery') {
      await _saveOrder('Cash on Delivery');
    } else if (_selectedPayment == 'UPI') {
      final paymentId = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MockUpiPaymentPage(amount: total)),
      );
      if (paymentId != null) {
        await _saveOrder('UPI Payment - $paymentId');
      } else {
        Fluttertoast.showToast(msg: 'Payment Cancelled');
      }
    } else if (_selectedPayment == 'Card') {
      final paymentId = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MockCardPaymentPage(amount: total)),
      );
      if (paymentId != null) {
        await _saveOrder('Card Payment - $paymentId');
      } else {
        Fluttertoast.showToast(msg: 'Payment Cancelled');
      }
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
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

  /// Delivery info and payment options
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
            const Text('Delivery Information',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Delivery Address',
                hintText: 'Street, Area, City, Pincode',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
                prefixIcon: const Icon(Icons.location_on),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter delivery address';
                }
                // Basic street validation: at least 10 chars
                if (value.trim().length < 10) {
                  return 'Enter a valid address';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            const Text('Payment Options',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Column(
              children: [
                RadioListTile(
                  value: 'Cash on Delivery',
                  groupValue: _selectedPayment,
                  title: const Text('Cash on Delivery'),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedPayment = value);
                  },
                ),
                RadioListTile(
                  value: 'UPI',
                  groupValue: _selectedPayment,
                  title: const Text('UPI'),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedPayment = value);
                  },
                ),
                RadioListTile(
                  value: 'Card',
                  groupValue: _selectedPayment,
                  title: const Text('Card'),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedPayment = value);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Order summary section
  Widget _orderSummarySection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order Summary',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...widget.items.map((item) {
              final cake = widget.cakesMap[item.cakeId];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: cake?.imageUrl != null
                          ? Image.network(
                              cake!.imageUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.cake, size: 60, color: Colors.pink),
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
                          Text(cake?.name ?? 'Unknown Cake',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('Quantity: ${item.quantity}',
                              style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Text('₹${(cake?.price ?? 0) * item.quantity}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }).toList(),
            const Divider(thickness: 1.2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('₹${total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                ),
                child: const Text('Place Order',
                    style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
