import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';


void main(){
  runApp (const MushroomApp());
}

class MushroomApp extends StatelessWidget {
  const MushroomApp({ super.key });

  @override
  Widget build(BuildContext context){
    return MaterialApp(
      home: const MushroomInitializer(),
      theme: ThemeData(primaryColor: Colors.green),
    );
  }
}

class MushroomInitializer extends StatefulWidget {
  const MushroomInitializer({ Key? key }) : super(key: key);

  @override
  _MushroomInitializerState createState() => _MushroomInitializerState();
}

class _MushroomInitializerState extends State<MushroomInitializer> {

  //defining interpreter variable which holds the model
  //before loads model is null
  Interpreter? _interpreter;

  //defining labels
  //nullable before loads
  List<String>? _labels;

  //defining status to keep track of the process
  String _status = 'Initializing Model';

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

      setState(() {
        _status = 'Model Loaded Successfully';
      });

    } catch (e) {
      setState(() {
        _status = 'Error loading model: $e';
      });
    }
  } 

  //load labels.txt from assets
  Future<void> _loadLabels() async {
    try {
      
      final labelData = await rootBundle.loadString('assets/labels.txt');
      setState(() {
        _labels = labelData.split('\n').where((s) => s.isNotEmpty).toList();
      });

      setState(() {
        _status = "System Ready\n\n"
        "Input shape: ${_interpreter!.getInputTensor(0).shape}\n"
        "Output shape: ${_interpreter!.getOutputTensor(0).shape}\n"
        "labels: ${_labels!.length}";
      });

    } catch (e) {
      setState(() {
        _status = 'Error loading labels: $e';
      });
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
      appBar: AppBar(title: const Text('Load model and labels')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            _status,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold
            ),
          ),
        ),
      ),
    );
  }
}
