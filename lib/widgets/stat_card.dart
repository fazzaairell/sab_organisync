import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;
  final Color backgroundColor;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: accentColor.withOpacity(0.8),
              )),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: accentColor,
              )),
        ],
      ),
    );
  }
}
