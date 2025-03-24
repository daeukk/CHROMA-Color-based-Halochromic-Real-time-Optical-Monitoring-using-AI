import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../review_page.dart';
import 'package:camera/camera.dart';

class SelectWidget extends StatefulWidget {
  final List<CameraDescription> cameras;

  const SelectWidget({super.key, required this.cameras});

  @override
  State<SelectWidget> createState() => _SelectWidgetState();
}

class _SelectWidgetState extends State<SelectWidget> {
  @override
  void initState() {
    super.initState();
    pickImages();
  }

  Future<void> pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null && mounted) {
        List<String> imagePaths = [image.path];
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ReviewPage(
              imagePaths: imagePaths,
              cameras: widget.cameras,
            ),
          ),
        );
      } else if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No image selected")),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error selecting image: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
