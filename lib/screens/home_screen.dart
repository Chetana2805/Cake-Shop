// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
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
  bool _isLoading = false; // Prevent multiple loads

  @override
  void initState() {
    super.initState();
    _loadCakes();
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

  void _filterCakes() {
    final query = _searchController.text.toLowerCase();
    if (mounted) {
      setState(() {
        _filteredCakes = _cakes.where((cake) =>
            (cake.name.toLowerCase().contains(query) ||
                cake.description.toLowerCase().contains(query))).toList();
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
        title: const Text('Cake Shop'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () async {
              await Future.delayed(const Duration(milliseconds: 100));
              if (mounted) Navigator.pushNamed(context, '/cart');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Cakes',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _cakes.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _filteredCakes.length,
                    itemBuilder: (context, index) {
                      return CakeCard(cake: _filteredCakes[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}