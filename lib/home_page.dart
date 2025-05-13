import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'post_service.dart';
import 'post.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PostService _postService = PostService();
  final AuthService _auth = AuthService();
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigation logic
    switch (index) {
      case 0: // Home - already on this page
        break;
      case 1: // Create Post
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreatePostScreen()),
        );
        break;
      case 2: // Profile
        // Will navigate to profile page when implemented
        break;
    }
  }

  // Helper method to create user avatar
  Widget _buildUserAvatar({String? photoUrl, double radius = 24}) {
    // Default avatar with icon as fallback
    if (photoUrl == null ||
        photoUrl.isEmpty ||
        photoUrl.contains('example.com')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.blue.shade100,
        child: Icon(
          Icons.person,
          color: Colors.blue.shade700,
          size: radius * 1.2,
        ),
      );
    }

    // Try to use the photo URL, but with error handling
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.blue.shade100,
      backgroundImage: NetworkImage(photoUrl),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        // This child will only be visible if the image fails to load
        child: Icon(
          Icons.person,
          color: Colors.blue.shade700,
          size: radius * 1.2,
          // Initially invisible, will become visible if image fails
          // via errorBuilder of the network image
        ),
      ),
    );
  }

  // Helper method to validate and check if an image URL is valid
  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    if (url.contains('example.com')) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Petflix',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.blue),
            onPressed: () async {
              await _auth.signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // User profile snippet
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildUserAvatar(photoUrl: user?.photoURL),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'User',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Posts feed
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _postService.getPosts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No posts yet. Create your first post!'),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final post = snapshot.data!.docs[index].data();
                    final postId = snapshot.data!.docs[index].id;
                    final timestamp = post['date_created'] as Timestamp?;
                    final postDate = timestamp?.toDate() ?? DateTime.now();
                    final String? imageUrl = post['post_image'];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Post header
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                _buildUserAvatar(radius: 20),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'User', // Replace with actual user name lookup
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${postDate.day}/${postDate.month}/${postDate.year} ${postDate.hour}:${postDate.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                if (post['FK_users_Id'] == user?.uid)
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert),
                                    onSelected: (value) {
                                      if (value == 'delete') {
                                        _postService.deletePost(postId);
                                      }
                                    },
                                    itemBuilder:
                                        (context) => [
                                          const PopupMenuItem<String>(
                                            value: 'delete',
                                            child: Text('Delete'),
                                          ),
                                        ],
                                  ),
                              ],
                            ),
                          ),

                          // Post content
                          if (post['post_content'] != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Text(
                                post['post_content'],
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),

                          // Post image - only render if URL is valid
                          if (_isValidImageUrl(imageUrl))
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                              child: Image.network(
                                imageUrl!,
                                width: double.infinity,
                                height: 250,
                                fit: BoxFit.cover,
                                loadingBuilder: (
                                  context,
                                  child,
                                  loadingProgress,
                                ) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    height: 250,
                                    width: double.infinity,
                                    color: Colors.grey.shade200,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value:
                                            loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 250,
                                    width: double.infinity,
                                    color: Colors.grey.shade200,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.broken_image,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Could not load image',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),

                          // Post actions
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.thumb_up_outlined),
                                  onPressed: () {
                                    // Implement like functionality
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.comment_outlined),
                                  onPressed: () {
                                    // Implement comment functionality
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share_outlined),
                                  onPressed: () {
                                    // Implement share functionality
                                  },
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
