// lib/screens/razorpay_web_checkout.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class RazorpayWebCheckout extends StatefulWidget {
  final int amountInPaise;

  const RazorpayWebCheckout({super.key, required this.amountInPaise});

  @override
  State<RazorpayWebCheckout> createState() => _RazorpayWebCheckoutState();
}

class _RazorpayWebCheckoutState extends State<RazorpayWebCheckout> {
  late InAppWebViewController _webViewController;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // ❌ Should not run on Web
      return Scaffold(
        appBar: AppBar(title: const Text('Payment Unavailable')),
        body: const Center(
          child: Text(
            'Online payment is available only on mobile app.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // ✅ Mobile
    return Scaffold(
      appBar: AppBar(title: const Text('Razorpay Payment')),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri('about:blank')),
        initialData: InAppWebViewInitialData(
          data: """
            <!DOCTYPE html>
            <html>
              <head>
                <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
              </head>
              <body>
                <script>
                  var options = {
                    "key": "rzp_test_1DP5mmOlF5G5ag",
                    "amount": ${widget.amountInPaise},
                    "currency": "INR",
                    "name": "Cake Shop",
                    "description": "Cake order payment",
                    "handler": function(response){
                      window.flutter_inappwebview.callHandler('paymentSuccess', response.razorpay_payment_id);
                    },
                    "prefill": {
                      "name": "Test User",
                      "email": "test@example.com",
                      "contact": "9999999999"
                    },
                    "theme": {"color":"#F37254"}
                  };
                  var rzp = new Razorpay(options);
                  rzp.open();
                </script>
              </body>
            </html>
          """,
        ),
        onWebViewCreated: (controller) {
          _webViewController = controller;
          _webViewController.addJavaScriptHandler(
            handlerName: 'paymentSuccess',
            callback: (args) {
              if (args.isNotEmpty) {
                Navigator.pop(context, args[0]); // Return paymentId
              }
            },
          );
        },
      ),
    );
  }
}
