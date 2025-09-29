// lib/screens/cake_details_screen.dart
import 'package:flutter/material.dart';
import '../models/cake.dart';

class CakeDetailsScreen extends StatelessWidget {
  final Cake cake;

  const CakeDetailsScreen({super.key, required this.cake});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(cake.name),
        backgroundColor: Colors.pinkAccent,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Full image
            cake.imageUrl.isNotEmpty
                ? Image.asset(
                    cake.imageUrl,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                  )
                : const SizedBox(
                    height: 250,
                    child: Center(
                      child: Icon(Icons.cake, size: 80, color: Colors.grey),
                    ),
                  ),

            // Details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cake.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cake.description.isNotEmpty
                        ? cake.description
                        : 'No description available',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),

                  // INGREDIENTS
                  if (cake.ingredients.isNotEmpty) ...[
                        const Text(
                          'Ingredients:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          runSpacing: 6, // vertical spacing between rows
                          spacing: 6,    // horizontal spacing between pills
                          children: cake.ingredients
                              .map(
                                (ing) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.pink[50],
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.pinkAccent.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    ing,
                                    style: const TextStyle(fontSize: 14, color: Colors.pinkAccent),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                      ],


                  Text(
                    'Price: ₹${cake.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.pinkAccent,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Add to cart button
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        // You can reuse FirestoreService addToCart logic here
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${cake.name} added to cart!'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Add to Cart',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}