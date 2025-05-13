import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final AuthService _auth = AuthService();
  bool _isLoggingOut = false;

  void _handleLogout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _auth.signOut();
      // Force navigation to login page in case the AuthWrapper doesn't respond fast enough
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Petflix',
          style: TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: Colors.blue),
            onPressed: () {
              Navigator.pushNamed(context, '/create_post');
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.blue),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
            onPressed: () {},
          ),
          IconButton(
            icon:
                _isLoggingOut
                    ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      strokeWidth: 2.0,
                    )
                    : const Icon(Icons.logout, color: Colors.blue),
            onPressed: _isLoggingOut ? null : _handleLogout,
          ),
        ],
      ),
      body: const PetFeed(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 2) {
            // Pet icon for adding post
            Navigator.pushNamed(context, '/create_post');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Add'),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_collection_outlined),
            label: 'Reels',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              radius: 13,
              backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1543466835-00a7907e9de1',
              ),
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class PetFeed extends StatelessWidget {
  const PetFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => PostItem(index: index),
            childCount: 10,
          ),
        ),
      ],
    );
  }
}

class PostItem extends StatelessWidget {
  final int index;

  const PostItem({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final petImages = [
      'https://images.unsplash.com/photo-1543466835-00a7907e9de1',
      'https://images.unsplash.com/photo-1425082661705-1834bfd09dca',
      'https://images.unsplash.com/photo-1548802673-380ab8ebc7b7',
      'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e',
      'https://images.unsplash.com/photo-1592194996308-7b43878e84a6',
    ];

    final random = index % petImages.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(petImages[random]),
            ),
            title: Text(
              'Fluffy_${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Animal Shelter'),
            trailing: const Icon(Icons.more_vert),
          ),

          // Post image
          GestureDetector(
            onDoubleTap: () {},
            child: Image.network(
              petImages[random],
              fit: BoxFit.cover,
              width: double.infinity,
              height: 300,
            ),
          ),

          // Post actions
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () {},
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: () {}),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.bookmark_border),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Likes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${(index + 1) * 127} likes',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // Caption
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                    text: 'Fluffy_${index + 1} ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                        'Having a wonderful day at the park! 🐾 '
                        '#petflicks #cute #adorable #pet #adoption',
                  ),
                ],
              ),
            ),
          ),

          // Comments
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'View all ${(index + 1) * 13} comments',
              style: const TextStyle(color: Colors.grey),
            ),
          ),

          // Time
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '${index + 1} hours ago',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
