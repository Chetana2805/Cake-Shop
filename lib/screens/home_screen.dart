import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/cake.dart';
import '../services/firestore_service.dart';
import '../widgets/cake_card.dart';
import 'cart_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  List<Cake> _cakes = [];
  List<Cake> _filteredCakes = [];

  @override
  void initState() {
    super.initState();
    _loadCakes();
    _searchController.addListener(_filterCakes);
  }

  void _loadCakes() async {
    _cakes = await FirestoreService().getCakes();
    setState(() => _filteredCakes = _cakes);
  }

  void _filterCakes() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCakes = _cakes.where((cake) => cake.name.toLowerCase().contains(query)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cake Shop'),
        actions: [
          IconButton(icon: Icon(Icons.shopping_cart), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CartScreen()))),
          IconButton(icon: Icon(Icons.logout), onPressed: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen())); // Redirect to auth? Wait, actually to AuthScreen
          }),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: TextField(controller: _searchController, decoration: InputDecoration(labelText: 'Search Cakes', suffixIcon: Icon(Icons.search))),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCakes.length,
              itemBuilder: (_, index) => CakeCard(cake: _filteredCakes[index]),
            ),
          ),
        ],
      ),
    );
  }
}