import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:planterra/screens/dashboard_tabs/profile_edit.dart';
import '../login.dart'; // Ensure you import the login screen for navigation

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _profileName;
  String? _profilePictureUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Load user profile data from Firestore
  Future<void> _loadUserProfile() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Try to load the profile from Firestore
        final snapshot = await FirebaseFirestore.instance
            .collection('profiles')
            .doc(user.email) // Using email as the document ID
            .get();

        if (snapshot.exists) {
          // If profile exists in Firestore, load the data
          final data = snapshot.data();
          setState(() {
            _profileName = data?['name'] ?? user.displayName; // Use Firestore name or FirebaseAuth's displayName
            _profilePictureUrl = data?['profile_picture'] ?? user.photoURL; // Use Firestore picture or FirebaseAuth's photoURL
            _isLoading = false; // Stop loading after data is loaded
          });
        } else {
          // If no profile in Firestore, use FirebaseAuth's data
          setState(() {
            _profileName = user.displayName ?? 'No Name Available'; // Use Google/Firebase display name
            _profilePictureUrl = user.photoURL ?? ''; // Use Google/Firebase photoURL
            _isLoading = false; // Stop loading after data is loaded
          });
        }
      } catch (e) {
        print('Error loading profile: $e');
        setState(() {
          _isLoading = false; // Stop loading in case of an error
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Profile Picture (Avatar)
              CircleAvatar(
                radius: 50,
                backgroundImage: _profilePictureUrl != null
                    ? NetworkImage(_profilePictureUrl!)
                    : (user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : AssetImage('assets/images/default_avatar.png') as ImageProvider),
              ),
              const SizedBox(height: 16),
              // User's Name with Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person, size: 30),
                  const SizedBox(width: 8),
                  Text(
                    _profileName ?? 'Name not available',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // User's Email with Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.email, size: 30),
                  const SizedBox(width: 8),
                  Text(
                    user?.email ?? 'Email not available',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Edit Profile Button
              ElevatedButton(
                onPressed: () {
                  // Navigate to Edit Profile Screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EditProfileScreen()),
                  );
                },
                child: const Text('Edit Profile'),
              ),
              const SizedBox(height: 16),
              // Sign Out Button
              ElevatedButton(
                onPressed: () async {
                  // Sign out functionality
                  await FirebaseAuth.instance.signOut();

                  // Clear navigation stack and navigate to login screen
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                        (route) => false, // Removes all routes from the stack
                  );
                },
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
