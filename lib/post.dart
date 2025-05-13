import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'post_service.dart'; // The service we created earlier

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _postController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;
  final PostService _postService = PostService();
  final ImagePicker _picker = ImagePicker();
  double _uploadProgress = 0.0;
  bool _isUploading = false;
  bool _imageError = false;

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        // Verify the file exists and is readable
        if (await file.exists()) {
          setState(() {
            _imageFile = file;
            _imageError = false;
          });
        } else {
          setState(() {
            _imageError = true;
          });
          _showErrorMessage('Selected image file not accessible');
        }
      }
    } catch (e) {
      setState(() {
        _imageError = true;
      });
      _showErrorMessage('Error picking image: ${e.toString()}');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        // Verify the file exists and is readable
        if (await file.exists()) {
          setState(() {
            _imageFile = file;
            _imageError = false;
          });
        } else {
          setState(() {
            _imageError = true;
          });
          _showErrorMessage('Camera image file not accessible');
        }
      }
    } catch (e) {
      setState(() {
        _imageError = true;
      });
      _showErrorMessage('Error taking photo: ${e.toString()}');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _clearImage() async {
    setState(() {
      _imageFile = null;
      _imageError = false;
    });
  }

  Future<void> _uploadPost() async {
    if (_postController.text.isEmpty && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter text or add an image for your post'),
        ),
      );
      return;
    }

    if (_imageError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'There was an issue with the selected image. Please try another image.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      String? imageUrl;
      if (_imageFile != null) {
        // Check if file is readable
        try {
          await _imageFile!.readAsBytes();
        } catch (e) {
          throw Exception('Cannot read the image file: ${e.toString()}');
        }

        // Upload image with progress tracking
        final fileName = 'posts/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance.ref().child(fileName);

        final uploadTask = ref.putFile(_imageFile!);

        // Listen to upload progress
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          setState(() {
            _uploadProgress = progress;
          });
        });

        // Wait for upload to complete
        await uploadTask;

        // Get download URL
        imageUrl = await ref.getDownloadURL();
      }

      // Create post with the retrieved image URL
      await _postService.createPost(
        content: _postController.text,
        imageUrl: imageUrl,
        context: context,
      );

      // Clear form after successful post
      _postController.clear();
      setState(() {
        _imageFile = null;
        _imageError = false;
      });

      // Return to previous screen
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isUploading = false;
      });
    }
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade50,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Post'),
              onPressed: _uploadPost,
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info section
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(
                      Icons.person,
                      color: Colors.blue.shade700,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'What\'s on your mind?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Text input
              TextField(
                controller: _postController,
                decoration: const InputDecoration(
                  hintText: "Share something about your pets...",
                  border: InputBorder.none,
                ),
                maxLines: 5,
                minLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),

              // Image preview
              if (_imageFile != null && !_imageError) ...[
                const SizedBox(height: 16),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Builder(
                        builder: (context) {
                          try {
                            return Image.file(
                              _imageFile!,
                              width: double.infinity,
                              height: 250,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Handle image load error
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  setState(() {
                                    _imageError = true;
                                  });
                                });
                                return Container(
                                  width: double.infinity,
                                  height: 250,
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            );
                          } catch (e) {
                            // Set error state if we can't display the image
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              setState(() {
                                _imageError = true;
                              });
                            });
                            return Container(
                              width: double.infinity,
                              height: 250,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                          onPressed: _clearImage,
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Show error message if image couldn't be loaded
              if (_imageError) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Image Error',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'There was a problem with the selected image. Please try selecting another image.',
                        style: TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _clearImage,
                        child: const Text('Clear Image'),
                      ),
                    ],
                  ),
                ),
              ],

              // Upload progress indicator
              if (_isUploading && _uploadProgress > 0) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                const SizedBox(height: 8),
                Text(
                  'Uploading image: ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ],

              const SizedBox(height: 24),

              // Action buttons
              Divider(color: Colors.grey.shade300),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    InkWell(
                      onTap: _isLoading ? null : _pickImage,
                      borderRadius: BorderRadius.circular(30),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 16.0,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.photo_library,
                              color: Colors.green.shade600,
                            ),
                            const SizedBox(width: 8),
                            const Text('Gallery'),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _isLoading ? null : _takePhoto,
                      borderRadius: BorderRadius.circular(30),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 16.0,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.camera_alt, color: Colors.blue.shade600),
                            const SizedBox(width: 8),
                            const Text('Camera'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
