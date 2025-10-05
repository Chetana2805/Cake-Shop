import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../utils/location_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestore = FirestoreService();
  final user = FirebaseAuth.instance.currentUser;
  String? name;
  String? email;
  String? address;
  List<Map<String, dynamic>> orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final data = await _firestore.getUser(user!.uid);
      final orderDocs = await _firestore.getOrdersWithCakes(user!.uid);

      if (mounted) {
        setState(() {
          name = data?['fullName'] ?? user!.displayName ?? 'Guest';
          email = data?['email'] ?? user!.email ?? '';
          address = data?['address'] ?? '';
          orders = orderDocs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }

  void _editName() {
    final controller = TextEditingController(text: name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter your name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (user == null) return;
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await _firestore.updateUserName(user!.uid, newName);
                await _loadProfile();
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editAddress() {
    final controller = TextEditingController(text: address);
    bool _isFetchingLocation = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add / Edit Address'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter your address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _isFetchingLocation
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: () async {
                        setState(() => _isFetchingLocation = true);
                        final address = await LocationHelper.getCurrentAddress();
                        if (address != null) controller.text = address;
                        setState(() => _isFetchingLocation = false);
                      },
                      icon: const Icon(Icons.my_location),
                      label: const Text('Use Current Location'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (user == null) return;
                final newAddress = controller.text.trim();
                if (newAddress.isNotEmpty) {
                  await _firestore.updateUserAddress(user!.uid, newAddress);
                  await _loadProfile();
                  if (mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _orderAgain(List<Map<String, dynamic>> items) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Fluttertoast.showToast(msg: 'Please log in to add items to cart');
      return;
    }

    try {
      for (var item in items) {
        final cakeId = item['cakeId'] ?? item['id'];
        final quantity = item['quantity'] ?? 1;
        if (cakeId != null) {
          await _firestore.addToCart(user.uid, cakeId, quantity);
        }
      }

      Fluttertoast.showToast(msg: 'Order added to cart!');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error adding to cart: $e');
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    if (user == null) return;
    try {
      await _firestore.cancelOrder(user!.uid, orderId);
      Fluttertoast.showToast(msg: 'Order canceled successfully');
      await _loadProfile();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error canceling order: $e');
    }
  }

  Future<String> _getOrderIdFromOrder(Map<String, dynamic> order) async {
    try {
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('orders')
          .where('total', isEqualTo: order['total'])
          .where('timestamp', isEqualTo: order['timestamp'])
          .limit(1)
          .get();
      return ordersSnapshot.docs.isNotEmpty ? ordersSnapshot.docs.first.id : '';
    } catch (_) {
      return '';
    }
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
          'Profile',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _logout),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name card
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.pinkAccent, Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.pinkAccent,
                          child: const Icon(Icons.person, size: 30),
                        ),
                        title: Text(name ?? 'Guest',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                        subtitle: Text(email ?? 'No email provided',
                            style: const TextStyle(fontSize: 16, color: Colors.black54)),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.pinkAccent),
                          onPressed: _editName,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Address card
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.pinkAccent, Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.pinkAccent,
                          child: const Icon(Icons.home, size: 30),
                        ),
                        title: Text(
                          address != null && address!.isNotEmpty ? address! : 'Add your address',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.pinkAccent),
                          onPressed: _editAddress,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Order History',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: orders.isEmpty
                        ? const Center(child: Text('No orders yet', style: TextStyle(fontSize: 16, color: Colors.black54)))
                        : ListView.builder(
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              final items = order['items'] as List;
                              final total = order['total'] is num ? order['total'] : 0.0;
                              final orderIdFuture = _getOrderIdFromOrder(order);

                              return FutureBuilder<String>(
                                future: orderIdFuture,
                                builder: (context, snapshot) {
                                  final orderId = snapshot.data ?? '';
                                  final timestamp = order['timestamp']?.toDate();

                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 2,
                                    child: ExpansionTile(
                                      leading: const Icon(Icons.shopping_bag, color: Colors.pinkAccent),
                                      title: Text('Total: ₹${total.toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      subtitle: Text(
                                        'Date: ${timestamp != null ? timestamp.toString().split(' ')[0] : 'Unknown'}',
                                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                                      ),
                                      children: [
                                        ...items.map((item) {
                                          return ListTile(
                                            leading: CircleAvatar(
                                              radius: 20,
                                              backgroundColor: Colors.grey[200],
                                             backgroundImage: (item['imageUrl'] != null &&
                                              item['imageUrl'].startsWith('http'))
                                              ? NetworkImage(item['imageUrl']): AssetImage(item['imageUrl'] ??
                                                  'assets/images/cake-1.webp')
                                                  as ImageProvider,
                                              child: (item['imageUrl'] == null ||
                                                item['imageUrl'].isEmpty)
                                              ? const Icon(Icons.cake, size: 16)
                                              : null,
                                            ),
                                            title: Text(item['name'] ?? 'Unknown Item'),
                                            subtitle: Text(
                                              '₹${(item['price'] is num ? item['price'] : 0.0).toStringAsFixed(2)}',
                                              style: const TextStyle(color: Colors.pinkAccent),
                                            ),
                                            trailing: Text('x${item['quantity'] ?? 0}'),
                                          );
                                        }).toList(),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              ElevatedButton(
                                                onPressed: () => _orderAgain(items.cast<Map<String, dynamic>>()),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.pinkAccent,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                ),
                                                child: const Text('Order Again',
                                                    style: TextStyle(color: Colors.white)),
                                              ),
                                              if (orderId.isNotEmpty && timestamp != null)
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 12),
                                                  child: CancelButtonWithTimer(
                                                    timestamp: timestamp,
                                                    onCancel: () => _cancelOrder(orderId),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
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

class CancelButtonWithTimer extends StatelessWidget {
  final DateTime timestamp;
  final VoidCallback onCancel;

  const CancelButtonWithTimer({super.key, required this.timestamp, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
      builder: (context, snapshot) {
        final now = DateTime.now();
        final difference = now.difference(timestamp).inSeconds;
        final remaining = (5 * 60) - difference;

        if (remaining <= 0) {
          return const SizedBox.shrink();
        }

        final minutes = remaining ~/ 60;
        final seconds = remaining % 60;

        return ElevatedButton(
  onPressed: () async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Order"),
        content: const Text("Are you sure you want to cancel this order?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );
    if (confirm == true) onCancel();
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.red,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min, // so button wraps content
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.cancel, size: 16, color: Colors.white),
      const SizedBox(width: 6),
      Text(
        "Cancel (${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')})",
        style: const TextStyle(color: Colors.white),
      ),
    ],
  ),
);

      },
    );
  }
}