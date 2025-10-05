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

  List<String> _allIngredients = [];
  List<String> _selectedIngredients = [];

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
        // Collect unique ingredients from all cakes
        final ingredientsSet = <String>{};
        for (var cake in cakes) {
          ingredientsSet.addAll(cake.ingredients); // ingredients array from backend
        }

        setState(() {
          _cakes = cakes;
          _filteredCakes = cakes;
          _allIngredients = ingredientsSet.toList()..sort();
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
      if (mounted) setState(() => _cartItemCount = 0);
    }
  }

  void _filterCakes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCakes = _cakes.where((cake) {
        final matchesSearch = cake.name.toLowerCase().contains(query) ||
            cake.description.toLowerCase().contains(query);

        final matchesIngredient = _selectedIngredients.isEmpty
            ? true
            : cake.ingredients
                .any((ing) => _selectedIngredients.contains(ing));

        return matchesSearch && matchesIngredient;
      }).toList();
    });
  }

  void _openIngredientSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Ingredients',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: _allIngredients.map((ingredient) {
                  final isSelected = _selectedIngredients.contains(ingredient);
                  return ChoiceChip(
                    label: Text(ingredient),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedIngredients.add(ingredient);
                        } else {
                          _selectedIngredients.remove(ingredient);
                        }
                        _filterCakes();
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close modal
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      },
    );
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
            // Row with search bar + ingredients button
            Row(
              children: [
                Expanded(
                  child: Container(
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
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _openIngredientSelector,
                  child: const Text('Ingredients'),
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
