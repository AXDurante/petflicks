import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/comments_services/comment_likes_service.dart';
import 'package:rxdart/rxdart.dart';

class CommentLikeButton extends StatefulWidget {
  final String postId;
  final String commentId;
  final CommentLikesService likesService;
  final User? currentUser;

  const CommentLikeButton({
    Key? key,
    required this.postId,
    required this.commentId,
    required this.likesService,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<CommentLikeButton> createState() => _CommentLikeButtonState();
}

class _CommentLikeButtonState extends State<CommentLikeButton> {
  bool? _isLiked;
  int? _likesCount;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        StreamBuilder<List<dynamic>>(
          stream: CombineLatestStream.list([
            widget.likesService
                .getCommentLikeStatusStream(widget.postId, widget.commentId)
                .distinct(),
            widget.likesService
                .getCommentLikesCountStream(widget.postId, widget.commentId)
                .distinct(),
          ]),
          builder: (context, snapshot) {
            final isLiked = _isLiked = snapshot.data?[0] ?? _isLiked ?? false;
            final likesCount =
                _likesCount = snapshot.data?[1] ?? _likesCount ?? 0;

            return Row(
              children: [
                GestureDetector(
                  onTap: _isLoading ? null : () => _handleLike(context),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.grey,
                        size: 18,
                        key: ValueKey<bool>(isLiked),
                      ),
                    ),
                  ),
                ),
                Text(
                  '$likesCount',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _handleLike(BuildContext context) async {
    if (widget.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to like comments'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isLiked = !(_isLiked ?? false);
      _likesCount = (_likesCount ?? 0) + (_isLiked! ? 1 : -1);
    });

    try {
      await widget.likesService.toggleCommentLike(
        widget.postId,
        widget.commentId,
      );
    } catch (e) {
      setState(() {
        _isLiked = !(_isLiked ?? false);
        _likesCount = (_likesCount ?? 0) + (_isLiked! ? 1 : -1);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating like: ${e.toString()}'),
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
