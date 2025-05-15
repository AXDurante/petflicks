import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'post_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;
  final PostService _postService = PostService();
  final ImagePicker _picker = ImagePicker();
  double _uploadProgress = 0.0;
  bool _isUploading = false;
  bool _imageError = false;
  bool _showUrlField = false;
  bool _showUrlPreview = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        if (await file.exists()) {
          setState(() {
            _imageFile = file;
            _imageError = false;
            _showUrlField = false;
            _showUrlPreview = false;
            _urlController.clear();
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

  void _toggleUrlField() {
    setState(() {
      _showUrlField = !_showUrlField;
      if (!_showUrlField) {
        _urlController.clear();
        _showUrlPreview = false;
      }
      if (_showUrlField) {
        _imageFile = null;
      }
    });
  }

  void _checkUrl() {
    if (_urlController.text.isNotEmpty) {
      final urlPattern = RegExp(
        r'^(https?://)?([\w-]+\.)+[\w-]+(/[\w-./?%&=]*)?$',
        caseSensitive: false,
      );
      if (urlPattern.hasMatch(_urlController.text)) {
        setState(() {
          _showUrlPreview = true;
        });
      } else {
        setState(() {
          _showUrlPreview = false;
        });
      }
    } else {
      setState(() {
        _showUrlPreview = false;
      });
    }
  }

  Future<void> _uploadPost() async {
    if (_postController.text.isEmpty &&
        _imageFile == null &&
        _urlController.text.isEmpty) {
      _showErrorMessage(
        'Please enter text, add an image, or provide a URL for your post',
      );
      return;
    }

    if (_imageError) {
      _showErrorMessage('Issue with the image. Try another one.');
      return;
    }

    // Validate URL if provided
    if (_urlController.text.isNotEmpty) {
      final urlPattern = RegExp(
        r'^(https?://)?([\w-]+\.)+[\w-]+(/[\w-./?%&=]*)?$',
        caseSensitive: false,
      );
      if (!urlPattern.hasMatch(_urlController.text)) {
        _showErrorMessage('Please enter a valid URL');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      String? imageUrl;
      String? postUrl =
          _urlController.text.isNotEmpty ? _urlController.text : null;

      if (_imageFile != null) {
        try {
          await _imageFile!.readAsBytes();
        } catch (e) {
          throw Exception('Cannot read image: ${e.toString()}');
        }

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
        url: postUrl,
        context: context,
      );

      _postController.clear();
      _urlController.clear();
      setState(() {
        _imageFile = null;
        _imageError = false;
        _showUrlField = false;
        _showUrlPreview = false;
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
    _urlController.dispose();
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
            if (_imageFile != null && !_imageError) ...[
              const SizedBox(height: 16),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _imageFile!,
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white54,
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.black,
                        ),
                        onPressed: _clearImage,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (_showUrlField) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _urlController,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  hintText: "Enter URL...",
                  hintStyle: TextStyle(color: Colors.black),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link, color: Colors.black),
                ),
                keyboardType: TextInputType.url,
                onChanged: (value) => _checkUrl(),
              ),
            ],
            if (_showUrlPreview) ...[
              const SizedBox(height: 16),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _urlController.text,
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 250,
                          color: Colors.grey.shade200,
                          child: Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 250,
                          color: Colors.grey.shade200,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Could not load image preview',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white54,
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.black,
                        ),
                        onPressed: () {
                          setState(() {
                            _showUrlPreview = false;
                            _urlController.clear();
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed:
                      _isLoading ? null : () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo, color: Colors.white),
                  label: const Text(
                    'Gallery',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed:
                      _isLoading ? null : () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: const Text(
                    'Camera',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _toggleUrlField,
                  icon: const Icon(Icons.link, color: Colors.white),
                  label: Text(
                    _showUrlField ? 'Remove URL' : 'Add URL',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
