import 'package:camera/camera.dart';
import 'package:echoeyes/models/settings_model.dart';
import 'package:echoeyes/screens/detection_screen.dart';
import 'package:echoeyes/screens/settings_screen.dart';
import 'package:echoeyes/services/settings_service.dart';
import 'package:echoeyes/services/tts_service.dart';
import 'package:echoeyes/widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = AppSettings();
    _initializeAnimations();
    _loadSettings();
    _speakInstructions();
  }
  /// ANIMATION FOR SMOOTH TRANSITION 
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  Future<void> _loadSettings() async {
    final saved = await SettingsService.loadSettings();
    setState(() => _settings = saved);
    await TTSService.updateSettings(_settings);

    _speakInstructions();
  }

  Future<void> _speakInstructions() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await TTSService.speak(
      "Double tap to start detection",
    );
  }

  Future<void> _openCamera() async {
    await TTSService.speak("Opening camera");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final cameras = await availableCameras();

    if (!mounted) return;
    Navigator.pop(context);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => YoloCam(camerass: cameras, settings: _settings),
      ),
    );
  }

  Future<void> _openSettings() async {
    await TTSService.speak("Opening settings");

    final loaded = await SettingsService.loadSettings();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SettingsScreen(settings: loaded)),
    );

    if (result != null && mounted) {
      setState(() => _settings = result);
      await SettingsService.saveSettings(_settings);
      await TTSService.updateSettings(_settings);
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

    //Here to modify the bg color for splash screen
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      //in order the button still works even adding gesture control
      onDoubleTap: _openCamera,

      child: Scaffold(
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromARGB(255, 255, 255, 255),
                  Color.fromARGB(255, 149, 222, 253),
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
                            _buildLogo(),
                            const SizedBox(height: 40),
                            Text(
                              'echoeyes',
                              style: const TextStyle(
                                fontFamily: 'Quattrocento',
                                fontWeight: FontWeight.w400,
                                fontSize: 46,
                                color: Color(0xFF8DA0A8),
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Object Detection and Recognition Application for Visually Impaired',
                              style: MyTextStyles.semiBold.copyWith(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 50),
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

  //LOGO --->
  Widget _buildLogo() {
    return Image.asset('assets/images/echoeyes_logo.png', fit: BoxFit.contain);
  }

  //BUTTON FOR SETTINGS&CAMERA --->
  Widget _buildButton(double width, String label, VoidCallback onPressed) {
    return SizedBox(
      width: width * 0.7,
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
        child: Text(label, style: MyTextStyles.semiBold.copyWith(fontSize: 20)),
      ),
    );
  }
}
