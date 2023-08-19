import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite/tflite.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  String selectedImagePath = '';
  bool imageSubmitted = false;
  List<dynamic> recognitions = [];

  late List<String> labelList;

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> loadModel() async {
    String modelPath = 'assets/your_model.tflite'; // Update the path
    String labelsPath = 'assets/labels.txt'; // Update the path

    await Tflite.loadModel(
      model: modelPath,
      labels: labelsPath,
    );

    String labelsContent = await rootBundle.loadString(labelsPath);
    labelList = labelsContent.split('\n');
  }

  Future<void> runModelOnImage(String imagePath) async {
    recognitions = await Tflite.runModelOnImage(
      path: imagePath,
      numResults: labelList.length,
      threshold: 0.1,
    ) as dynamic;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 254, 75, 25),
        appBar: AppBar(
          title: const Text('Butterfly Classifier'),
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/bg.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Column(
                children: [
                  SizedBox(height: 20), // Add margin

                  if (imageSubmitted && recognitions.isNotEmpty)
                    Text(
                      'Prediction: ${labelList[recognitions[0]['index']] ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            margin: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white,
                            ),
                            padding: const EdgeInsets.all(10),
                            child: selectedImagePath == ''
                                ? Image.asset(
                                    'assets/image_placeholder.png',
                                    height: 200,
                                    width: 200,
                                    fit: BoxFit.fill,
                                  )
                                : Image.file(
                                    File(selectedImagePath),
                                    height: 200,
                                    width: 200,
                                    fit: BoxFit.fill,
                                  ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () async {
                              await _showImageSelectionDialog();
                            },
                            child: const Text('Select Image'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      selectedImagePath =
                          await selectImageFromCamera() as String;
                      setState(() {});
                    },
                    child: const Text('Take Picture'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      selectedImagePath =
                          await selectImageFromGallery() as String;
                      setState(() {});
                    },
                    child: const Text('Upload from Gallery'),
                  ),
                ],
              ),
              Column(
                children: recognitions.map((result) {
                  int labelIndex = result['index'];
                  String className = labelList[labelIndex];
                  double confidence = result['confidence'];

                  return Column(
                    children: [
                      Text(
                        'Prediction: $className',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color.fromARGB(255, 239, 215, 137),
                        ),
                      ),
                      Text(
                        'Confidence: $confidence',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> selectImageFromGallery() async {
    XFile? file = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 10);
    return file?.path;
  }

  Future<String?> selectImageFromCamera() async {
    XFile? file = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 10);
    return file?.path;
  }

  Future<void> _showImageSelectionDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Image Selection'),
          content: const Text('Do you want to use this image?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                setState(() {
                  imageSubmitted = true;
                });
                runModelOnImage(selectedImagePath); // Call the function here
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}
