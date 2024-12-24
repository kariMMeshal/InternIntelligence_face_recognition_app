import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:ui' as ui;

class ChooseOrCapture extends StatefulWidget {
  const ChooseOrCapture({super.key});

  @override
  State<ChooseOrCapture> createState() => _ChooseOrCaptureState();
}

class _ChooseOrCaptureState extends State<ChooseOrCapture> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  List<Face> _faces = [];
  ui.Image? _imageUi;

  // Choose Image from gallery
  Future<void> chooseImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final File imageFile = File(image.path);
      await detectFaces(imageFile);
    }
  }

  // Detect faces using Google ML Kit
  Future<void> detectFaces(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableLandmarks: true,
        enableClassification: true,
      ),
    );

    final List<Face> faces = await faceDetector.processImage(inputImage);

    setState(() {
      _image = imageFile;
      _faces = faces;
    });

    await loadImage(imageFile);
  }

  // Load the image into memory for display
  Future<void> loadImage(File file) async {
    final data = await file.readAsBytes();
    await decodeImageFromList(data).then((value) {
      setState(() {
        _imageUi = value;
      });
    });
  }

  // Capture image from camera
  Future<void> captureImage() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      final File imageFile = File(photo.path);
      await detectFaces(imageFile);
    }
  }

  // Clear the image and reset faces
  void clearImage() {
    setState(() {
      _image = null;
      _faces = [];
      _imageUi = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Face Recognition App',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF06402b),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display number of faces detected above the image
            // if (_faces.isNotEmpty) 
              Text(
                'Faces Detected: ${_faces.length}',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            _image != null
                ? SizedBox(
                    width: 300, 
                    height: 300, 
                    child: CustomPaint(
                      painter: _imageUi != null
                          ? FacePainter(_imageUi!, _faces)
                          : null,
                    ),
                  )
                : const Icon(Icons.image, size: 150),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: captureImage,
                  child: const Text(
                    'Capture From Camera',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  onPressed: chooseImage,
                  child: const Text(
                    'Choose From Gallery',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: clearImage,
              child: const Text(
                'Clear Image',
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  final ui.Image image;
  final List<Face> faces;

  FacePainter(this.image, this.faces);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.red;

    // Adjust the image size to fit inside the custom paint bounds
    final imageRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        imageRect,
        Paint());

    // Calculate scaling factor for bounding box
    double scaleX = size.width / image.width.toDouble();
    double scaleY = size.height / image.height.toDouble();

    // Draw the face bounding boxes
    for (var face in faces) {
      final boundingBox = face.boundingBox;

      // Scale the bounding box to fit the image inside the CustomPainter
      final scaledBoundingBox = Rect.fromLTRB(
        boundingBox.left * scaleX,
        boundingBox.top * scaleY,
        boundingBox.right * scaleX,
        boundingBox.bottom * scaleY,
      );

      canvas.drawRect(scaledBoundingBox, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
