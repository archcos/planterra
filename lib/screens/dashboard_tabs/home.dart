import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'post_list.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  bool get wantKeepAlive => true;  // Keep the state alive when switching tabs

  final TextEditingController _postController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  String _generateRandomId() {
    final random = Random();
    final chars = '0123456789abcdefghijklmnopqrstuvwxyz';
    return List.generate(11, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _selectedImage = image;
    });
  }

  Future<String?> _uploadImage(String fileName) async {
    try {
      final supabaseClient = Supabase.instance.client;
      final bytes = await _selectedImage!.readAsBytes();

      final response = await supabaseClient.storage
          .from('post_images')
          .uploadBinary(fileName, bytes);

      if (response.error == null) {
        final publicUrl =
        supabaseClient.storage.from('post_images').getPublicUrl(fileName);
        return publicUrl;
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
    }
    return null;
  }

  Future<void> _postContent() async {
    if (_postController.text.isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter text or select an image')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'unknown';
      final randomId = _generateRandomId();
      final documentId = '${userEmail}_$randomId';

      String? imageUrl;
      if (_selectedImage != null) {
        final fileName = '${userEmail}_$randomId';
        imageUrl = await _uploadImage(fileName);
      }

      await FirebaseFirestore.instance.collection('posts').doc(documentId).set({
        'content': _postController.text,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'userEmail': userEmail,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post uploaded successfully!')),
      );
      _postController.clear();
      setState(() {
        _selectedImage = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error posting content: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // return PopScope(
    //   canPop: true, // Allow back navigation
    //   onPopInvokedWithResult: (bool isUserGesture, dynamic result) {
    //     // Scroll to the top of the list
    //     _scrollController.animateTo(
    //       0,
    //       duration: const Duration(milliseconds: 300),
    //       curve: Curves.easeInOut,
    //     );
    //
    //     // Trigger a refresh
    //     setState(() {});
    //
    //     // No return value needed for this callback
    //   },
    super.build(context);  // Don't forget to call super.build()

    return Scaffold(
        appBar: AppBar(title: const Text('Create Post')),
        body: SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _postController,
                  decoration: const InputDecoration(
                    labelText: 'What’s on your mind?',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: null,
                  minLines: 1,
                ),
                if (_selectedImage != null) ...[
                  const SizedBox(height: 16),
                  Image.file(File(_selectedImage!.path), height: 150),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Add Image'),
                    ),
                    ElevatedButton(
                      onPressed: _isUploading ? null : _postContent,
                      child: _isUploading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Post'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                PostsList(), // Include the PostsList widget
              ],
            ),
          ),
        ),
      );
    ")";
  }
}

extension on String {
  get error => null;
}
