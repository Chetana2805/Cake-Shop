// lib/screens/mock_payment_pages.dart

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// ===============================
/// 1. MOCK UPI PAYMENT PAGE
/// ===============================
class MockUpiPaymentPage extends StatelessWidget {
  final double amount;

  const MockUpiPaymentPage({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    final mockUpiId = 'cakeshop@upi'; // Demo UPI ID
    final upiUrl = 'upi://pay?pa=$mockUpiId&pn=CakeShop&am=$amount&cu=INR';

    return Scaffold(
      appBar: AppBar(
        title: const Text('UPI Payment'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        return Center(
          child: Card(
            margin: const EdgeInsets.all(24),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: isWide ? 400 : double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Scan QR to Pay',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    // QR Code
                    QrImageView(
                      data: upiUrl,
                      version: QrVersions.auto,
                      size: isWide ? 250 : 200,
                      errorStateBuilder: (context, error) => Container(
                        color: Colors.grey[300],
                        height: isWide ? 250 : 200,
                        width: isWide ? 250 : 200,
                        child: const Center(
                          child: Icon(Icons.error, color: Colors.red, size: 50),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Amount: ₹${amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Simulate payment success
                          Navigator.pop(context, 'upi_payment_id_12345');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'I have Paid',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, null); // Cancel payment
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// ===============================
/// 2. MOCK CARD PAYMENT PAGE
/// ===============================
class MockCardPaymentPage extends StatelessWidget {
  final double amount;

  const MockCardPaymentPage({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Payment'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        return Center(
          child: Card(
            margin: const EdgeInsets.all(24),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: isWide ? 450 : double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Pay ₹${amount.toStringAsFixed(2)}',
                      style:
                          const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    // Card Image
                    Image.asset(
                      'assets/images/credit_card.png',
                      width: isWide ? 180 : 120,
                      height: isWide ? 120 : 80,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.credit_card,
                        size: isWide ? 80 : 60,
                        color: Colors.pinkAccent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Enter your card details',
                      style: TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Card Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.credit_card),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Expiry Date (MM/YY)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.datetime,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'CVV',
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Simulate payment success
                          Navigator.pop(context, 'mock_card_payment_id_12345');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Pay Now',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, null); // Cancel payment
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
