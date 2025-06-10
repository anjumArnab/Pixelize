import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get_storage/get_storage.dart';
import '../screens/homepage.dart';

void main() async {
  await GetStorage.init();
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
          textTheme: GoogleFonts.poppinsTextTheme()),
      home: const Homepage(),
    );
  }
}
