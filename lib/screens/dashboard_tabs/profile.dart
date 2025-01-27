import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:planterra/screens/dashboard_tabs/profile_edit.dart';
import '../login.dart'; // Ensure you import the login screen for navigation
import 'package:timeago/timeago.dart' as timeago;

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _profileName;
  String? _profilePictureUrl;
  bool _isLoading = true;
  List<DocumentSnapshot> _posts = []; // List to store user posts

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadUserPosts(); // Load posts as well
  }

  Future<String?> _getUserName() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('profiles')
            .doc(user.email) // Using email as the document ID
            .get();

        if (snapshot.exists) {
          final data = snapshot.data();
          return data?['name'] ?? user.displayName;
        } else {
          return user.displayName ?? 'No Name Available';
        }
      } catch (e) {
        print('Error loading user name: $e');
        return user.displayName ?? 'No Name Available';
      }
    }
    return null;
  }

  // Load user profile data from Firestore
  Future<void> _loadUserProfile() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('profiles')
            .doc(user.email) // Using email as the document ID
            .get();

        if (snapshot.exists) {
          final data = snapshot.data();
          setState(() {
            _profileName = data?['name'] ?? user.displayName;
            _profilePictureUrl = data?['profile_picture'] ?? user.photoURL;
            _isLoading = false;
          });
        } else {
          setState(() {
            _profileName = user.displayName ?? 'No Name Available';
            _profilePictureUrl = user.photoURL ?? '';
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error loading profile: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Fetch posts from Firestore, ordered by timestamp
  Future<void> _loadUserPosts() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('posts')
            .orderBy('timestamp', descending: true) // Order by timestamp, latest first
            .get();

        final posts = snapshot.docs.where((post) {
          String postId = post.id;
          String emailPart = postId.substring(0, postId.length - 12);
          return emailPart == user.email;
        }).toList();

        setState(() {
          _posts = posts;
        });
      } catch (e) {
        print('Error loading posts: $e');
      }
    }
  }

  void _toggleLike(String postId) async {
    final userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) return;

    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
    final likedByRef = postRef.collection('likedBy').doc(userEmail);

    FirebaseFirestore.instance.runTransaction((transaction) async {
      final likedSnapshot = await transaction.get(likedByRef);
      final postSnapshot = await transaction.get(postRef);

      if (likedSnapshot.exists) {
        transaction.delete(likedByRef);
        final currentLikes = postSnapshot.data()?['likes'] ?? 0;
        transaction.update(postRef, {'likes': currentLikes - 1});
      } else {
        transaction.set(likedByRef, {'timestamp': FieldValue.serverTimestamp()});
        final currentLikes = postSnapshot.data()?['likes'] ?? 0;
        transaction.update(postRef, {'likes': currentLikes + 1});
      }
    });
  }

  void _showComments(BuildContext context, String postId) async {
    final TextEditingController commentController = TextEditingController();
    final snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .get();

    final comments = snapshot.docs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
            top: 16.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Comments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: comments.isEmpty
                    ? const Center(child: Text('No comments yet.'))
                    : ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final commentData =
                    comments[index].data() as Map<String, dynamic>;
                    final commentText = commentData['comment'] ?? '';
                    final userName = commentData['userName'] ?? 'Anonymous';
                    final commentTime =
                    (commentData['timestamp'] as Timestamp?)?.toDate();

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    text: userName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '\n$commentText',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.normal,
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (commentTime != null)
                                  Text(
                                    timeago.format(commentTime),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      maxLines: null, // Allows dynamic line expansion
                      keyboardType: TextInputType.multiline, // Enables multiline input
                      decoration: InputDecoration(
                        hintText: 'Write your comment...',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        prefixIcon: Icon(Icons.edit, color: Colors.grey[600]),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 15),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: const BorderSide(color: Colors.green, width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final commentText = commentController.text.trim();
                      final userName = await _getUserName();
                      if (commentText.isNotEmpty) {
                        final commentId = FirebaseFirestore.instance
                            .collection('posts')
                            .doc(postId)
                            .collection('comments')
                            .doc()
                            .id;

                        await FirebaseFirestore.instance
                            .collection('posts')
                            .doc(postId)
                            .collection('comments')
                            .doc(commentId)
                            .set({
                          'comment': commentText,
                          'userName': userName,
                          'userEmail':
                          FirebaseAuth.instance.currentUser?.email,
                          'timestamp': FieldValue.serverTimestamp(),
                        });

                        Navigator.of(context).pop();
                        _showComments(context, postId); // Refresh the comments
                      }
                    },
                    child: const Text('Post'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: _profilePictureUrl != null
                    ? NetworkImage(_profilePictureUrl!)
                    : const AssetImage('assets/images/default_avatar.png')
                as ImageProvider,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person, size: 30),
                  const SizedBox(width: 8),
                  Text(
                    _profileName ?? 'Name not available',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.email, size: 30),
                  const SizedBox(width: 8),
                  Text(
                    user?.email ?? 'Email not available',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EditProfileScreen()),
                  );
                },
                child: const Text('Edit Profile'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                        (route) => false,
                  );
                },
                child: const Text('Sign Out'),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  final postData = post.data() as Map<String, dynamic>;
                  final postId = post.id;
                  final content = postData['content'] ?? '';
                  final imageUrl = postData['imageUrl']; // Added imageUrl field
                  final likes = postData['likes'] ?? 0;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imageUrl != null)
                            Image.network(imageUrl), // Display image if available
                          const SizedBox(height: 8),
                          Text(content, style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.thumb_up),
                                    onPressed: () => _toggleLike(postId),
                                  ),
                                  Text('$likes Likes'),
                                ],
                              ),
                              TextButton(
                                onPressed: () => _showComments(context, postId),
                                child: const Text('Show Comments'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
