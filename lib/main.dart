import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const DedoleApp());
}

class DedoleApp extends StatelessWidget {
  const DedoleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'NunitoSans'),
      home: SplashScreen(),
    );
  }
}
