import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/likes_service.dart';
import 'package:rxdart/rxdart.dart';

// Optimized like button with count and immediate feedback
class LikeButton extends StatefulWidget {
  final String postId;
  final LikesService likesService;
  final User? currentUser;

  const LikeButton({
    Key? key,
    required this.postId,
    required this.likesService,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  bool? _isLiked;
  int? _likesCount;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Combined StreamBuilder for better efficiency
        StreamBuilder<List<dynamic>>(
          stream: CombineLatestStream.list([
            widget.likesService.getLikeStatusStream(widget.postId).distinct(),
            widget.likesService.getLikesCountStream(widget.postId).distinct(),
          ]),
          builder: (context, snapshot) {
            // Use cached values while loading
            final isLiked = _isLiked = snapshot.data?[0] ?? _isLiked ?? false;
            final likesCount =
                _likesCount = snapshot.data?[1] ?? _likesCount ?? 0;

            return Row(
              children: [
                // Like button
                GestureDetector(
                  onTap: _isLoading ? null : () => _handleLike(context),
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
                        isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                        color: isLiked ? Colors.blue : Colors.black,
                        key: ValueKey<bool>(isLiked), // Key for animation
                        size: 24,
                      ),
                    ),
                  ),
                ),
                // Like count
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    '$likesCount',
                    key: ValueKey<int>(likesCount), // Key for animation
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

  Future<void> _handleLike(BuildContext context) async {
    if (widget.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to like posts'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Optimistic UI update
    setState(() {
      _isLoading = true;
      _isLiked = !(_isLiked ?? false);
      _likesCount = (_likesCount ?? 0) + (_isLiked! ? 1 : -1);
    });

    try {
      await widget.likesService.toggleLike(widget.postId);
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        _isLiked = !(_isLiked ?? false);
        _likesCount = (_likesCount ?? 0) + (_isLiked! ? 1 : -1);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating like: ${e.toString()}'),
          duration: Duration(seconds: 2),
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
