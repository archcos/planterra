import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth; // Alias for firebase_auth
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // For picking images from gallery
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _displayNameController = TextEditingController();
  File? _profileImage;
  String? _currentProfilePictureUrl;

  @override
  void initState() {
    super.initState();
    final firebase_auth.User? user = firebase_auth.FirebaseAuth.instance.currentUser; // Use alias here
    if (user != null) {
      _displayNameController.text = user.displayName ?? '';
      _currentProfilePictureUrl = user.photoURL;
    }
  }

  // Function to pick profile image
  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  // Save the changes (Name and Profile Image)
  Future<void> _saveChanges() async {
    final firebase_auth.User? user = firebase_auth.FirebaseAuth.instance.currentUser; // Use alias here

    // Only update display name if it has changed
    if (_displayNameController.text.isNotEmpty &&
        _displayNameController.text != user?.displayName) {
      await user?.updateDisplayName(_displayNameController.text);
    }

    String? profilePictureUrl;

    // Only upload a new image if there is one
    if (_profileImage != null) {
      final fileName = '${user?.email}_${DateTime.now().millisecondsSinceEpoch}';
      final filePath = 'profile_picture/$fileName';

      // Upload image to Supabase storage
      final response = await Supabase.instance.client.storage.from('profile_picture').upload(filePath, _profileImage!);

      if (response.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: ${response.error?.message}')),
        );
        return;
      }

      // Get the image URL after uploading
      profilePictureUrl = Supabase.instance.client.storage.from('profile_picture').getPublicUrl(filePath);
    }

    // Update Firestore profile document with the changes (name and profile picture URL if uploaded)
    if (user != null) {
      final userProfileRef = FirebaseFirestore.instance.collection('profiles').doc(user.email); // Use email as document ID

      // Update Firestore document with the new data
      await userProfileRef.set({
        'name': _displayNameController.text, // Update name
        if (profilePictureUrl != null) 'profile_picture': profilePictureUrl // Only update if there's a new profile picture
      }, SetOptions(merge: true));

      // Optionally update photoURL in FirebaseAuth if a new image is uploaded
      if (profilePictureUrl != null && profilePictureUrl != _currentProfilePictureUrl) {
        await user.updatePhotoURL(profilePictureUrl);
      }
    }

    // Show confirmation snack bar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully')),
    );

    // Navigate back to Profile screen
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final firebase_auth.User? user = firebase_auth.FirebaseAuth.instance.currentUser; // Use alias here

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Picture (Editable)
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : (_currentProfilePictureUrl != null
                    ? NetworkImage(_currentProfilePictureUrl!)
                    : AssetImage('assets/images/default_avatar.png') as ImageProvider),
                child: const Icon(Icons.camera_alt, size: 40, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            // Display Name Field
            TextField(
              controller: _displayNameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Save Button
            ElevatedButton(
              onPressed: _saveChanges,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

extension on String {
  get error => null;
}
