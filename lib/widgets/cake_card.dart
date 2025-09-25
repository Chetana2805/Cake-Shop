
import 'package:flutter/material.dart';
import '../models/cake.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CakeCard extends StatefulWidget {
  final Cake cake;

  const CakeCard({super.key, required this.cake});

  @override
  _CakeCardState createState() => _CakeCardState();
}

class _CakeCardState extends State<CakeCard> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: widget.cake.imageUrl.isNotEmpty
            ? Image.asset(
                widget.cake.imageUrl,
                width: 50,
                height: 50,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
              )
            : const Icon(Icons.cake),
        title: Text(widget.cake.name.isNotEmpty ? widget.cake.name : 'Unknown Cake'),
        subtitle: Text(widget.cake.description.isNotEmpty ? widget.cake.description : 'No description'),
        trailing: Text('\$${widget.cake.price.toStringAsFixed(2)}'),
        onTap: () async {
          if (_isProcessing) return;
          setState(() => _isProcessing = true);

          final user = FirebaseAuth.instance.currentUser;

          if (user == null) {
            Fluttertoast.showToast(msg: 'Please log in to add to cart');
            await Future.delayed(const Duration(milliseconds: 200));
            if (mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushNamed(context, '/auth');
              });
            }
            setState(() => _isProcessing = false);
            return;
          }

          try {
            await FirestoreService().addToCart(user.uid, widget.cake.id, 1);
            Fluttertoast.showToast(msg: '${widget.cake.name} added to cart');
            await Future.delayed(const Duration(milliseconds: 200));
            if (mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushNamed(context, '/cart');
              });
            }
          } catch (e) {
            Fluttertoast.showToast(msg: 'Error adding to cart: $e');
          } finally {
            if (mounted) setState(() => _isProcessing = false);
          }
        },

        // Disable animations and hover effects
        enableFeedback: false,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        selected: false,
      ),
    );
  }
}