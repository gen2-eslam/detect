import 'package:detection/dio_helper.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';
import 'detect_service.dart';
import 'model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DioHelper.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Insulator Defect Detection',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  ModelOutput? _modelOutput;
  String _result = '';
  String _location = '';
  bool _loading = false;

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _image = File(image.path);
        _loading = true;
      });
      await _getLocation();
      await _detectDefects(image.path);
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _image = File(image.path);
        _loading = true;
      });
      await _getLocation();
      await _detectDefects(image.path);
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _detectDefects(String imagePath) async {
    FormData data = FormData.fromMap({});
    data.files
        .add(MapEntry('UploadedFile', MultipartFile.fromFileSync(imagePath)));
    var res =
        await DioHelper.postData(url: "/api/Detection/detect", data: data);
    print("prediction: ${res.data}");
    ModelOutput resData = ModelOutput.fromJson(res.data);
    print("resData: $resData");
    // var result = await detectService.detectDefects(imagePath);
    // print("prediction: ${result?.boxes.toString()}");
    setState(() {
      _modelOutput = resData;
      _result =
          resData.boxes.isEmpty ? 'No defects detected' : 'Defects detected';
    });
  }

  Future<void> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _location = 'Location services are disabled.';
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _location = 'Location permissions are denied';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _location = 'Location permissions are permanently denied.';
      });
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark place = placemarks[0];

    setState(() {
      _location = '${place.locality}, ${place.country}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insulator Defect Detection'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _image == null
                  ? const Text('No image selected.')
                  : Stack(
                      children: [
                        Image.file(_image!),
                        if (_modelOutput != null)
                          ..._modelOutput!.boxes.map((box) {
                            return Positioned(
                              left: box.x?.toDouble(),
                              top: box.y?.toDouble(),
                              width: box.width?.toDouble(),
                              height: box.height?.toDouble(),
                              child: Container(
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.red, width: 2),
                                ),
                                child: Text(
                                  '${box.label} (${box.confidence?.toStringAsFixed(2)})',
                                  style: const TextStyle(
                                    backgroundColor: Colors.red,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickImageFromGallery,
                child: const Text('Pick Image from Gallery'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _takePhoto,
                child: const Text('Take Photo'),
              ),
              const SizedBox(height: 20),
              _loading ? const CircularProgressIndicator() : Container(),
              const SizedBox(height: 20),
              _modelOutput != null
                  ? Column(
                      children: _modelOutput!.boxes.map((box) {
                        return Column(
                          children: [
                            Text(
                              'Label: ${box.label}, Confidence: ${box.confidence?.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              'Bounding Box: (${box.x?.toStringAsFixed(2)}, ${box.y?.toStringAsFixed(2)}), (${box.width?.toStringAsFixed(2)}, ${box.height?.toStringAsFixed(2)})',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        );
                      }).toList(),
                    )
                  : Container(),
              const SizedBox(height: 20),
              Text(
                _result,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                'Location: $_location',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
