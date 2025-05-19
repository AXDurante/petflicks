// services/comment_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get comments for a post
  Stream<QuerySnapshot> getComments(String postId) {
    return _firestore
        .collection('Posts')
        .doc(postId)
        .collection('Comments')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Add a comment to a post
  Future<void> addComment({
    required String postId,
    required String content,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Get user data
    final userDoc = await _firestore.collection('Users').doc(user.uid).get();
    final userData = userDoc.data();

    await _firestore
        .collection('Posts')
        .doc(postId)
        .collection('Comments')
        .add({
          'userId': user.uid,
          'username': userData?['username'],
          'userProfilePic': userData?['profile_picture'] ?? '',
          'content': content,
          'timestamp': FieldValue.serverTimestamp(),
          'likes_count': 0,
        });

    // Update comment count in the post
    await _firestore.collection('Posts').doc(postId).update({
      'comment_count': FieldValue.increment(1),
    });
  }

  // Delete a comment
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    await _firestore
        .collection('Posts')
        .doc(postId)
        .collection('Comments')
        .doc(commentId)
        .delete();

    // Update comment count in the post
    await _firestore.collection('Posts').doc(postId).update({
      'comment_count': FieldValue.increment(-1),
    });
  }

  Stream<int> getCommentsCountStream(String postId) {
    return _firestore
        .collection('Posts')
        .doc(postId)
        .collection('Comments')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }
}
