import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final EdgeInsetsGeometry padding;

  const SectionTitle({super.key, required this.title, this.padding = const EdgeInsets.only(bottom: 12)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          )),
    );
  }
}
