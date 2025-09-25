import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/cake.dart';
import '../services/firestore_service.dart';

class CakeCard extends StatelessWidget {
  final Cake cake;

  CakeCard({required this.cake});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Image.network(cake.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
        title: Text(cake.name),
        subtitle: Text('\$${cake.price} - ${cake.description}'),
        trailing: IconButton(
          icon: Icon(Icons.add_shopping_cart),
          onPressed: () async {
            String userId = FirebaseAuth.instance.currentUser!.uid;
            await FirestoreService().addToCart(userId, cake.id, 1); // Quantity 1 for simplicity
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added to Cart')));
          },
        ),
      ),
    );
  }
}  