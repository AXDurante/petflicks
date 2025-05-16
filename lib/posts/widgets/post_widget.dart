import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../post_service.dart';

class PostWidget extends StatelessWidget {
  final Map<String, dynamic> post;
  final String postId;
  final PostService postService;
  final User? currentUser;
  final Timestamp? timestamp;

  const PostWidget({
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
                        'User',
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
                  if (post['FK_users_Id'] == currentUser?.uid)
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

            // Post image
            if (_isValidImageUrl(post['post_image']) ||
                _isValidImageUrl(post['post_url']))
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
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

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  Icon(Icons.thumb_up_outlined, color: Colors.black),
                  Icon(Icons.comment_outlined, color: Colors.black),
                  Icon(Icons.share_outlined, color: Colors.black),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
