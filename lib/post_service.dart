import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the collection reference
  CollectionReference<Map<String, dynamic>> get _postsCollection =>
      _firestore.collection('Posts');

  // Create a new post
  Future<void> createPost({
    required String content,
    String? imageUrl,
    required BuildContext context,
  }) async {
    try {
      // Check if user is logged in
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to post')),
        );
        return;
      }

      // Create post data matching the Firebase structure shown in screenshot
      final postData = {
        'FK_users_Id': user.uid,
        'post_content': content,
        'date_created': FieldValue.serverTimestamp(),
        'date_edited': FieldValue.serverTimestamp(),
      };

      // Add image URL if provided
      if (imageUrl != null && imageUrl.isNotEmpty) {
        postData['post_image'] = imageUrl;
      }

      // Add to Firestore
      await _postsCollection.add(postData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating post: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      rethrow; // Rethrow to handle in the UI
    }
  }

  // Fetch posts from Firestore
  Stream<QuerySnapshot<Map<String, dynamic>>> getPosts() {
    return _postsCollection
        .orderBy('date_created', descending: true)
        .snapshots();
  }

  // Delete a post
  Future<void> deletePost(String postId) async {
    try {
      await _postsCollection.doc(postId).delete();
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

      await _postsCollection.doc(postId).update(updateData);
    } catch (e) {
      print('Error updating post: $e');
      rethrow;
    }
  }
}
