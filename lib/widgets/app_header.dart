import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;

  const AppHeader({super.key, required this.title, required this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6C3CBC),
                  )),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  )),
            ],
          ),
        ),
        if (action != null) ...[
          const SizedBox(width: 12),
          action!,
        ],
      ],
    );
  }
}
