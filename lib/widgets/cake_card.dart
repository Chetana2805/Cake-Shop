// lib/widgets/cake_card.dart
import 'package:flutter/material.dart';
import '../models/cake.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CakeCard extends StatefulWidget {
  final Cake cake;
  final VoidCallback? onCartUpdated;

  const CakeCard({super.key, required this.cake, this.onCartUpdated});

  @override
  _CakeCardState createState() => _CakeCardState();
}

class _CakeCardState extends State<CakeCard> with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    print('CakeCard init: cakeId=${widget.cake.id}, imageUrl=${widget.cake.imageUrl}'); // Debug
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: widget.cake.imageUrl.isNotEmpty
                    ? FadeInImage(
                        placeholder: const AssetImage('assets/images/placeholder.png'),
                        image: AssetImage(widget.cake.imageUrl),
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        imageErrorBuilder: (context, error, stackTrace) {
                          print('Image load error for ${widget.cake.imageUrl}: $error\nStackTrace: $stackTrace'); // Debug
                          return const Icon(Icons.error, size: 50, color: Colors.red);
                        },
                      )
                    : const Icon(Icons.cake, size: 50, color: Colors.grey),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.cake.name.isNotEmpty ? widget.cake.name : 'Unknown Cake',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.cake.description.isNotEmpty
                          ? widget.cake.description
                          : 'No description',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${widget.cake.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.pinkAccent,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _isProcessing
                              ? null
                              : () async {
                                  if (_isProcessing) return;
                                  setState(() => _isProcessing = true);
                                  final user = FirebaseAuth.instance.currentUser;
                                  if (user == null) {
                                    Fluttertoast.showToast(
                                        msg: 'Please log in to add to cart');
                                    await Future.delayed(
                                        const Duration(milliseconds: 200));
                                    if (mounted) {
                                      Navigator.pushNamed(context, '/auth');
                                    }
                                    setState(() => _isProcessing = false);
                                    return;
                                  }
                                  try {
                                    await FirestoreService()
                                        .addToCart(user.uid, widget.cake.id, 1);
                                    Fluttertoast.showToast(
                                        msg: '${widget.cake.name} added to cart');
                                    widget.onCartUpdated?.call();
                                    await Future.delayed(
                                        const Duration(milliseconds: 200));
                                    if (mounted) {
                                      Navigator.pushNamed(context, '/cart');
                                    }
                                  } catch (e) {
                                    Fluttertoast.showToast(
                                        msg: 'Error adding to cart: $e');
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isProcessing = false);
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pinkAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Text('Add to Cart'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}