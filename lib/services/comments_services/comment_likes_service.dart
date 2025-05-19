import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentLikesService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CommentLikesService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  // Like a comment
  Future<void> likeComment(String postId, String commentId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    final commentRef = _firestore
        .collection('Posts')
        .doc(postId)
        .collection('Comments')
        .doc(commentId);

    final likeRef = commentRef.collection('Likes').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final likeSnapshot = await transaction.get(likeRef);

      if (!likeSnapshot.exists) {
        transaction.set(likeRef, {'timestamp': FieldValue.serverTimestamp()});
        transaction.update(commentRef, {
          'likes_count': FieldValue.increment(1),
        });
      }
    });
  }

  // Unlike a comment
  Future<void> unlikeComment(String postId, String commentId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    final commentRef = _firestore
        .collection('Posts')
        .doc(postId)
        .collection('Comments')
        .doc(commentId);

    final likeRef = commentRef.collection('Likes').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final likeSnapshot = await transaction.get(likeRef);

      if (likeSnapshot.exists) {
        transaction.delete(likeRef);
        transaction.update(commentRef, {
          'likes_count': FieldValue.increment(-1),
        });
      }
    });
  }

  // Toggle like status
  Future<void> toggleCommentLike(String postId, String commentId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    final commentRef = _firestore
        .collection('Posts')
        .doc(postId)
        .collection('Comments')
        .doc(commentId);

    final likeRef = commentRef.collection('Likes').doc(userId);

    final likeDoc = await likeRef.get();

    final batch = _firestore.batch();
    if (likeDoc.exists) {
      batch.delete(likeRef);
      batch.update(commentRef, {'likes_count': FieldValue.increment(-1)});
    } else {
      batch.set(likeRef, {'timestamp': FieldValue.serverTimestamp()});
      batch.update(commentRef, {'likes_count': FieldValue.increment(1)});
    }

    await batch.commit();
  }

  // Check if current user liked a comment
  Future<bool> isCommentLiked(String postId, String commentId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    final likeSnapshot =
        await _firestore
            .collection('Posts')
            .doc(postId)
            .collection('Comments')
            .doc(commentId)
            .collection('Likes')
            .doc(userId)
            .get();

    return likeSnapshot.exists;
  }

  // Stream of like count for a comment
  Stream<int> getCommentLikesCountStream(String postId, String commentId) {
    return _firestore
        .collection('Posts')
        .doc(postId)
        .collection('Comments')
        .doc(commentId)
        .snapshots()
        .map((snapshot) => snapshot.data()?['likes_count'] ?? 0);
  }

  // Stream of current user's like status for a comment
  Stream<bool> getCommentLikeStatusStream(String postId, String commentId) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(false);

    return _firestore
        .collection('Posts')
        .doc(postId)
        .collection('Comments')
        .doc(commentId)
        .collection('Likes')
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }
}
