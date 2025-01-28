import 'package:cloud_firestore/cloud_firestore.dart';

class PlantItem {
  final String name;
  final int quantity;
  final double price;
  final String location;
  final String imageUrl;

  PlantItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.location,
    required this.imageUrl,
  });

  factory PlantItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlantItem(
      name: data['name'] ?? '',
      quantity: data['quantity'] ?? 0,
      price: data['price'] ?? 0.0,
      location: data['location'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
    );
  }
}