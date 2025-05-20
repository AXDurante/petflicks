import 'package:cloud_firestore/cloud_firestore.dart';

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Search users by username or name
  Future<QuerySnapshot> searchUsers(String query) async {
    return await _firestore
        .collection('Users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThan: query + 'z')
        .get();
  }

  // Search posts by content
  Future<QuerySnapshot> searchPosts(String query) async {
    return await _firestore
        .collection('Posts')
        .where('post_content', isGreaterThanOrEqualTo: query)
        .where('post_content', isLessThan: query + 'z')
        .orderBy('post_content')
        .get();
  }
}
