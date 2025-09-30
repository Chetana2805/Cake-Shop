import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cake.dart';
import '../services/firestore_service.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({Key? key}) : super(key: key);

  @override
  _WishlistScreenState createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? _user = FirebaseAuth.instance.currentUser;

  late Future<List<Cake>> _wishlistFuture;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  void _loadWishlist() {
    if (_user != null) {
      _wishlistFuture = _firestoreService.getWishlist(_user!.uid);
    }
  }

  Future<void> _refreshWishlist() async {
    setState(() {
      _loadWishlist();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Favorites ❤️"),
        centerTitle: true,
      ),
      body: _user == null
          ? const Center(child: Text("Please login to view favorites"))
          : FutureBuilder<List<Cake>>(
              future: _wishlistFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text("No favorites yet ❤️\nAdd cakes to favorites!"),
                  );
                }

                final wishlist = snapshot.data!;

                return RefreshIndicator(
                  onRefresh: _refreshWishlist,
                  child: ListView.builder(
                    itemCount: wishlist.length,
                    itemBuilder: (context, index) {
                      final cake = wishlist[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: cake.imageUrl.isNotEmpty
                                ? NetworkImage(cake.imageUrl)
                                : null,
                            child: cake.imageUrl.isEmpty
                                ? const Icon(Icons.cake)
                                : null,
                          ),
                          title: Text(cake.name),
                          subtitle: Text("₹${cake.price.toStringAsFixed(2)}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await _firestoreService.toggleFavorite(
                                  _user!.uid, cake);
                              _refreshWishlist();
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
