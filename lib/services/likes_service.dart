import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LikesService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // Constructor (allow dependency injection for testing)
  LikesService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  // Like a post (with transaction)
  Future<void> likePost(String postId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    final postRef = _firestore.collection('Posts').doc(postId);
    final likeRef = postRef.collection('Likes').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final likeSnapshot = await transaction.get(likeRef);

      if (!likeSnapshot.exists) {
        transaction.set(likeRef, {'timestamp': FieldValue.serverTimestamp()});
        transaction.update(postRef, {'Likes_count': FieldValue.increment(1)});
      }
    });
  }

  // Unlike a post (with transaction)
  Future<void> unlikePost(String postId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    final postRef = _firestore.collection('Posts').doc(postId);
    final likeRef = postRef.collection('Likes').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final likeSnapshot = await transaction.get(likeRef);

      if (likeSnapshot.exists) {
        transaction.delete(likeRef);
        transaction.update(postRef, {'likes_count': FieldValue.increment(-1)});
      }
    });
  }

  Future<void> toggleLike(String postId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    final postRef = _firestore.collection('Posts').doc(postId);
    final likeRef = postRef.collection('Likes').doc(userId);

    final likeDoc = await likeRef.get();

    // Use batch instead of transaction when possible
    final batch = _firestore.batch();

    if (likeDoc.exists) {
      batch.delete(likeRef);
      batch.update(postRef, {'likes_count': FieldValue.increment(-1)});
    } else {
      batch.set(likeRef, {'date_created': FieldValue.serverTimestamp()});
      batch.update(postRef, {'likes_count': FieldValue.increment(1)});
    }

    await batch.commit();
  }

  // Check if current user liked a post
  Future<bool> isPostLiked(String postId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    final likeSnapshot =
        await _firestore
            .collection('Posts')
            .doc(postId)
            .collection('Likes')
            .doc(userId)
            .get();

    return likeSnapshot.exists;
  }

  // Stream of like count for a post
  Stream<int> getLikesCountStream(String postId) {
    return _firestore
        .collection('Posts')
        .doc(postId)
        .snapshots()
        .map((snapshot) => snapshot.data()?['likes_count'] ?? 0);
  }

  // Stream of current user's like status
  Stream<bool> getLikeStatusStream(String postId) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(false);

    return _firestore
        .collection('Posts')
        .doc(postId)
        .collection('Likes')
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }
}
