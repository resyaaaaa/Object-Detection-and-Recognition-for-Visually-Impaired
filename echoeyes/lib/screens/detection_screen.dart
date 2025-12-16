// =====================================================
// APP FILES AND PACKAGES IMPORT
//======================================================
// Import app models, screens, widgets and services
import 'package:echoeyes/models/settings_model.dart';
import 'package:echoeyes/screens/settings_screen.dart';
import 'package:echoeyes/services/settings_service.dart';
import 'package:echoeyes/services/tts_service.dart';
import 'package:echoeyes/widgets/custom_text.dart';

// Import flutter core => UI MATERIAL DESIGN
import 'package:flutter/material.dart';

// Import camera and vision (object detection)
import 'package:camera/camera.dart';
import 'package:flutter_vision/flutter_vision.dart';

// Import UI and TTS 
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_tts/flutter_tts.dart';

// Store all of available camera detected on the device
late List<CameraDescription> cameras;
// Control text-to-speech playback (lang, rate & volume)
late FlutterTts flutterTts;

Set<String> spokenLabels = {};

class DetectionScreen extends StatefulWidget {
  // Store user settings
  final AppSettings settings;
  // Receive camera list from main app
  final List<CameraDescription> camerass;

  const DetectionScreen({
    super.key,
    required this.camerass,
    required this.settings,
  });

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

// =====================================================
// STATE CLASS => HANDLE CAMERA, YOLO AND TTS
//======================================================
class _DetectionScreenState extends State<DetectionScreen> {
 
  final GlobalKey _previewKey = GlobalKey();    // Marks camera preview feed
  
  late CameraController controller;             // Control camera stream
  late FlutterVision vision;                    // Run YOLO detection model
  late List<Map<String, dynamic>> yoloResults;  // Store YOLO detection result
  late AppSettings _settings;                   // Active user settings

  CameraImage? cameraImage;       // Current camera frame

  bool isLoaded = false;                        // Check if the setup is done
  bool isDetecting = false;                     // Check detection on/off flag

  FlashMode _currentFlashMode = FlashMode.off;  // Flashlight state

  static DateTime _lastSpokenTime = DateTime.now();   // Limit speech frequency

// Start camera setup
  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    vision = FlutterVision();                         // Create YOLO engine
    _settings = await SettingsService.loadSettings(); // Load saved settings

    // Select back-camera
    final backCamera = widget.camerass.firstWhere(    
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => widget.camerass[0],
    );
    
    controller = CameraController(backCamera, ResolutionPreset.high); // HIGH-RES camera
    await controller.initialize();                                    // Start camera
    await loadYoloModel();                                            // Load YOLO detection model

    // Setup TTS engine
    flutterTts = FlutterTts();
    await flutterTts.setLanguage(_settings.language);
    await flutterTts.setSpeechRate(_settings.speechRate);
    await flutterTts.setVolume(_settings.speechVolume);
  
  // App is ready
    setState(() {
      isLoaded = true;
      yoloResults = [];
    });
  }

  @override
  void dispose() {
    controller.dispose();     // Release camera
    vision.closeYoloModel();  // Close YOLO model
    super.dispose();
  }

// =====================================================
// LOAD YOLO DETECTION MODEL
//======================================================
  Future<void> loadYoloModel() async {
    await vision.loadYoloModel(
      labels: 'assets/labels/label.txt',
      modelPath: 'assets/best_float32.tflite',
      modelVersion: "yolov8",
      quantization: false,
      numThreads: 1,
      useGpu: false,
    );
  }

