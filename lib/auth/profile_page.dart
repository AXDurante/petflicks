import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Widget _buildPostItem(DocumentSnapshot post) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post['content'] ??
                  'No content', // Assuming you have a content field
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Posted on ${post['timestamp']?.toDate().toString() ?? 'Unknown time'}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('Profile', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(child: _buildUserAvatar(user?.photoURL)),
              const SizedBox(height: 16),
              Text(
                user?.displayName ?? 'No Display Name',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user?.email ?? 'No email',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
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
                            .orderBy('timestamp', descending: true)
                            .snapshots()
                        : null,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Error loading posts');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text('No posts yet');
                  }

                  return Column(
                    children:
                        snapshot.data!.docs
                            .map((doc) => _buildPostItem(doc))
                            .toList(),
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
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
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
      ),
    );
  }
}
