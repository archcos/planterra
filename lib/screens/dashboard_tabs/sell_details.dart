import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../model/plant_model.dart';

class PlantDetailScreen extends StatelessWidget {
  final PlantItem item;

  const PlantDetailScreen({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              // Implement share functionality
              // You can use share_plus package for this
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with hero animation
            Hero(
              tag: 'plant_image_${item.imageUrl}',
              child: Image.network(
                item.imageUrl,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Price Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Quantity
                  Row(
                    children: [
                      Icon(Icons.inventory_2, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        'Available Quantity: ${item.quantity}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        item.location,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton(
                        onPressed: () async {
                          final url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeFull(item.location)}';
                          if (await canLaunch(url)) {
                            await launch(url);
                          }
                        },
                        child: Text('View on Map'),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Contact Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Implement contact seller functionality
                        // You can open email/chat/phone based on your app's requirements
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text('Contact Seller'),
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