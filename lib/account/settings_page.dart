import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  File? _profileImage;
  bool _isLoading = false;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _displayNameController = TextEditingController(text: user?.displayName);
    _emailController = TextEditingController(text: user?.email);
    _photoUrl = user?.photoURL;

    // Load username and profile picture from Firestore
    if (user?.uid != null) {
      FirebaseFirestore.instance.collection('Users').doc(user?.uid).get().then((
        snapshot,
      ) {
        if (snapshot.exists) {
          final data = snapshot.data();
          if (data?.containsKey('username') ?? false) {
            _usernameController = TextEditingController(
              text: data?['username'],
            );
          }
          if (data?.containsKey('profile_picture') ?? false) {
            _photoUrl = data?['profile_picture'];
          }
          setState(() {});
        }
      });
    }

    _usernameController = TextEditingController();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_profileImage == null) return null;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${user.uid}.jpg');

      final uploadTask = storageRef.putFile(_profileImage!);
      final snapshot = await uploadTask.whenComplete(() {});

      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      if (e.code == 'unauthorized') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You don\'t have permission to upload images'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: ${e.message}')),
        );
      }
      return null;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      return null;
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get the current username before updating (for comparison)
      final currentUserDoc =
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(user.uid)
              .get();
      final currentUsername = currentUserDoc.data()?['username'] ?? '';

      // Upload profile image if selected
      String? newProfilePictureUrl;
      if (_profileImage != null) {
        newProfilePictureUrl = await _uploadProfileImage();
      }

      // Update email if changed
      if (_emailController.text != user.email) {
        await user.updateEmail(_emailController.text);
      }

      // Update display name if changed
      if (_displayNameController.text != user.displayName) {
        await user.updateDisplayName(_displayNameController.text);
      }

      // Update user data in Firestore
      final userData = {
        'username': _usernameController.text,
        if (newProfilePictureUrl != null)
          'profile_picture': newProfilePictureUrl,
      };

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));

      // If username changed, update all posts by this user
      if (_usernameController.text != currentUsername) {
        // Get all posts by this user
        final postsQuery =
            await FirebaseFirestore.instance
                .collection('Posts')
                .where('userId', isEqualTo: user.uid)
                .get();

        // Batch update all posts
        final batch = FirebaseFirestore.instance.batch();
        for (final post in postsQuery.docs) {
          batch.update(post.reference, {'username': _usernameController.text});
        }
        await batch.commit();
      }

      // Update auth photoURL if we have a new profile picture
      if (newProfilePictureUrl != null) {
        await user.updatePhotoURL(newProfilePictureUrl);
        setState(() {
          _photoUrl = newProfilePictureUrl;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
        _profileImage = null; // Reset the image file after upload
      });
    }
  }

  Widget _buildProfileImage() {
    if (_profileImage != null) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: FileImage(_profileImage!),
      );
    } else if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: NetworkImage(_photoUrl!),
      );
    } else {
      return const CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey,
        child: Icon(Icons.person, size: 50, color: Colors.white),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            _buildProfileImage(),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _displayNameController,
                        decoration: const InputDecoration(
                          labelText: 'Display Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your display name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a username';
                          }
                          if (value.contains(' ')) {
                            return 'Username cannot contain spaces';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _updateProfile,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Save Changes',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.password, color: Colors.blue),
                        title: const Text('Change Password'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // Navigate to change password screen
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete, color: Colors.red),
                        title: const Text(
                          'Delete Account',
                          style: TextStyle(color: Colors.red),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // Show delete account confirmation
                        },
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
