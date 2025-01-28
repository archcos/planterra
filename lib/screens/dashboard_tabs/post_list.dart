import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter/services.dart';

class PostsList extends StatelessWidget {
  String? _getUserEmail() {
    return FirebaseAuth.instance.currentUser?.email;
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

  void _toggleLike(String postId) async {
    final userEmail = _getUserEmail();
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

  void _addComment(BuildContext context, String postId) async {
    final TextEditingController commentController = TextEditingController();

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
                'Add a Comment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(postId)
                      .collection('comments')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, commentsSnapshot) {
                    if (commentsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!commentsSnapshot.hasData ||
                        commentsSnapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No comments yet.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    final comments = commentsSnapshot.data!.docs;

                    return ListView.builder(
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
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.blueAccent,
                                child: Text(
                                  userName.isNotEmpty
                                      ? userName.substring(0, 1).toUpperCase()
                                      : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 10),
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
                          vertical: 10,
                          horizontal: 15,
                        ),
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
                      if (commentText.isNotEmpty) {
                        final userName = await _getUserName();
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
                          'userEmail': _getUserEmail(),
                          'userName': userName,
                          'timestamp': FieldValue.serverTimestamp(),
                        });

                        commentController.clear(); // Clear input after posting
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No posts available.'));
        }

        final posts = snapshot.data!.docs;

        return ListView.builder(
          key: const PageStorageKey('posts_list'), // Key to preserve the state
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final data = post.data() as Map<String, dynamic>;
            final content = data['content'] ?? '';
            final imageUrl = data['imageUrl'] ?? '';
            final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
            final likes = data['likes'] ?? 0;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullImageScreen(imageUrl: imageUrl),
                            ),
                          );
                        },
                        child: Image.network(
                          imageUrl,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(content, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    if (timestamp != null)
                      Text(
                        'Posted ${timeago.format(timestamp)}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('posts')
                                  .doc(post.id)
                                  .collection('likedBy')
                                  .doc(_getUserEmail())
                                  .snapshots(),
                              builder: (context, likedSnapshot) {
                                final isLiked = likedSnapshot.data?.exists ?? false;

                                return IconButton(
                                  icon: Icon(
                                    isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                                  ),
                                  onPressed: () => _toggleLike(post.id),
                                );
                              },
                            ),
                            Text('$likes Likes'),
                          ],
                        ),
                        TextButton(
                          onPressed: () => _addComment(context, post.id),
                          child: const Text('Comment'),
                        ),
                      ],
                    ),
                    const Divider(),
                    // Display latest comment below the post content
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('posts')
                          .doc(post.id)
                          .collection('comments')
                          .orderBy('timestamp', descending: true)
                          .limit(1) // Fetch only the latest comment
                          .snapshots(),
                      builder: (context, commentsSnapshot) {
                        if (commentsSnapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }

                        if (!commentsSnapshot.hasData || commentsSnapshot.data!.docs.isEmpty) {
                          return const Text('No comments yet.');
                        }

                        final commentData = commentsSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                        final commentText = commentData['comment'] ?? '';
                        final commentUser = commentData['userName'] ?? 'Anonymous';
                        final commentTime =
                        (commentData['timestamp'] as Timestamp?)?.toDate();

                        return GestureDetector(
                          onTap: () {
                            // Open the dialog with all comments and the input field to add a new comment
                            _addComment(context, post.id);  // Call _addComment function directly here
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // RichText for username and timestamp
                                RichText(
                                  text: TextSpan(
                                    text: '$commentUser',  // Username
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '  ${timeago.format(commentTime!)}',  // Time in time ago format, not bold
                                        style: const TextStyle(
                                          fontWeight: FontWeight.normal,  // Normal weight for timestamp
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Comment text (limited to 2 lines with ellipsis if overflows)
                                Padding(
                                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                                  child: Text(
                                    commentText,  // Comment text
                                    maxLines: 2,  // Limit to 2 lines
                                    overflow: TextOverflow.ellipsis,  // Add ellipsis if the text overflows
                                    style: const TextStyle(
                                      fontWeight: FontWeight.normal,
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
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
            );
          },
        );
      },
    );
  }
}


class FullImageScreen extends StatelessWidget {
  final String imageUrl;

  FullImageScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Prevents the default back arrow
        leading: IconButton(
          icon: const Icon(Icons.close), // X button
          onPressed: () {
            Navigator.pop(context); // Close and go back
          },
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}