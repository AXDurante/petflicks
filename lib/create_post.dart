import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _captionController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  void _submitPost() {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an image')));
      return;
    }

    // For now, just simulate posting and return to feed
    setState(() => _isLoading = true);

    // Here you would typically upload the image and save the post to the database
    Future.delayed(const Duration(seconds: 1), () {
      setState(() => _isLoading = false);
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created successfully!')),
      );
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitPost,
            child:
                _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Post', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Selection
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      _selectedImage != null
                          ? Image.file(_selectedImage!, fit: BoxFit.cover)
                          : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.add_a_photo,
                                size: 60,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Tap to add a photo',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                ),
              ),
              const SizedBox(height: 20),

              // Caption
              TextField(
                controller: _captionController,
                decoration: const InputDecoration(
                  hintText: 'Write a caption...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
