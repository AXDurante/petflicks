import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../services/post_service.dart';
import '../widgets/image_cropper_widget.dart';

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
  double _uploadProgress = 0.0;
  bool _isUploading = false;
  bool _imageError = false;

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.black),
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
      _showErrorMessage('Please enter text or add an image for your post');
      return;
    }

    if (_imageError) {
      _showErrorMessage('Issue with the image. Try another one.');
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
        final fileName =
            'posts/${DateTime.now().millisecondsSinceEpoch}_${_imageFile!.path.split('/').last}';
        final ref = FirebaseStorage.instance.ref().child(fileName);

        final uploadTask = ref.putFile(_imageFile!);
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          setState(() {
            _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
          });
        });

        final snapshot = await uploadTask;

        if (snapshot.state == TaskState.success) {
          imageUrl = await ref.getDownloadURL();
        } else {
          throw Exception('Image upload failed.');
        }
      }

      await _postService.createPost(
        content: _postController.text,
        imageUrl: imageUrl,
        context: context,
      );

      _postController.clear();
      setState(() {
        _imageFile = null;
        _imageError = false;
      });

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showErrorMessage('Upload failed: ${e.toString()}');
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Create Post', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        actions: [
          _isLoading
              ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                ),
              )
              : IconButton(
                icon: const Icon(Icons.send, color: Colors.black),
                onPressed: _uploadPost,
              ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.black),
                ),
                const SizedBox(width: 12),
                const Text(
                  "What's on your mind?",
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _postController,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                hintText: "Share something...",
                hintStyle: TextStyle(color: Colors.black),
                border: InputBorder.none,
              ),
              maxLines: 5,
              minLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            if (_isUploading && _uploadProgress > 0) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.grey.shade800,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
              ),
              const SizedBox(height: 8),
              Text(
                'Uploading: ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.black),
              ),
            ],
            const SizedBox(height: 24),
            ImageCropperWidget(
              onImageCropped: (File? imageFile) {
                setState(() {
                  _imageFile =
                      imageFile; // This will be set immediately when image is picked
                  _imageError = imageFile == null;
                });
              },
              isLoading: _isLoading,
              initialImage: _imageFile,
            ),
          ],
        ),
      ),
    );
  }
}
