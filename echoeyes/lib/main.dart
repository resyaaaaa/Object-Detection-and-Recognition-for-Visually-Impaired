import 'package:echoeyes/screens/splash_screen.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EchoEyesApp());
}

class EchoEyesApp extends StatelessWidget {
  const EchoEyesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return (MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    ));
  }
}
