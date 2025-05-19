import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/comments_services/comment_service.dart';

class CommentButton extends StatefulWidget {
  final String postId;
  final CommentService commentService;
  final User? currentUser;
  final VoidCallback? onPressed; // Optional callback for when button is pressed

  const CommentButton({
    Key? key,
    required this.postId,
    required this.commentService,
    required this.currentUser,
    this.onPressed,
  }) : super(key: key);

  @override
  State<CommentButton> createState() => _CommentButtonState();
}

class _CommentButtonState extends State<CommentButton> {
  int? _commentsCount;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        StreamBuilder<int>(
          stream:
              widget.commentService
                  .getCommentsCountStream(widget.postId)
                  .distinct(),
          builder: (context, snapshot) {
            // Use cached value while loading
            final commentsCount =
                _commentsCount = snapshot.data ?? _commentsCount ?? 0;

            return Row(
              children: [
                // Comment button
                GestureDetector(
                  onTap: _isLoading ? null : () => _handleComment(context),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (
                        Widget child,
                        Animation<double> animation,
                      ) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: Icon(
                        Icons.comment_outlined,
                        color: Colors.black,
                        key: ValueKey<int>(commentsCount), // Key for animation
                        size: 24,
                      ),
                    ),
                  ),
                ),
                // Comment count
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    '$commentsCount',
                    key: ValueKey<int>(commentsCount), // Key for animation
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _handleComment(BuildContext context) async {
    if (widget.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to comment'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Execute the optional callback if provided
      widget.onPressed?.call();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
