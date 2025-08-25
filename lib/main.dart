import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/export_img_page.dart';
import 'screens/resize_img_page.dart';
import 'screens/compress_img_page.dart';
import 'screens/convert_img_page.dart';
import 'screens/crop_img_page.dart';
import '../screens/homepage.dart';

void main() async {
  runApp(const Pixelize());
}

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
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      initialRoute: '/home',
      routes: {
        '/home': (context) => const Homepage(),
        '/compress': (context) => const CompressImagePage(),
        '/crop': (context) => const CropImagePage(),
        '/convert': (context) => const ConvertImagePage(),
        '/resize': (context) => const ResizeImagePage(),
        '/export': (context) => const ExportImagePage(),
      },
    );
  }
}
