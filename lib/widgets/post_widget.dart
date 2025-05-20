import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/post_service.dart';
import '../services/likes_service.dart';
import '../buttons/like_button.dart';
import '../buttons/comments/comment_button.dart';
import '../services/comments_services/comment_service.dart';
import 'comment_section_widget.dart';
import '../account/profile_page.dart';

class PostWidget extends StatelessWidget {
  final Map<String, dynamic> post;
  final String postId;
  final PostService postService;
  final User? currentUser;
  final Timestamp? timestamp;
  final LikesService _likesService = LikesService();

  PostWidget({
    super.key,
    required this.post,
    required this.postId,
    required this.postService,
    required this.currentUser,
    this.timestamp,
  });

  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    if (url.contains('example.com')) return false;
    return true;
  }

  Widget _buildUserAvatar({String? photoUrl, double radius = 24}) {
    if (photoUrl == null ||
        photoUrl.isEmpty ||
        photoUrl.contains('example.com')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade300,
        child: Icon(Icons.person, color: Colors.black, size: radius * 1.2),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundImage: NetworkImage(photoUrl),
      backgroundColor: Colors.grey.shade300,
    );
  }

  @override
  Widget build(BuildContext context) {
    final postDate = timestamp?.toDate() ?? DateTime.now();
    final CommentService _commentService = CommentService();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Card(
        color: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info and menu
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(userId: post['userId']),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Modified avatar section to use StreamBuilder
                    StreamBuilder<DocumentSnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('Users')
                              .doc(post['userId'])
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return _buildUserAvatar(radius: 20);
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _buildUserAvatar(radius: 20);
                        }

                        final userData =
                            snapshot.data?.data() as Map<String, dynamic>?;
                        final profilePicture = userData?['profile_picture'];

                        return _buildUserAvatar(
                          photoUrl: profilePicture,
                          radius: 20,
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '@' + post['username'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          '${postDate.day}/${postDate.month}/${postDate.year} '
                          '${postDate.hour}:${postDate.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (post['userId'] == currentUser?.uid)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.black),
                        onSelected: (value) async {
                          if (value == 'delete') {
                            try {
                              final imageUrl = post['post_image'];
                              await postService.deletePost(postId, imageUrl);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Post deleted successfully'),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to delete post: ${e.toString()}',
                                  ),
                                ),
                              );
                            }
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
            ),

            // Post image
            if (_isValidImageUrl(post['post_image']) ||
                _isValidImageUrl(post['post_url']))
              ClipRRect(
                child: Image.network(
                  _isValidImageUrl(post['post_image'])
                      ? post['post_image']
                      : post['post_url']!,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 250,
                      color: Colors.grey.shade200,
                      child: Center(
                        child: CircularProgressIndicator(
                          value:
                              loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 250,
                      color: Colors.grey.shade200,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.broken_image,
                            size: 50,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Could not load image',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 5),

            // Post content
            if (post['post_content'] != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8,
                ),
                child: Text(
                  post['post_content'],
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),

            const SizedBox(height: 5),

            // Like and Comment buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Like button with count
                  Row(
                    children: [
                      LikeButton(
                        postId: postId,
                        likesService: _likesService,
                        currentUser: currentUser,
                      ),
                    ],
                  ),

                  // Comment button
                  CommentButton(
                    postId: postId,
                    commentService: _commentService,
                    currentUser: currentUser,
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder:
                            (context) => DraggableScrollableSheet(
                              expand: false,
                              initialChildSize: 0.7,
                              maxChildSize: 0.9,
                              minChildSize: 0.5,
                              builder:
                                  (context, scrollController) => CommentSection(
                                    postId: postId,
                                    currentUser: currentUser,
                                  ),
                            ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
