import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'widgets/select_widget.dart';
import 'saved_data_page.dart';
import 'widgets/picture_widget.dart';

class HomePage extends StatelessWidget {
  final List<CameraDescription> cameras;

  const HomePage({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 20),
            const Text(
              'CHROMA',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 50),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Picture'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PictureWidget(cameras: cameras),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.photo),
              label: const Text('Select from Gallery'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SelectWidget(cameras: cameras),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.data_usage),
              label: const Text('Data'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SavedDataPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
