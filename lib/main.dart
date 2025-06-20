import 'package:flutter/material.dart';
import 'package:speedy/screens/speed_test_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Speed Test",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyanAccent,
          brightness: Brightness.dark,),
        appBarTheme: AppBarTheme(centerTitle: true),
        useMaterial3: true,
      ),
      home: SpeedTestScreen(),
    );
  }
}
