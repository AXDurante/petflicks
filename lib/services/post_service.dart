import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the collection reference
  CollectionReference<Map<String, dynamic>> get _postsCollection =>
      _firestore.collection('Posts');

  // Get user document reference
  Future<DocumentSnapshot> _getUserDocument(String userId) async {
    return await _firestore.collection('Users').doc(userId).get();
  }

  // Create a new post
  Future<void> createPost({
    required String content,
    String? imageUrl,
    String? url,
    required BuildContext context,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to post')),
        );
        return;
      }

      // Debug print to verify auth state
      debugPrint('Creating post as user: ${user.uid}');

      // Get user data with error handling
      String username;
      try {
        final userDoc = await _getUserDocument(user.uid);
        if (!userDoc.exists) {
          throw Exception('User document not found');
        }
        final userData = userDoc.data() as Map<String, dynamic>?;
        username = userData?['username'] ?? 'unknown';
      } catch (e) {
        debugPrint('Error getting user data: $e');
        username = 'unknown';
      }

      final postData = {
        'userId': user.uid, // Must match auth uid per your rules
        'username': username,
        'post_content': content,
        'date_created': FieldValue.serverTimestamp(),
        'date_edited': FieldValue.serverTimestamp(),
        'likes_count': 0,
        'comment_count': 0,
        'favorites_count': 0,
      };

      if (imageUrl != null && imageUrl.isNotEmpty) {
        postData['post_image'] = imageUrl;
      }

      if (url != null && url.isNotEmpty) {
        postData['post_url'] = url;
      }

      // Debug print to verify post data
      debugPrint('Post data: $postData');

      await _postsCollection.add(postData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Full error creating post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating post: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      rethrow;
    }
  }

  // Fetch posts from Firestore
  Stream<QuerySnapshot<Map<String, dynamic>>> getPosts() {
    return _postsCollection
        .orderBy('date_created', descending: true)
        .snapshots();
  }

  Future<void> deletePost(String postId, String? imageUrl) async {
    try {
      // Delete post document
      await _postsCollection.doc(postId).delete();

      // Delete image if URL exists and is not null
      if (imageUrl != null && imageUrl.isNotEmpty) {
        // Extract the path from the full URL
        final uri = Uri.parse(imageUrl);
        final path = uri.path.split('/o/').last.split('?').first;
        final decodedPath = Uri.decodeFull(path);

        // Get reference and delete
        await FirebaseStorage.instance.ref(decodedPath).delete();
      }
    } catch (e) {
      print('Error deleting post: $e');
      rethrow;
    }
  }

  // Update a post
  Future<void> updatePost({
    required String postId,
    String? content,
    String? imageUrl,
    String? url,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'date_edited': FieldValue.serverTimestamp(),
      };

      if (content != null) {
        updateData['post_content'] = content;
      }

      if (imageUrl != null) {
        updateData['post_image'] = imageUrl;
      }

      if (url != null) {
        updateData['post_url'] = url;
      }

      await _postsCollection.doc(postId).update(updateData);
    } catch (e) {
      print('Error updating post: $e');
      rethrow;
    }
  }
}
