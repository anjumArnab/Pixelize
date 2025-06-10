import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/homepage.dart';

void main() {
  runApp(const Pixelize());
}

// Main App
class Pixelize extends StatelessWidget {
  const Pixelize({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixelize',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          textTheme: GoogleFonts.poppinsTextTheme()),
      home: const Homepage(),
    );
  }
}
