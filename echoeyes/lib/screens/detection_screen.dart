// APP FILES AND PACKAGES IMPORT
import 'package:echoeyes/models/settings_model.dart';
import 'package:echoeyes/screens/settings_screen.dart';
import 'package:echoeyes/services/settings_service.dart';
import 'package:echoeyes/services/tts_service.dart';
import 'package:echoeyes/widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:flutter_tts/flutter_tts.dart';

late List<CameraDescription> cameras;
late FlutterTts flutterTts;

Set<String> spokenLabels = {};

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: Text("EchoEyes starting..."))),
    );
  }
}

class YoloCam extends StatefulWidget {
  final AppSettings settings;
  final List<CameraDescription> camerass;
  const YoloCam({super.key, required this.camerass, required this.settings});

  @override
  State<YoloCam> createState() => _YoloCamState();
}

class _YoloCamState extends State<YoloCam> {
  late CameraController controller;
  late FlutterVision vision;
  late List<Map<String, dynamic>> yoloResults;
  late AppSettings _settings;

  CameraImage? cameraImage;
  bool isLoaded = false;
  bool isDetecting = false;
  FlashMode _currentFlashMode = FlashMode.off;

  static DateTime _lastSpokenTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    vision = FlutterVision();
    _settings = await SettingsService.loadSettings();

