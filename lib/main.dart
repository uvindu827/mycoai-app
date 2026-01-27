import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;


void main(){
  runApp (const MushroomApp());
}

class MushroomApp extends StatelessWidget {
  const MushroomApp({ super.key });

  @override
  Widget build(BuildContext context){
    return MaterialApp(
      home: const MushroomClassifier(),
      theme: ThemeData(primaryColor: Colors.green),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MushroomClassifier extends StatefulWidget {
  const MushroomClassifier({ Key? key }) : super(key: key);

  @override
  _MushroomClassifierState createState() => _MushroomClassifierState();
}

class _MushroomClassifierState extends State<MushroomClassifier> {

  //defining interpreter variable which holds the model
  //before loads model is null
  Interpreter? _interpreter;

  //defining labels
  //nullable before loads
  List<String>? _labels;

  //defining image file to store uploading image
  //nullable until image is selected
  File? _image;

  String _result = "Select an image";
  bool _isAnalysing = false;

  static const int inputSize = 224;

  void initState() {
    super.initState();

    _loadModel();
    _loadLabels();
  }


  //load model from assets
  Future<void> _loadModel() async {
    try {

      _interpreter = await Interpreter.fromAsset(
        'assets/mushroom_model.tflite'
      );
    } catch (e) {
        print("Error loading model: $e");
    }
  } 

  //load labels.txt from assets
  Future<void> _loadLabels() async {
    try {
      
      final labelData = await rootBundle.loadString('assets/labels.txt');
      setState(() {
        _labels = labelData.split('\n').where((s) => s.isNotEmpty).toList();
      });

    } catch (e) {
      setState(() {
        print("Error loading labels: $e");
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if(pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _result = "Analysing...";
      });

      _analyseImage(File(pickedFile.path));

    }
  }

  Future<void> _analyseImage(File imageFile) async {
    if(_interpreter ==null || _labels == null) {
      setState(() {
        _result = "Model or labels not loaded";
      });
    }

    setState(() {
      _isAnalysing = true;
    });

    try {
      //decoding the image
      final imageData = await imageFile.readAsBytes();
      final image = img.decodeImage(imageData);
      if(image == null) return;

      //shrinking image to 224 x 224
      final resizedImage = img.copyResize(
        image,
        width: inputSize,
        height: inputSize
      );

      //Matrix creation
      var input = _buildInputTensor(resizedImage);

      //create outpput tensor
      var output = List.filled(1 * _labels!.length, 0.0).reshape([1, _labels!.length]);

      //run inference
      _interpreter!.run(input, output);

      //interprete results
      List<double> probabilities = List<double>.from(output[0]);
      int maxIndex = 0;
      double maxProb = 0.0;

      for(int i=0; i< probabilities.length; i++) {
        if(probabilities[i] > maxProb){
          maxProb = probabilities[i];
          maxIndex = i;
        }
      }

      setState(() {
        _result = "${_labels![maxIndex]} \n"
        "Confidence: ${(maxProb * 100).toStringAsFixed(2)}%";
      });

    } catch (e) {
      setState(() {
        _result = "Error: $e";
      });
    } finally {
      setState(() {
        _isAnalysing = false;
      });
    }

  }

  //
  List<List<List<List<double>>>> _buildInputTensor(img.Image image){
    return List.generate(1, (_){
      return List.generate(inputSize, (y) {
        return List.generate(inputSize, (x) {
          final pixel = image.getPixel(x, y);

          return [
            pixel.g.toDouble(),
            pixel.b.toDouble(),
            pixel.r.toDouble(),
          ];
        });
      }); 
    });
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
        title: const Text('🍄Mushroom Classifier')
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_image != null) 
              Image.file(_image!, height:300)
            else 
              const Icon(Icons.image, size:100, color: Colors.grey),
            
            const SizedBox(height: 20),

            Text(
              _result,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold
              ),
              textAlign: TextAlign.center,
            ),

            if (_isAnalysing) const CircularProgressIndicator(),

            const SizedBox(height: 30),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera), 
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Camera")
                ),

                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery), 
                  icon: const Icon(Icons.photo),
                  label: const Text("Gallery")
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
