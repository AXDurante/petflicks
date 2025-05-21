import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'settings_page.dart';
import '../widgets/post_widget.dart';
import '../services/post_service.dart';

class ProfilePage extends StatelessWidget {
  final String? userId; // Null means current user

  const ProfilePage({super.key, this.userId});

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

  Widget _buildFollowButton(
    BuildContext context,
    bool isCurrentUser,
    String profileUserId,
  ) {
    if (isCurrentUser) {
      return const SizedBox(); // No follow button for current user
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox();

    final authService = AuthService();

    return StreamBuilder<bool>(
      stream: authService.isFollowing(currentUser.uid, profileUserId),
      builder: (context, snapshot) {
        final isFollowing = snapshot.data ?? false;

        return ElevatedButton(
          onPressed: () async {
            if (snapshot.connectionState == ConnectionState.waiting) return;

            try {
              if (isFollowing) {
                await authService.unfollowUser(currentUser.uid, profileUserId);
              } else {
                await authService.followUser(currentUser.uid, profileUserId);
              }
            } catch (e) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isFollowing ? Colors.grey : Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          ),
          child: Text(
            isFollowing ? 'Following' : 'Follow',
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final profileUserId = userId ?? currentUser?.uid;
    final postService = PostService();

    if (profileUserId == null) {
      return const Scaffold(body: Center(child: Text('User not found')));
    }

    final isCurrentUser = profileUserId == currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('Profile', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        actions: [
          if (isCurrentUser)
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: FutureBuilder<DocumentSnapshot>(
          future:
              FirebaseFirestore.instance
                  .collection('Users')
                  .doc(profileUserId)
                  .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!userSnapshot.hasData || userSnapshot.data!.data() == null) {
              return const Center(child: Text('User not found'));
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(child: _buildUserAvatar(userData['profile_picture'])),
                const SizedBox(height: 16),
                Text(
                  userData['name'] ?? 'No name',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                if (isCurrentUser)
                  Text(
                    currentUser?.email ?? 'No email',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
                  ),
                const SizedBox(height: 8),
                Text(
                  '@${userData['username'] ?? 'nousername'}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
                ),
                const SizedBox(height: 16),
                _buildFollowButton(context, isCurrentUser, profileUserId),
                const SizedBox(height: 24),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          StreamBuilder<QuerySnapshot>(
                            stream:
                                FirebaseFirestore.instance
                                    .collection('Posts')
                                    .where('userId', isEqualTo: profileUserId)
                                    .snapshots(),
                            builder: (context, snapshot) {
                              return Text(
                                snapshot.hasData
                                    ? '${snapshot.data!.docs.length}'
                                    : '0',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                          const Text('Posts'),
                        ],
                      ),
                      Column(
                        children: [
                          StreamBuilder<QuerySnapshot>(
                            stream:
                                FirebaseFirestore.instance
                                    .collection('Users')
                                    .doc(profileUserId)
                                    .collection('followers')
                                    .snapshots(),
                            builder: (context, snapshot) {
                              return Text(
                                snapshot.hasData
                                    ? '${snapshot.data!.docs.length}'
                                    : '0',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                          const Text('Followers'),
                        ],
                      ),
                      Column(
                        children: [
                          StreamBuilder<QuerySnapshot>(
                            stream:
                                FirebaseFirestore.instance
                                    .collection('Users')
                                    .doc(profileUserId)
                                    .collection('following')
                                    .snapshots(),
                            builder: (context, snapshot) {
                              return Text(
                                snapshot.hasData
                                    ? '${snapshot.data!.docs.length}'
                                    : '0',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                          const Text('Following'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (userData['bio'] != null &&
                    userData['bio'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      userData['bio'].toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Posts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('Posts')
                          .where('userId', isEqualTo: profileUserId)
                          .orderBy('date_created', descending: true)
                          .snapshots(),
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
                          Image.asset(
                            'assets/images/empty_posts.png',
                            height: 150,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            isCurrentUser ? 'No posts yet' : 'No posts',
                            style: const TextStyle(fontSize: 16),
                          ),
                          if (isCurrentUser) ...[
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
                              currentUser: currentUser,
                              timestamp: post['date_created'],
                            );
                          }).toList(),
                    );
                  },
                ),
                if (isCurrentUser) ...[
                  const SizedBox(height: 32),
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
              ],
            );
          },
        ),
      ),
    );
  }
}
