import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:developer';
import 'package:image/image.dart' as img;
import 'package:color_models/color_models.dart';
import '../ml_model.dart';

class PredictWidget extends StatefulWidget {
  final List<String> imagePaths;
  final Function(List<Map<String, dynamic>>) onPredicted;

  const PredictWidget({
    super.key,
    required this.imagePaths,
    required this.onPredicted,
  });

  @override
  PredictWidgetState createState() => PredictWidgetState();
}

class PredictWidgetState extends State<PredictWidget> {
  List<Map<String, dynamic>> _featuresList = [];
  bool _isPredicting = true;
  late MLModel _mlModel;

  @override
  void initState() {
    super.initState();
    _mlModel = MLModel();
    _predictFeaturesForAllImages();
  }

  @override
  void dispose() {
    _mlModel.close();
    super.dispose();
  }

  Future<void> _predictFeaturesForAllImages() async {
    List<Map<String, dynamic>> extractedFeatures = [];

    for (String imagePath in widget.imagePaths) {
      Map<String, dynamic>? features =
          await _predictAverageFeatures(File(imagePath));
      if (features != null) {
        double predictedPH = await _mlModel.predict(
          double.parse(features["a"]),
          double.parse(features["V"]),
          double.parse(features["b"]),
          double.parse(features["S"]),
        );

        features["Predicted pH"] = predictedPH.toStringAsFixed(4);
        extractedFeatures.add(features);
      }
    }

    if (mounted) {
      setState(() {
        _featuresList = extractedFeatures;
        _isPredicting = false;
      });
      widget.onPredicted(_featuresList);
    }
  }

  Future<Map<String, dynamic>?> _predictAverageFeatures(File imageFile) async {
    log("🔍 Predicting features from: ${imageFile.path}");

    Uint8List imageBytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) {
      log("❌ Failed to decode image");
      return null;
    }

    int width = image.width;
    int height = image.height;
    int validPixelCount = 0;

    log("✅ Image Loaded: ${width}x$height");

    double sumA = 0, sumV = 0, sumB = 0, sumS = 0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        img.Pixel pixel = image.getPixelSafe(x, y);

        int r = pixel.r.toInt().clamp(0, 255);
        int g = pixel.g.toInt().clamp(0, 255);
        int b = pixel.b.toInt().clamp(0, 255);

        if (r == 0 && g == 0 && b == 0) continue;

        validPixelCount++;

        RgbColor rgbColor = RgbColor(r, g, b);
        LabColor labColor = rgbColor.toLabColor();
        HsbColor hsbColor = rgbColor.toHsbColor();

        sumA += labColor.a;
        sumV += hsbColor.brightness;
        sumB += labColor.b;
        sumS += hsbColor.saturation;
      }
    }

    if (validPixelCount == 0) {
      log("⚠️ No valid pixels found.");
      return null;
    }

    return {
      "imagePath": imageFile.path,
      "a": (sumA / validPixelCount).toStringAsFixed(4),
      "V": (sumV / validPixelCount).toStringAsFixed(4),
      "b": (sumB / validPixelCount).toStringAsFixed(4),
      "S": (sumS / validPixelCount).toStringAsFixed(4),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Predict Features")),
      body: _isPredicting
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _featuresList.length,
              itemBuilder: (context, index) {
                Map<String, dynamic> features = _featuresList[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Image.file(File(features["imagePath"]),
                          height: 200, fit: BoxFit.contain),
                      const SizedBox(height: 10),
                      ...features.entries
                          .where((entry) => entry.key != "imagePath")
                          .map((entry) => Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 8),
                                child: Text(
                                  "${entry.key}: ${entry.value}",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              )),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
