import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ConfirmDialog {
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String content,
    String confirmLabel = 'Hapus',
    String cancelLabel = 'Batal',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Text(content, style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelLabel, style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C3CBC),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel, style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
