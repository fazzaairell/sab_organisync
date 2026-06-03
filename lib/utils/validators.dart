class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email tidak boleh kosong';
    }
    final email = value.trim();
    final emailRegex = RegExp(r"^[\w-.]+@[\w-]+\.[a-zA-Z]{2,}");
    if (!emailRegex.hasMatch(email)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }
}
