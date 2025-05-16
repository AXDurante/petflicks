import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class ImageCropperWidget extends StatefulWidget {
  final Function(File?) onImageCropped;
  final bool isLoading;
  final File? initialImage;

  const ImageCropperWidget({
    Key? key,
    required this.onImageCropped,
    required this.isLoading,
    this.initialImage,
  }) : super(key: key);

  @override
  State<ImageCropperWidget> createState() => _ImageCropperWidgetState();
}

class _ImageCropperWidgetState extends State<ImageCropperWidget> {
  File? _pickedFile;
  CroppedFile? _croppedFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.initialImage != null) {
      _pickedFile = widget.initialImage;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_pickedFile != null || _croppedFile != null) _imageCard(),
        if (_pickedFile == null && _croppedFile == null) _uploaderCard(),
      ],
    );
  }

  Widget _imageCard() {
    return Column(
      children: [
        Card(
          elevation: 4.0,
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: _image(),
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        _menu(),
      ],
    );
  }

  Widget _image() {
    if (_croppedFile != null) {
      return Image.file(
        File(_croppedFile!.path),
        fit: BoxFit.contain,
        width: double.infinity,
      );
    } else if (_pickedFile != null) {
      return Image.file(
        _pickedFile!,
        fit: BoxFit.contain,
        width: double.infinity,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _menu() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FloatingActionButton(
          onPressed: _clear,
          backgroundColor: Colors.redAccent,
          mini: true,
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        if (_croppedFile == null) ...[
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: _cropImage,
            backgroundColor: Theme.of(context).primaryColor,
            mini: true,
            child: const Icon(Icons.crop, color: Colors.white),
          ),
        ],
        const SizedBox(width: 16),
        FloatingActionButton(
          onPressed: _uploadImage,
          backgroundColor: Theme.of(context).primaryColor,
          mini: true,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ],
    );
  }

  Widget _uploaderCard() {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: SizedBox(
        width: double.infinity,
        height: 200.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: Theme.of(context).highlightColor.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.image,
                          color: Theme.of(context).highlightColor,
                          size: 48.0,
                        ),
                        const SizedBox(height: 16.0),
                        Text(
                          'Upload an image to start',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium!.copyWith(
                            color: Theme.of(context).highlightColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: ElevatedButton(
                onPressed: _uploadImage,
                child: const Text('Upload Image'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cropImage() async {
    if (_pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: _pickedFile!.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
        ],
      );
      if (croppedFile != null) {
        final file = File(croppedFile.path);
        setState(() {
          _croppedFile = croppedFile;
        });
        // Send the cropped file to parent
        widget.onImageCropped(file);
      } else {
        // If user cancels cropping, keep the original file
        widget.onImageCropped(_pickedFile!);
      }
    }
  }

  Future<void> _uploadImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      setState(() {
        _pickedFile = file;
        _croppedFile = null;
      });
      // Immediately send the original file to parent
      widget.onImageCropped(file);
    }
  }

  void _clear() {
    setState(() {
      _pickedFile = null;
      _croppedFile = null;
    });
    widget.onImageCropped(null);
  }
}
