import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await availableCameras();

  runApp(ColorExtractionApp(cameras: cameras));
}

class ColorExtractionApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const ColorExtractionApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Color Extractor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: HomePage(cameras: cameras),
    );
  }
}