  @override
  Widget build(BuildContext context) {

    // Show 'loading' animation while initializing
    if (!isLoaded) {
      return Scaffold(
        body: Center(
          child: const SpinKitChasingDots(color: Color(0xFF95DEFD), size: 50.0),
        ),
      );
    }

    // Main camera and detection_screen
    return Scaffold(
      // APPBAR - return icon & echoeyes title
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
          // CAMERA FRAME -> TO CHANGE VIEW, ETC.
          RepaintBoundary(
            key: _previewKey,
            child: Stack(
              fit: StackFit.expand,
              children: [
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller.value.previewSize?.height,
                    height: controller.value.previewSize?.width,
                    child:
                        // For Auto-Focus when tapped
                        GestureDetector(
                          onTapDown: (details) async {
                            final offset = Offset(
                              details.localPosition.dx /
                                  MediaQuery.of(context).size.width,
                              details.localPosition.dy /
                                  MediaQuery.of(context).size.height,
                            );
                            await controller.setFocusPoint(offset);
                           await controller.setFocusMode(FocusMode.auto);
                          },

                          child: CameraPreview(controller),
                        ),
                  ),
                ),
                // Here's to call the bounding boxes on camera feed
                ...displayBoxesAroundRecognizedObjects(
                  MediaQuery.of(context).size,
                ),
              ],
            ),
          ),

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
                        //await TTSService.speak("Flash on");
                      } else {
                        await controller.setFlashMode(FlashMode.off);
                        setState(() => _currentFlashMode = FlashMode.off);
                        //await TTSService.speak("Flash off");
                      }
                    },
                    child: _circleButton(
                      icon: Icons.flash_on,
                      color: _currentFlashMode == FlashMode.torch
                          ? const Color.fromARGB(255, 247, 195, 5)
                          : Colors.black,
                    ),
                  ),

                  // CAPTURE BUTTON -GESTURE FEEDBACK FOR DETECTION STOP & START
                  GestureDetector(
                    onTap: () async {
                      if (isDetecting) {
                        await stopDetection();
                        await flutterTts.stop();
                        TTSService.clearLabelCache();
                        //await TTSService.speak("Stop detection");
                      } else {
                        await startDetection();
                        //await TTSService.speak("Start detection");
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

                  // GO TO SETTINGS BUTTON
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

// =====================================================
// RUN YOLO MODEL ON CAMERA FRAME --IMPORTANT--
//======================================================
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
    // CHECK IF TIME HAS PASSSED 2S BEFORE ANNOUNCE NEXT LABEL
    if (now.difference(_lastSpokenTime).inMilliseconds > 2000) {
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
            final direction = _getObjectDirection(
              box,
              cameraImage,
              // ignore: use_build_context_synchronously
              MediaQuery.of(context).size,
            );
            await flutterTts.speak("$label is detected $direction");
          } else {
            await flutterTts.speak("$label is detected");
          }
          break;
        }
      }
    }

    //  CLEAR SPOKEN LABELS OR OLD LABELS (USER KEEP UPDATED WITH DETECTED OBJECT LABEL)
    spokenLabels.removeWhere(
      (label) =>
          now.difference(_lastSpokenTime).inMilliseconds >
          2000, // LASTSPOKENTIME ABOVE IS 2000 MS/4S
    );

    // DETECTION FRAME OR BOUNDING BOX DELAY DURATION
    setState(() {
      yoloResults = result; // Detection result
    });
    await Future.delayed(const Duration(milliseconds: 2000));
  }

// =====================================================
// START CAMERA STREAM AND OBJECT DETECTION
//======================================================
  Future<void> startDetection() async {
    setState(() => isDetecting = true);
    if (controller.value.isStreamingImages) return;

    await controller.startImageStream((image) async {
      if (isDetecting) {
        cameraImage = image;
        await yoloOnFrame(image); // Detect object
      }
    });
  }

// =====================================================
// STOP OBJECT DETECTION
//======================================================
  Future<void> stopDetection() async {
    setState(() {
      isDetecting = false;
      // Clear detection result (STOP FROM DETECTING OBJECT)
      //yoloResults.clear(); // Off to for testing=> screenshots purposes
    });
  }

// =====================================================
// DIRECTION MODE => LEFT, AHEAD OR RIGHT
//======================================================
  String _getObjectDirection(
    List<dynamic> box,
    CameraImage cameraImage,
    Size previewSize,
  ) {
    double frameWidth = previewSize.width / cameraImage.height;
    double centerX = ((box[0] + box[2]) / 2.0) * frameWidth; // To determine the center ==> bject's centerX


    double dirSection =
        previewSize.width / 3.0; // divide frame into 3 vertical sections

    if (centerX < dirSection) {
      return "on the left";
    } else if (centerX > 2 * dirSection) {
      return "on the right";
    } else {
      return "ahead";
    }
  } 

// =====================================================
// BOUNDING BOXES => FRAME, LABEL COLOR, TAG, ETC
//======================================================
 
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
            border: Border.all(color: Colors.cyanAccent.shade400, width: 2),
          ),
          child: Text(
            "${result['tag']} ${result['box'][4].toStringAsFixed(2)}", // Return 2 decimal
            style: MyTextStyles.semiBold.copyWith(
              background: Paint()..color = Colors.cyanAccent.shade400,
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      );
    }).toList();
  } // CLOSE BOUNDING BOXES
}