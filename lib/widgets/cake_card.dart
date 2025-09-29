// lib/widgets/cake_card.dart
import 'package:flutter/material.dart';
import '../models/cake.dart';
import '../services/firestore_service.dart';
import '../screens/cake_details_screen.dart';
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

       onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CakeDetailsScreen(cake: widget.cake),
        ),
      );
    },
    
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
                        placeholder: const AssetImage('assets/images/placeholder-2.png'),
                        image: AssetImage(widget.cake.imageUrl),
                        height: 120, // reduced for responsiveness
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : const SizedBox(
                        height: 120,
                        child: Center(child: Icon(Icons.cake, size: 50, color: Colors.grey)),
                      ),
              ),

              // DETAILS
              Expanded(
                child: Padding(
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
                      Expanded(
                        child: Text(
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
                      ),
                      const SizedBox(height: 8),

                      // PRICE + BUTTON
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹${widget.cake.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.pinkAccent,
                            ),
                          ),
                          Flexible(
                            child: ElevatedButton(
                              onPressed: _isProcessing ? null : () async {
                                if (_isProcessing) return;
                                setState(() => _isProcessing = true);
                                final user = FirebaseAuth.instance.currentUser;
                                if (user == null) {
                                  Fluttertoast.showToast(msg: 'Please log in to add to cart');
                                  await Future.delayed(const Duration(milliseconds: 200));
                                  if (mounted) {
                                    Navigator.pushNamed(context, '/auth');
                                  }
                                  setState(() => _isProcessing = false);
                                  return;
                                }
                                try {
                                  await FirestoreService().addToCart(user.uid, widget.cake.id, 1);
                                  Fluttertoast.showToast(
                                  msg: '${widget.cake.name} added to cart',
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  backgroundColor: Colors.black, // black background
                                  textColor: Colors.white,       // white text
                                  fontSize: 14.0,
                                );
                                widget.onCartUpdated?.call();
                                } catch (e) {
                                  Fluttertoast.showToast(msg: 'Error adding to cart: $e');
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
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: const Size(60, 30), // smaller for mobile
                              ),
                              child: const Text('Add to Cart', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}