import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../utils/validators.dart';
import '../widgets/mobile_app_wrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final success = await AuthService.instance.login(
      _emailController.text,
      _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (success) {
      await DataService.instance.refreshData();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/main');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Email atau password tidak sesuai',
            style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
    });

    final user = await AuthService.instance.signInWithGoogle();

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (user != null) {
      await DataService.instance.refreshData();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/main');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Login Google gagal atau dibatalkan',
            style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      body: MobileAppWrapper(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo/Brand
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF6C3CBC), Color(0xFF9B59B6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.groups_rounded, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 18),
                Text('OrganiSync',
                    style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C3CBC))),
                const SizedBox(height: 6),
                Text('Transparansi dan Manajemen Organisasi dalam Satu Aplikasi',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Color(0xFF9B59B6),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 24),
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Masuk ke akun Anda',
                            style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6C3CBC))),
                        const SizedBox(height: 8),
                        Text('Gunakan email dan password terdaftar.',
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: Colors.grey[700])),
                        const SizedBox(height: 18),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: const Icon(Icons.email_rounded, color: Color(0xFF6C3CBC)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                validator: Validators.validateEmail,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_rounded, color: Color(0xFF6C3CBC)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                validator: Validators.validatePassword,
                              ),
                              const SizedBox(height: 22),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6C3CBC),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        )
                                      : Text('Masuk',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          )),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(child: Divider(color: Colors.grey[300])),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text('ATAU', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.bold)),
                                  ),
                                  Expanded(child: Divider(color: Colors.grey[300])),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: _isLoading ? null : _handleGoogleLogin,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.grey[300]!),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.network(
                                        'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                        width: 20,
                                        height: 20,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.g_mobiledata, size: 24, color: Colors.red),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          'Masuk dengan Google',
                                          style: GoogleFonts.poppins(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F0FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Akun demo:',
                                  style: GoogleFonts.poppins(fontSize: 12, color: Color(0xFF6C3CBC), fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.admin_panel_settings_rounded, size: 16, color: Color(0xFF6C3CBC)),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text('Admin: admin@organisync.com / admin123',
                                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.school_rounded, size: 16, color: Color(0xFF9B59B6)),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text('Mahasiswa: mahasiswa@organisync.com / user123',
                                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Belum punya akun? ', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, '/register'),
                              child: Text('Daftar Akun',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFF6C3CBC),
                                    fontWeight: FontWeight.bold,
                                  )),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
