// =====================================================
// APP FILES AND PACKAGES IMPORT
//======================================================
// Import app models, screens, widgets and services
import 'package:echoeyes/models/settings_model.dart';
import 'package:echoeyes/screens/detection_screen.dart';
import 'package:echoeyes/screens/settings_screen.dart';
import 'package:echoeyes/services/settings_service.dart';
import 'package:echoeyes/services/tts_service.dart';

// App custom font
import 'package:echoeyes/widgets/custom_text.dart';

// Import flutter core => UI MATERIAL DESIGN
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Import plugin to access device camera
import 'package:camera/camera.dart';

// Display splash screen when app starts
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// =====================================================
// STATE CLASS => animation
//======================================================

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late final AnimationController _animationController; // Control all splash animations
  late final Animation<double> _fadeAnimation;         // Control fade-in effect
  late final Animation<double> _scaleAnimation;        // Control zoom-in effect
  late AppSettings _settings;                          // Store current app settings

  @override
  void initState() {
    super.initState();
    _settings = AppSettings(); // Create initial default settings
    _initializeAnimations();   // Prepare splash animations
    _loadSettings();           // Load saved user settings
    _speakInstructions();      // Speak instructions (Instruct gesture feedback)
  }

// =====================================================
// INITIALIZE FADE AND SCALE ANIMATIONS 
//======================================================
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

// =====================================================
// FADE ANIMATION => fade-in effect
//======================================================
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

// =====================================================
// SCALE ANIMATION => zoom-in with bounce effect
//======================================================
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

// =====================================================
// LOAD SAVED SETTINGS AND UPDATE TTS CONFIG
//======================================================

  Future<void> _loadSettings() async {
    final saved = await SettingsService.loadSettings();
    setState(() => _settings = saved);          // Update local state with saved settings
    await TTSService.updateSettings(_settings); // Apply settings to TTS engine

    _speakInstructions();                       // Speak instruction after settings are ready
  }

// =====================================================
// GESTURE FEEDBACK'S INSTRUCTION => TTS
//======================================================
  Future<void> _speakInstructions() async {
    await Future.delayed(const Duration(milliseconds: 500));
    //await TTSService.speak("Double tap to start detection");
  }

  // CAMERA BUTTON IS CLICKED TTS
  Future<void> _openCamera() async {
    await TTSService.speak("Opening camera");

    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // Fetch available cameras
    final cameras = await availableCameras();

    if (!mounted) return;
    Navigator.pop(context); // Close 'loading'


    // Navigate to detection_screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetectionScreen(camerass: cameras, settings: _settings),
      ),
    );
  }

// =====================================================
// SETTINGS BUTTON IS CLICKED TTS
//======================================================
  Future<void> _openSettings() async {
    await TTSService.speak("Opening settings");

    final loaded = await SettingsService.loadSettings();
    // Navigate to settings_screen
    final result = await Navigator.push(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(builder: (_) => SettingsScreen(settings: loaded)),
    );
    // Apply new updated settings when returned
    if (result != null && mounted) {
      setState(() => _settings = result);
      await SettingsService.saveSettings(_settings);
      //await TTSService.updateSettings(_settings); //NO NEED
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    // Allow gestures anywhere on screen => Double-Tap
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      // Make sure button still works even adding gesture control
      onDoubleTap: _openCamera,

// ========================================================
// UI => background gradient, app icon, title, description
//=========================================================
      child: Scaffold(
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  // SPLASH SCREEN MAIN BACKGROUND
                  Color.fromARGB(255, 255, 255, 255),
                  Color(0xFF95DEFD),
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // SIZED BOX FOR EVERY BUTTON OR TEXT ON SPLASH SCREEN
                            _buildLogo(),
                            const SizedBox(height: 8),
                            Text(
                              // ECHOEYES UNDER LOGO
                              'echoeyes',
                              style: const TextStyle(
                                fontFamily: 'Marcellus',
                                fontWeight: FontWeight.w400,
                                fontSize: 58,
                                color: Color(0xFFA2875B),
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              // TEXT UNDER "ECHOEYES"
                              'Object Detection and Recognition Application for Visually Impaired',
                              style: MyTextStyles.medium.copyWith(
                                fontWeight: FontWeight.w300,
                                fontSize: 16,
                                color: Color(0xFF788293),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 68),
                            _buildButton(width, 'Camera', _openCamera),
                            const SizedBox(height: 20),
                            _buildButton(width, 'Settings', _openSettings),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

// =====================================================
// LOGO IMAGE PATH
//======================================================
  Widget _buildLogo() {
    return Image.asset('assets/images/echoeyes2_logo.png', fit: BoxFit.contain);
  }

// =====================================================
// BUTTON FOR SETTINGS AND CAMERA
//======================================================
  Widget _buildButton(double width, String label, VoidCallback onPressed) {
    return SizedBox(
      width: width * 0.5,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label, style: MyTextStyles.medium.copyWith(fontSize: 16)),
      ),
    );
  }
}