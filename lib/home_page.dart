import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final AuthService _auth = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome ${user?.displayName ?? 'User'}!'),
            Text('Email: ${user?.email ?? 'No email'}'),
            const SizedBox(height: 20),
            if (user?.photoURL != null)
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(user!.photoURL!),
              ),
          ],
        ),
      ),
    );
  }
}
