import 'dart:io';
import 'package:flutter/material.dart';
import 'widgets/predict_widget.dart';
import 'home_page.dart';
import 'results_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';

class ReviewPage extends StatefulWidget {
  final List<String> imagePaths;
  final List<CameraDescription> cameras;

  const ReviewPage(
      {super.key, required this.imagePaths, required this.cameras});

  @override
  ReviewPageState createState() => ReviewPageState();
}

class ReviewPageState extends State<ReviewPage> {
  late List<String> imagePaths;
  bool isPredicting = false;

  @override
  void initState() {
    super.initState();
    imagePaths = widget.imagePaths;
    if (imagePaths.isEmpty) {
      _takePicture();
    }
  }

  Future<void> _takePicture() async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null && mounted) {
      setState(() {
        imagePaths = [pickedFile.path];
      });
    } else if (mounted) {
      Navigator.pop(context);
    }
  }

  void _navigateToResults(List<Map<String, dynamic>> predictedColors) {
    if (!mounted) return;
    setState(() {
      isPredicting = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsPage(
          imagePaths: imagePaths,
          predictedResults: predictedColors
              .map((e) => double.tryParse(e["Predicted pH"].toString()) ?? 0.0)
              .toList(),
          cameras: widget.cameras,
        ),
      ),
    );
  }

  void _startPrediction() {
    if (!mounted) return;
    setState(() {
      isPredicting = true;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PredictWidget(
          imagePaths: imagePaths,
          onPredicted: _navigateToResults,
        ),
      ),
    );
  }

  Future<void> _selectAgain() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null && mounted) {
      setState(() {
        imagePaths = [image.path];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Review Image"),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: imagePaths.isNotEmpty
            ? Stack(
                children: [
                  Positioned.fill(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 300,
                          child: Center(
                            child:
                                Image.file(File(imagePaths.first), width: 200),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (isPredicting)
                          const Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 10),
                              Text("Predicting... Please wait"),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.home),
                                label: const Text("Home"),
                                onPressed: () {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          HomePage(cameras: widget.cameras),
                                    ),
                                    (route) => false,
                                  );
                                },
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.image),
                                label: const Text("Select Again"),
                                onPressed: _selectAgain,
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.analytics),
                                label: const Text("Predict"),
                                onPressed:
                                    isPredicting ? null : _startPrediction,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
