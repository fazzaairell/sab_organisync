import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../services/organization_service.dart';
import '../utils/validators.dart';
import '../widgets/mobile_app_wrapper.dart';

enum AccountType { manager, member }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nimController = TextEditingController();
  final TextEditingController _campusController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _organizationNameController = TextEditingController();
  final TextEditingController _organizationTypeController = TextEditingController();
  final TextEditingController _organizationDescriptionController = TextEditingController();
  final TextEditingController _organizationCodeController = TextEditingController();

  AccountType? _selectedAccountType;
  String? _accountTypeError;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _nimController.dispose();
    _campusController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _organizationNameController.dispose();
    _organizationTypeController.dispose();
    _organizationDescriptionController.dispose();
    _organizationCodeController.dispose();
    super.dispose();
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

    _showError('Pendaftaran dengan Google gagal atau dibatalkan');
  }

  Future<void> _handleRegister() async {
    setState(() {
      _accountTypeError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAccountType == null) {
      setState(() {
        _accountTypeError = 'Pilih jenis akun terlebih dahulu';
      });
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final nim = _nimController.text.trim();
    final campusName = _campusController.text.trim();
    final password = _passwordController.text;
    final organizationName = _organizationNameController.text.trim();
    final organizationType = _organizationTypeController.text.trim();
    final organizationDescription = _organizationDescriptionController.text.trim();
    final organizationCode = _organizationCodeController.text.trim();

    if (email.toLowerCase() == 'admin@organisync.com' ||
        email.toLowerCase() == 'mahasiswa@organisync.com') {
      _showError('Tidak boleh mendaftar menggunakan email demo.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = DateTime.now().millisecondsSinceEpoch.toString();
      if (_selectedAccountType == AccountType.manager) {
        if (organizationName.isEmpty) {
          _showError('Nama organisasi wajib diisi.');
          return;
        }
        if (organizationType.isEmpty) {
          _showError('Jenis organisasi wajib diisi.');
          return;
        }
        if (organizationDescription.isEmpty) {
          _showError('Deskripsi organisasi wajib diisi.');
          return;
        }

        final organization = await OrganizationService.instance.createOrganization(
          name: organizationName,
          campusName: campusName,
          description: organizationDescription,
          ownerId: userId,
          ownerRole: 'organization_owner',
        );

        final registeredUser = await AuthService.instance.registerUser(
          id: userId,
          name: name,
          email: email,
          nim: nim,
          campusName: campusName,
          password: password,
          activeOrganizationId: organization.id,
          role: 'organization_owner',
        );

        if (registeredUser == null) {
          _showError('Pendaftaran gagal, silakan coba kembali dengan email lain.');
          return;
        }

        await OrganizationService.instance.setActiveOrganizationForUser(userId, organization.id);

        await _showSuccess(
          title: 'Pendaftaran Berhasil',
          message:
              'Akun pengelola organisasi telah dibuat. Kode organisasi Anda adalah ${organization.code}. Simpan kode ini untuk digunakan oleh anggota.',
        );
      } else {
        if (organizationCode.isEmpty) {
          _showError('Kode organisasi wajib diisi.');
          return;
        }

        final organization = await OrganizationService.instance.getOrganizationByCode(organizationCode);
        if (organization == null) {
          _showError('Kode organisasi tidak ditemukan. Periksa kembali kode yang diberikan pengelola.');
          return;
        }

        final registeredUser = await AuthService.instance.registerUser(
          id: userId,
          name: name,
          email: email,
          nim: nim,
          campusName: campusName,
          password: password,
          activeOrganizationId: organization.id,
          role: 'organization_member',
        );

        if (registeredUser == null) {
          _showError('Pendaftaran gagal, silakan coba kembali dengan email lain.');
          return;
        }

        await OrganizationService.instance.createMembership(
          userId: registeredUser.id,
          organizationId: organization.id,
          role: 'organization_member',
        );
        await OrganizationService.instance.setActiveOrganizationForUser(registeredUser.id, organization.id);

        await _showSuccess(
          title: 'Pendaftaran Berhasil',
          message: 'Akun berhasil dibuat. Silakan masuk untuk melanjutkan ke organisasi ${organization.name}.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _showSuccess({required String title, required String message}) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Text(message, style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text('Kembali ke Login', style: GoogleFonts.poppins(color: const Color(0xFF6C3CBC))),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Akun', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6C3CBC),
      ),
      backgroundColor: const Color(0xFFF5F0FF),
      body: MobileAppWrapper(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Isi data pendaftaran', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF6C3CBC))),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama lengkap',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama lengkap wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      validator: Validators.validateEmail,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nimController,
                      decoration: InputDecoration(
                        labelText: 'NIM',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'NIM wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _campusController,
                      decoration: InputDecoration(
                        labelText: 'Nama kampus',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama kampus wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      validator: Validators.validatePassword,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi password',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Konfirmasi password wajib diisi';
                        }
                        if (value != _passwordController.text) {
                          return 'Password dan konfirmasi tidak sama';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    Text('Jenis akun', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                    RadioListTile<AccountType>(
                      value: AccountType.manager,
                      groupValue: _selectedAccountType,
                      title: Text('Saya ingin mengelola organisasi', style: GoogleFonts.poppins()),
                      onChanged: (value) {
                        setState(() {
                          _selectedAccountType = value;
                          _accountTypeError = null;
                        });
                      },
                    ),
                    RadioListTile<AccountType>(
                      value: AccountType.member,
                      groupValue: _selectedAccountType,
                      title: Text('Saya ingin mengakses organisasi', style: GoogleFonts.poppins()),
                      onChanged: (value) {
                        setState(() {
                          _selectedAccountType = value;
                          _accountTypeError = null;
                        });
                      },
                    ),
                    if (_accountTypeError != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 4),
                        child: Text(_accountTypeError!, style: GoogleFonts.poppins(color: Colors.red, fontSize: 12)),
                      ),
                    if (_selectedAccountType == AccountType.manager) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _organizationNameController,
                        decoration: InputDecoration(
                          labelText: 'Nama organisasi',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        validator: (value) {
                          if (_selectedAccountType == AccountType.manager && (value == null || value.trim().isEmpty)) {
                            return 'Nama organisasi wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _organizationTypeController,
                        decoration: InputDecoration(
                          labelText: 'Jenis organisasi',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        validator: (value) {
                          if (_selectedAccountType == AccountType.manager && (value == null || value.trim().isEmpty)) {
                            return 'Jenis organisasi wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _organizationDescriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Deskripsi organisasi singkat',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        validator: (value) {
                          if (_selectedAccountType == AccountType.manager && (value == null || value.trim().isEmpty)) {
                            return 'Deskripsi organisasi wajib diisi';
                          }
                          return null;
                        },
                      ),
                    ] else if (_selectedAccountType == AccountType.member) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _organizationCodeController,
                        decoration: InputDecoration(
                          labelText: 'Kode organisasi',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        validator: (value) {
                          if (_selectedAccountType == AccountType.member && (value == null || value.trim().isEmpty)) {
                            return 'Kode organisasi wajib diisi';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C3CBC),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                            : Text('Daftar Akun', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
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
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _handleGoogleLogin,
                        icon: Image.network('https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg', width: 24),
                        label: Text('Daftar dengan Google', style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Sudah punya akun? ', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                          child: Text('Masuk',
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
          ),
        ),
      ),
    );
  }
}
