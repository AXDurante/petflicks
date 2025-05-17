import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'settings_page.dart';
import '../widgets/post_widget.dart';
import '../services/post_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Widget _buildUserAvatar(String? photoUrl) {
    if (photoUrl == null ||
        photoUrl.isEmpty ||
        photoUrl.contains('example.com')) {
      return const CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey,
        child: Icon(Icons.person, color: Colors.black, size: 50),
      );
    }
    return CircleAvatar(
      radius: 50,
      backgroundImage: NetworkImage(photoUrl),
      backgroundColor: Colors.grey.shade300,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;
    final postService = PostService();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('Profile', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(child: _buildUserAvatar(user?.photoURL)),
            const SizedBox(height: 16),
            // Display the display name
            Text(
              user?.displayName ?? 'No Display Name',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            // Display the email
            Text(
              user?.email ?? 'No email',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            // StreamBuilder to fetch and display the username from Firestore
            StreamBuilder<DocumentSnapshot>(
              stream:
                  userId != null
                      ? FirebaseFirestore.instance
                          .collection('Users')
                          .doc(userId)
                          .snapshots()
                      : null,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(); // Return empty widget while loading
                }

                final userData = snapshot.data?.data() as Map<String, dynamic>?;
                final username = userData?['username'] ?? 'No username';

                return Text(
                  '@$username',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
                );
              },
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Your Posts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream:
                  userId != null
                      ? FirebaseFirestore.instance
                          .collection('Posts')
                          .where('userId', isEqualTo: userId)
                          .orderBy('date_created', descending: true)
                          .snapshots()
                      : null,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Column(
                    children: [
                      const SizedBox(height: 40),
                      Image.asset('assets/images/empty_posts.png', height: 150),
                      const SizedBox(height: 20),
                      const Text(
                        'No posts yet',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/create_post');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Create your first post',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  children:
                      snapshot.data!.docs.map((doc) {
                        final post = doc.data() as Map<String, dynamic>;
                        return PostWidget(
                          post: post,
                          postId: doc.id,
                          postService: postService,
                          currentUser: user,
                          timestamp: post['date_created'],
                        );
                      }).toList(),
                );
              },
            ),
            const SizedBox(height: 32),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.black),
              title: const Text(
                'Settings',
                style: TextStyle(color: Colors.black),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.black,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.popUntil(context, (route) => route.isFirst);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
