// widgets/comment_section.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/comments_services/comment_service.dart';
import 'comment_widget.dart';

class CommentSection extends StatefulWidget {
  final String postId;
  final User? currentUser;

  const CommentSection({
    super.key,
    required this.postId,
    required this.currentUser,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final CommentService _commentService = CommentService();
  final TextEditingController _commentController = TextEditingController();
  late final Stream<QuerySnapshot> _commentsStream; // Cache the stream

  @override
  void initState() {
    super.initState();
    _commentsStream = _commentService.getComments(widget.postId);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Comment input field (unchanged)
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Write a comment...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () async {
                  if (_commentController.text.trim().isNotEmpty) {
                    try {
                      await _commentService.addComment(
                        postId: widget.postId,
                        content: _commentController.text.trim(),
                      );
                      _commentController.clear();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to post comment: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
        // Comments list with optimized StreamBuilder
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _commentsStream, // Use the cached stream
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading comments'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No comments yet. Be the first to comment!',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics:
                    const ClampingScrollPhysics(), // Better for nested scrolling
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 4.0,
                    ),
                    child: CommentWidget(
                      key: ValueKey(doc.id), // Important for item identity
                      comment: doc.data() as Map<String, dynamic>,
                      postId: widget.postId,
                      commentId: doc.id,
                      currentUser: widget.currentUser,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
