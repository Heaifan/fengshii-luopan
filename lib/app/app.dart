import 'package:flutter/material.dart';
import '../features/compass/compass_page.dart';

class BazhaiCompassApp extends StatelessWidget {
  const BazhaiCompassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '测向工具',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ),
      ),
      home: const CompassPage(),
    );
  }
}
