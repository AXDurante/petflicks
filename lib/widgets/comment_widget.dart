import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/comments_services/comment_likes_service.dart';
import '../buttons/comments/comment_like_button.dart';
import '../services/comments_services/comment_service.dart';

class CommentWidget extends StatelessWidget {
  final Map<String, dynamic> comment;
  final String postId;
  final String commentId;
  final User? currentUser;
  final CommentLikesService _likesService = CommentLikesService();
  final CommentService _commentService = CommentService();

  CommentWidget({
    super.key,
    required this.comment,
    required this.postId,
    required this.commentId,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final timestamp = comment['timestamp'] as Timestamp?;
    final commentDate = timestamp?.toDate() ?? DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage:
                comment['userProfilePic'] != null &&
                        comment['userProfilePic'].isNotEmpty
                    ? NetworkImage(comment['userProfilePic'])
                    : null,
            child:
                comment['userProfilePic'] == null ||
                        comment['userProfilePic'].isEmpty
                    ? const Icon(Icons.person, size: 16)
                    : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@${comment['username']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(comment['content']),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, top: 4),
                      child: Text(
                        '${commentDate.day}/${commentDate.month}/${commentDate.year} '
                        '${commentDate.hour}:${commentDate.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          // Like button for comment
                          CommentLikeButton(
                            postId: postId,
                            commentId: commentId,
                            likesService: _likesService,
                            currentUser: currentUser,
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (comment['userId'] == currentUser?.uid)
            IconButton(
              icon: const Icon(Icons.delete, size: 16),
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Delete Comment'),
                        content: const Text(
                          'Are you sure you want to delete this comment?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context); // Close dialog first
                              try {
                                await _commentService.deleteComment(
                                  postId: postId,
                                  commentId: commentId,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Comment deleted successfully',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to delete: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                );
              },
            ),
        ],
      ),
    );
  }
}
