import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CreateSaleScreen extends StatefulWidget {
  @override
  _CreateSaleScreenState createState() => _CreateSaleScreenState();
}

class _CreateSaleScreenState extends State<CreateSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;
  final supabase = Supabase.instance.client;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _imageFile != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Upload image to Supabase
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage
            .from('plant_sales')
            .upload(fileName, _imageFile!);

        // Get public URL
        final imageUrl = supabase.storage
            .from('plant_sales')
            .getPublicUrl(fileName);

        // Add to Firestore
        await _firestore.collection('plants').add({
          'name': _nameController.text,
          'quantity': int.parse(_quantityController.text),
          'price': double.parse(_priceController.text),
          'location': _locationController.text,
          'imageUrl': imageUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Return success
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating post: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Sale Post'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _imageFile != null
                      ? Image.file(_imageFile!, fit: BoxFit.cover)
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 50),
                      SizedBox(height: 8),
                      Text('Tap to add photo'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Plant Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter plant name' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter quantity' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter price' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter location' : null,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text('Create Post'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}