    final backCamera = widget.camerass.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => widget.camerass[0],
    );

    controller = CameraController(backCamera, ResolutionPreset.high);
    await controller.initialize();
    await loadYoloModel();

    flutterTts = FlutterTts();
    await flutterTts.setLanguage(_settings.language);
    await flutterTts.setSpeechRate(_settings.speechRate);
    await flutterTts.setVolume(_settings.speechVolume);

    setState(() {
      isLoaded = true;
      yoloResults = [];
    });
  }

  @override
  void dispose() {
    controller.dispose();
    vision.closeYoloModel();
    super.dispose();
  }

  Future<void> loadYoloModel() async {
    await vision.loadYoloModel(
      labels: 'assets/labels/pedestrian12.txt',
      modelPath: 'assets/yolov8n.tflite',
      modelVersion: "yolov8",
      quantization: false,
      numThreads: 1,
      useGpu: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoaded) {
      return const Scaffold(body: Center(child: Text("Loading model...")));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'echoeyes',
          style: MyTextStyles.semiBold.copyWith(
            color: Colors.white,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // CAMERA FEED -> TO CHANGE VIEW, ETC.
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.previewSize?.height,
              height: controller.value.previewSize?.width,
              child: CameraPreview(controller),
            ),
          ),
          ...displayBoxesAroundRecognizedObjects(MediaQuery.of(context).size),

          // NAVBAR, BUTTON @BOTTOM
          Positioned(
            bottom: 0,
            width: MediaQuery.of(context).size.width,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 30),
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.zero,
                  topRight: Radius.zero,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // FLASHLIGHT BUTTON
                  GestureDetector(
                    onTap: () async {
                      if (_currentFlashMode == FlashMode.off) {
                        await controller.setFlashMode(FlashMode.torch);
                        setState(() => _currentFlashMode = FlashMode.torch);
                        await TTSService.speak("Flash on");
                      } else {
                        await controller.setFlashMode(FlashMode.off);
                        setState(() => _currentFlashMode = FlashMode.off);
                        await TTSService.speak("Flash off");
                      }
                    },
                    child: _circleButton(
                      icon: Icons.flash_on,
                      color: _currentFlashMode == FlashMode.torch
                          ? const Color.fromARGB(255, 247, 195, 5)
                          : Colors.black,
                    ),
                  ),

                  // TTS & GESTURE FEEDBACK FOR DETECTION STOP & START
                  GestureDetector(
                    onTap: () async {
                      if (isDetecting) {
                        await stopDetection();
                        await flutterTts.stop();
                        TTSService.clearLabelCache();
                        await TTSService.speak("Stop Detection");
                      } else {
                        await startDetection();
                        await TTSService.speak("Start Detection");
                      }
                    },
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(50),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.grey.shade400,
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        isDetecting ? Icons.pause : Icons.play_arrow,
                        color: Colors.black,
                        size: 35,
                      ),
                    ),
                  ),

                  // SETTINGS BUTTON
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SettingsScreen(settings: _settings),
                        ),
                      );

                      /// RELOAD (GET THE UPDATED SETTINGS)
                      final updatedSettings =
                          await SettingsService.loadSettings();
                      setState(() {
                        _settings = updatedSettings;
                      });
                    },
                    child: _circleButton(
                      icon: Icons.settings,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required Color color}) {
    return Container(
      height: 60,
      width: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 30),
    );
  }
  
  // DETECTION CAMERA
  Future<void> yoloOnFrame(CameraImage cameraImage) async {
    final result = await vision.yoloOnFrame(
      bytesList: cameraImage.planes.map((plane) => plane.bytes).toList(),
      imageHeight: cameraImage.height,
      imageWidth: cameraImage.width,
      iouThreshold: 0.5,
      confThreshold: _settings.confidenceThreshold,
      classThreshold: _settings.confidenceThreshold,
    );

    final now = DateTime.now();
    if (now.difference(_lastSpokenTime).inMilliseconds > 4000) {
      for (var detection in result) {
        final label = detection['tag'].toString();
        final box = detection['box'];
        final double confidence = box[4].toDouble();
        if (confidence < widget.settings.confidenceThreshold) continue;

        // TTS FOR DIRECTIONAL MODE -> LEFT, RIGHT, IN FRONT
        if (!spokenLabels.contains(label)) {
          spokenLabels.add(label);
          _lastSpokenTime = now;
          await flutterTts.awaitSpeakCompletion(true);

          if (_settings.directionMode) {
            final direction = _getObjectDirection(box, cameraImage);
            await flutterTts.speak("$label is detected $direction");
          } else {
            await flutterTts.speak("$label is detected");
          }
          break;
        }
      }
    }

    spokenLabels.removeWhere(
      (label) => now.difference(_lastSpokenTime).inSeconds > 4,
    );

    // TTS DELAY DURATION
    setState(() {
      yoloResults = result;
    });
    await Future.delayed(const Duration(milliseconds: 600));
  }

  Future<void> startDetection() async {
    setState(() => isDetecting = true);
    if (controller.value.isStreamingImages) return;

    await controller.startImageStream((image) async {
      if (isDetecting) {
        cameraImage = image;
        await yoloOnFrame(image);
      }
    });
  }

  Future<void> stopDetection() async {
    setState(() {
      isDetecting = false;
      yoloResults.clear();
    });
  }

  /// LOGIC FOR DIRECTIONAL MODE
  String _getObjectDirection(List<dynamic> box, CameraImage cameraImage) {
    final double centerX = (box[0] + box[2]) / 2.0; // Object's centerX
    final double frameWidth = cameraImage.width
        .toDouble(); // convert frame width to double
    
    final double dirSection =
        frameWidth / 4.0; // divide frame into 4 vertical sections
    
    // DIRECTIOM BASED ON 4 SECTIONS
    final double leftBoundary = dirSection; // LEFT SECTION 1/4
    final double rightBoundary = frameWidth - dirSection; // RIGHT SECTION 4/4

    if (centerX < leftBoundary) {
      return "on the left";
    } else if (centerX > rightBoundary) {
      return "on the right";
    } else {
      return "ahead";
    }
  }

  // BOUNDING BOXES
  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if (yoloResults.isEmpty) return [];

    double factorX = screen.width / (cameraImage?.height ?? 1);
    double factorY = screen.height / (cameraImage?.width ?? 1);

    return yoloResults.map((result) {
      double x = result["box"][0] * factorX;
      double y = result["box"][1] * factorY;
      double w = (result["box"][2] - result["box"][0]) * factorX;
      double h = (result["box"][3] - result["box"][1]) * factorY;

      return Positioned(
        left: x,
        top: y,
        width: w,
        height: h,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            border: Border.all(color: Colors.amber.shade700, width: 2),
          ),
          child: Text(
            "${result['tag']} ${(result['box'][4] * 100).toStringAsFixed(1)}",
            style: MyTextStyles.semiBold.copyWith(
              background: Paint()
                ..color = const Color.fromARGB(255, 231, 147, 1),
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      );
    }).toList();
  }
}
