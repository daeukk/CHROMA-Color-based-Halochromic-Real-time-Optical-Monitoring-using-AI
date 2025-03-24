import 'dart:io';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'database_helper.dart';
import 'package:camera/camera.dart';

class ResultsPage extends StatefulWidget {
  final List<String> imagePaths;
  final List<double> predictedResults;
  final List<CameraDescription> cameras;

  const ResultsPage({
    super.key,
    required this.imagePaths,
    required this.predictedResults,
    required this.cameras,
  });

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  Future<void> _saveToDatabase() async {
    final dbHelper = DatabaseHelper();

    for (int i = 0; i < widget.imagePaths.length; i++) {
      await dbHelper.savePredictedPH(
          widget.imagePaths[i], widget.predictedResults[i]);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Predicted pH values saved successfully!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Predicted pH Results"),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int index = 0; index < widget.imagePaths.length; index++)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                              child: Image.file(
                                File(widget.imagePaths[index]),
                                height: 250,
                                width: double.infinity,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                "Predicted pH: ${widget.predictedResults[index].toStringAsFixed(1)}",
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              color: Colors.transparent,
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
                    icon: const Icon(Icons.save),
                    label: const Text("Save"),
                    onPressed: _saveToDatabase,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
