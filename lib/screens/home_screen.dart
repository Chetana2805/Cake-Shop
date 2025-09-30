// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cake.dart';
import '../services/firestore_service.dart';
import '../widgets/cake_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  List<Cake> _cakes = [];
  List<Cake> _filteredCakes = [];
  bool _isLoading = false;
  int _cartItemCount = 0;

  // New: price range
  double _minPrice = 0;
  double _maxPrice = 1000; // adjust as per your cake prices
  RangeValues _selectedRange = const RangeValues(0, 1000);

  @override
  void initState() {
    super.initState();
    _loadCakes();
    _loadCartCount();
    _searchController.addListener(_filterCakes);
  }

  Future<void> _loadCakes() async {
    if (_isLoading) return;
    _isLoading = true;
    try {
      final cakes = await _firestoreService.getCakes();
      if (mounted) {
        setState(() {
          _cakes = cakes;
          _filteredCakes = cakes;
          // Update max price dynamically
          if (_cakes.isNotEmpty) {
            _maxPrice = _cakes.map((c) => c.price).reduce((a, b) => a > b ? a : b);
            _selectedRange = RangeValues(_minPrice, _maxPrice);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading cakes: $e')),
        );
      }
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _loadCartCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final cart = await _firestoreService.getCart(user.uid);
        if (mounted) {
          setState(() {
            _cartItemCount = cart.fold(0, (sum, item) => sum + item.quantity);
          });
        }
      } catch (e) {
        print('Error loading cart count: $e');
      }
    } else {
      if (mounted) {
        setState(() => _cartItemCount = 0);
      }
    }
  }

  void _filterCakes() {
    final query = _searchController.text.toLowerCase();
    final min = _selectedRange.start;
    final max = _selectedRange.end;

    if (mounted) {
      setState(() {
        _filteredCakes = _cakes.where((cake) =>
            (cake.name.toLowerCase().contains(query) ||
             cake.description.toLowerCase().contains(query)) &&
            cake.price >= min &&
            cake.price <= max
        ).toList();
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCakes);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.pinkAccent, Colors.orangeAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Cake Shop',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          // Wishlist button ❤️
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/wishlist');
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () async {
                  await Future.delayed(const Duration(milliseconds: 100));
                  if (mounted) Navigator.pushNamed(context, '/cart');
                },
              ),
              if (_cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_cartItemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for cakes...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Price range slider
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Price Range: ₹${_selectedRange.start.toInt()} - ₹${_selectedRange.end.toInt()}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                RangeSlider(
                  values: _selectedRange,
                  min: _minPrice,
                  max: _maxPrice,
                  divisions: (_maxPrice - _minPrice).toInt(),
                  labels: RangeLabels(
                    '₹${_selectedRange.start.toInt()}',
                    '₹${_selectedRange.end.toInt()}',
                  ),
                  onChanged: (RangeValues values) {
                    setState(() {
                      _selectedRange = values;
                    });
                    _filterCakes();
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Cake grid
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredCakes.isEmpty
                      ? const Center(child: Text('No cakes found'))
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: _filteredCakes.length,
                          itemBuilder: (context, index) {
                            return CakeCard(
                              cake: _filteredCakes[index],
                              onCartUpdated: _loadCartCount,
                              // New: pass wishlist support & discount badges
                              showDiscount: true,
                              enableWishlist: true,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
