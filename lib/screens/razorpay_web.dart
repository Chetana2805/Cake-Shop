// lib/screens/razorpay_web.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

class RazorpayWeb {
  final int amountInPaise;

  RazorpayWeb({required this.amountInPaise});

  /// Opens Razorpay checkout in new browser tab (Web/localhost)
  void openPayment() {
    if (!kIsWeb) return; // Only for web

    final options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag', // Replace with your key
      'amount': amountInPaise,
      'currency': 'INR',
      'name': 'Cake Shop',
      'description': 'Cake order payment',
      'prefill': {
        'name': 'Test User',
        'email': 'test@example.com',
        'contact': '9999999999',
      },
      'theme': {'color': '#F37254'},
    };

    final optionsStr = html.window.btoa(jsonEncode(options));

    // Open Razorpay checkout in new tab
    html.window.open(
      'https://checkout.razorpay.com/v1/checkout.js?options=$optionsStr',
      '_blank',
    );
  }
}
