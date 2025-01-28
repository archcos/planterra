// selling_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:planterra/screens/dashboard_tabs/sell_create.dart';
import 'package:planterra/screens/dashboard_tabs/sell_details.dart';
import '../../model/plant_model.dart';

class SellingScreen extends StatefulWidget {
  @override
  _SellingScreenState createState() => _SellingScreenState();
}

class _SellingScreenState extends State<SellingScreen> with AutomaticKeepAliveClientMixin {
  bool get wantKeepAlive => true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<PlantItem> allItems = [];
  List<PlantItem> filteredItems = [];
  final TextEditingController _searchController = TextEditingController();
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    try {
      // Use snapshots() for real-time updates
      _firestore.collection('plants').snapshots().listen((snapshot) {
        if (mounted) {
          setState(() {
            allItems = snapshot.docs
                .map((doc) => PlantItem.fromFirestore(doc))
                .toList();
            // Apply current search filter if any
            _filterItems(_searchController.text);
          });
        }
      });
    } catch (e) {
      print('Error loading items: $e');
    }
  }

  void _filterItems(String query) {
    if (mounted) {
      setState(() {
        if (query.isEmpty) {
          filteredItems = List.from(allItems);
        } else {
          query = query.toLowerCase();
          filteredItems = allItems.where((item) {
            final nameLower = item.name.toLowerCase();
            final locationLower = item.location.toLowerCase();
            return nameLower.contains(query) || locationLower.contains(query);
          }).toList();
        }
      });
    }
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search by name or location...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.black26),
        prefixIcon: Icon(Icons.search, color: Colors.black26),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
          icon: Icon(Icons.clear, color: Colors.black),
          onPressed: () {
            _searchController.clear();
            _filterItems('');
          },
        )
            : null,
      ),
      style: TextStyle(color: Colors.black),
      onChanged: _filterItems,
    );
  }

  List<Widget> _buildActions() {
    if (isSearching) {
      return [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              isSearching = false;
              _searchController.clear();
              _filterItems('');
            });
          },
        ),
      ];
    }

    return [
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: () {
          setState(() {
            isSearching = true;
          });
        },
      ),
      Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: ElevatedButton.icon(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreateSaleScreen()),
            );
            if (result == true) {
              _loadItems();
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Create Sell Post'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Theme.of(context).primaryColor,
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        leading: isSearching ? BackButton(
          onPressed: () {
            setState(() {
              isSearching = false;
              _searchController.clear();
              _filterItems('');
            });
          },
        ) : null,
        title: isSearching
            ? _buildSearchField()
            : const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_florist, size: 28),
          ],
        ),
        actions: _buildActions(),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('plants').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No plants available'));
          }

          // Update allItems and filteredItems if not searching
          if (!isSearching) {
            allItems = snapshot.data!.docs
                .map((doc) => PlantItem.fromFirestore(doc))
                .toList();
            filteredItems = List.from(allItems);
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: isSearching ? filteredItems.length : allItems.length,
            itemBuilder: (context, index) {
              final item = isSearching ? filteredItems[index] : allItems[index];
              return PlantItemCard(item: item);
            },
          );
        },
      ),
    );
  }
}

class PlantItemCard extends StatelessWidget {
  final PlantItem item;

  const PlantItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlantDetailScreen(item: item),
          ),
        );
      },
      child: Card(
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Hero(
                tag: 'plant_image_${item.imageUrl}',
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text('Quantity: ${item.quantity}'),
                  Text('Price: \$${item.price.toStringAsFixed(2)}'),
                  Text('Location: ${item.location}',
                      style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}