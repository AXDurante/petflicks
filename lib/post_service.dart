import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

      // Create post data
      final postData = {
        'FK_users_Id': user.uid, // Links to the user who created the post
        'post_content': content,
        'date_created': FieldValue.serverTimestamp(), // Uses server time
        'date_edited':
            FieldValue.serverTimestamp(), // Initially same as created
        if (imageUrl != null) 'post_image': imageUrl,
      };

      // Add to Firestore
      await _firestore.collection('Posts').add(postData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating post: ${e.toString()}')),
      );
    }
  }
}
