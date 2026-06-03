import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FormInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final Widget? prefixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool enabled;

  const FormInput({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.prefixIcon,
    this.readOnly = false,
    this.onTap,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
        labelStyle: GoogleFonts.poppins(fontSize: 13),
        prefixIcon: prefixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6C3CBC)),
        ),
      ),
    );
  }
}
