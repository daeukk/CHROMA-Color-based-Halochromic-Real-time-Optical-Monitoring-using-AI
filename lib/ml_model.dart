import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:developer' as dev;

class MLModel {
  late Interpreter _interpreter;

  MLModel() {
    _loadModel();
  }

  Future<void> _loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/model/mlp_model.tflite');
  }
//replace mlp_model with others to load different model

  Future<double> predict(double a, double V, double b, double S) async {
    final stopwatch = Stopwatch()..start();

    List<List<double>> input = [
      [a, V, b, S]
    ];
    List<List<double>> output =
        List.generate(1, (index) => List.filled(1, 0.0));

    _interpreter.run(input, output);
    stopwatch.stop();

    double inferenceTime = stopwatch.elapsedMicroseconds / 1000.0;
    double throughput = inferenceTime > 0 ? 1000 / inferenceTime : 0;

    dev.log("Inference Performance Metrics:");
    dev.log("Inference Time: ${inferenceTime.toStringAsFixed(3)} ms");
    dev.log("Throughput: ${throughput.toStringAsFixed(2)} inferences/sec");

    return double.parse(output[0][0].toStringAsFixed(1));
  }

  void close() {
    _interpreter.close();
  }
}
