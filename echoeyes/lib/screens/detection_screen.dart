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

Offset _dragPosition = const Offset(65, 30);
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
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
          ...displayBoxesAroundRecognizedObjects(MediaQuery.of(context).size),
          buildLiveDetectionBox(),

          Positioned(
            bottom: 45,
            width: MediaQuery.of(context).size.width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Flash button
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
                    color: Colors.yellow,
                  ),
                ),

                // Detection start/stop
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
                      border: Border.all(color: Colors.grey.shade400, width: 3),
                    ),
                    child: Icon(
                      isDetecting ? Icons.pause : Icons.play_arrow,
                      color: Colors.black,
                      size: 35,
                    ),
                  ),
                ),

                // Settings button
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(settings: _settings),
                      ),
                    );
                    TTSService.speak("Settings");
                  },
                  child: _circleButton(
                    icon: Icons.settings,
                    color: Colors.black87,
                  ),
                ),
              ],
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

        // Distance alerts
        if (_settings.distanceAlerts) {
          final double width = (box[2] - box[0]).toDouble();
          final double height = (box[3] - box[1]).toDouble();
          if (width > cameraImage.width * 0.4 &&
              height > cameraImage.height * 0.4) {
            await flutterTts.speak("$label is very close");
            _lastSpokenTime = now;
            break;
          }
        }

        if (!spokenLabels.contains(label)) {
          spokenLabels.add(label);
          _lastSpokenTime = now;
          await flutterTts.awaitSpeakCompletion(true);

          if (_settings.directionMode) {
            final direction = _getObjectDirection(box, cameraImage);
            await flutterTts.speak("$label is detected on the $direction");
          } else {
            await flutterTts.speak("$label is detected");
          }
          break;
        }
      }
    }

    spokenLabels.clear();

    setState(() => yoloResults = result);
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
            border: Border.all(color: Colors.lightBlueAccent, width: 2),
          ),
          child: Text(
            "${result['tag']} ${(result['box'][4] * 100).toStringAsFixed(1)}",
            style: MyTextStyles.semiBold.copyWith(
              background: Paint()..color = const Color(0x800410F2),
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget buildLiveDetectionBox() {
    return Positioned(
      left: _dragPosition.dx,
      top: _dragPosition.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() => _dragPosition += details.delta);
        },
        child: Container(
          constraints: const BoxConstraints(minWidth: 250, maxWidth: 400),
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(179, 186, 190, 1).withAlpha(25),
            border: Border.all(color: Colors.blue.shade100, width: 2),
          ),
          child: yoloResults.isEmpty
              ? Text(
                  'No Object Detected',
                  style: MyTextStyles.semiBold.copyWith(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: yoloResults.map((result) {
                    final tag = result['tag'];
                    final conf = (result['box'][4] * 100).toStringAsFixed(2);
                    return Text(
                      '$tag: $conf%',
                      style: MyTextStyles.semiBold.copyWith(
                        color: Colors.white,
                        fontSize: 26,
                      ),
                    );
                  }).toList(),
                ),
        ),
      ),
    );
  }

  /// Circle logic for direction mode
  String _getObjectDirection(List box, CameraImage image) {
    final double centerX = (box[0] + box[2]) / 2;
    final double imageWidth = image.width.toDouble();

    if (centerX < imageWidth * 0.33) {
      return "left";
    } else if (centerX > imageWidth * 0.66) {
      return "right";
    } else {
      return "in front";
    }
  }
}
