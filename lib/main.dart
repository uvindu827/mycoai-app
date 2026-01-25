import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

void main() {
  runApp(const MushroomApp());
}

class MushroomApp extends StatelessWidget {
  const MushroomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const MushroomClassifier(),
      theme: ThemeData(primarySwatch: Colors.green),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MushroomClassifier extends StatefulWidget {
  const MushroomClassifier({super.key});

  @override
  State<MushroomClassifier> createState() => _MushroomClassifierState();
}

class _MushroomClassifierState extends State<MushroomClassifier> {
  File? _image;
  List<String>? _labels;
  Interpreter? _interpreter;
  String _result = "";
  bool _isAnalyzing = false;

  // Constants based on your model training
  static const int inputSize = 224;

  @override
  void initState() {
    super.initState();
    _loadModel();
    _loadLabels();
  }

  Future<void> _loadModel() async {
    try {
      // Load the model from assets
      _interpreter = await Interpreter.fromAsset(
        'assets/mushroom_model.tflite',
      );
      print("Model loaded successfully");
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  Future<void> _loadLabels() async {
    try {
      final labelData = await rootBundle.loadString('assets/labels.txt');
      setState(() {
        _labels = labelData.split('\n').where((s) => s.isNotEmpty).toList();
      });
    } catch (e) {
      print("Error loading labels: $e");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _result = "";
      });
      _analyzeImage(File(pickedFile.path));
    }
  }

  Future<void> _analyzeImage(File imageFile) async {
    if (_interpreter == null || _labels == null) {
      setState(() => _result = "Model not initialized.");
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      // 1. Read and decode the image
      final imageData = await imageFile.readAsBytes();
      final image = img.decodeImage(imageData);

      if (image == null) return;

      // 2. Resize image to 224x224 (model requirement)
      final resizedImage = img.copyResize(
        image,
        width: inputSize,
        height: inputSize,
      );

      // 3. Convert image to input tensor format [1, 224, 224, 3]
      // Note: If your model expects 0-1 range, divide pixel values by 255.0
      var input = List.generate(
        1,
        (i) => List.generate(
          inputSize,
          (y) => List.generate(inputSize, (x) {
            final pixel = resizedImage.getPixel(x, y);
            // Extract RGB channels
            return [pixel.r.toDouble(), pixel.g.toDouble(), pixel.b.toDouble()];
          }),
        ),
      );

      // 4. Create output buffer (shape depends on number of classes)
      // Assuming output is [1, num_classes]
      var output = List.filled(
        1 * _labels!.length,
        0.0,
      ).reshape([1, _labels!.length]);

      // 5. Run Inference
      _interpreter!.run(input, output);

      // 6. Parse Results
      List<double> probabilities = List<double>.from(output[0]);
      int maxIndex = 0;
      double maxProb = 0.0;

      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          maxIndex = i;
        }
      }

      setState(() {
        _result =
            "${_labels![maxIndex]}\nConfidence: ${(maxProb * 100).toStringAsFixed(1)}%";
      });
    } catch (e) {
      setState(() => _result = "Error analyzing: $e");
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "🍄Mushroom Identifier",
          style: TextStyle(fontSize: 35),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        color: Colors.black87,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_image != null)
                Image.file(_image!, height: 300)
              else
                const Icon(Icons.image_search, size: 100, color: Colors.tealAccent),
        
              const SizedBox(height: 20),
        
              Text(
                _result,
                style: const TextStyle( color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
        
              if (_isAnalyzing) const CircularProgressIndicator(),
        
              const SizedBox(height: 30),
        
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera, size: 24),
                    label: const Text(
                      "Camera",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 194, 194, 8), // Button color
                      foregroundColor: Colors.white, // Text and Icon color
                      elevation: 5, // A subtle shadow
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      shape: const StadiumBorder(), // Makes it pill-shaped
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo),
                    label: const Text(
                      "Gallery",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 171, 51, 21), // Button color
                      foregroundColor: Colors.white, // Text and Icon color
                      elevation: 5, // A subtle shadow
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      shape: const StadiumBorder(), // Makes it pill-shaped
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
