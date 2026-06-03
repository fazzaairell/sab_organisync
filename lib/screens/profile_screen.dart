import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_storage/firebase_storage.dart';

import '../models/user_model.dart';
import '../models/organization_model.dart';
import '../services/auth_service.dart';
import '../services/organization_service.dart';
import '../widgets/mobile_app_wrapper.dart';
import 'organization_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _nimController;
  late TextEditingController _campusController;
  
  UserModel? _user;
  OrganizationModel? _organization;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _user = AuthService.instance.currentUser;
    _nameController = TextEditingController(text: _user?.name ?? '');
    _nimController = TextEditingController(text: _user?.nim ?? '');
    _campusController = TextEditingController(text: _user?.campusName ?? '');
    if (_user?.profileImagePath != null && _user!.profileImagePath!.isNotEmpty) {
      _imageFile = File(_user!.profileImagePath!);
    }
    _loadOrganization();
  }

  Future<void> _loadOrganization() async {
    if (_user?.activeOrganizationId != null) {
      final org = await OrganizationService.instance.getOrganizationById(_user!.activeOrganizationId!);
      if (mounted) {
        setState(() {
          _organization = org;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nimController.dispose();
    _campusController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Tampilkan indikator loading (opsional)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mengunggah foto...')),
        );

        final file = File(pickedFile.path);
        
        // Upload ke Firebase Storage
        final fileName = 'profile_${_user?.id}_${DateTime.now().millisecondsSinceEpoch}${path.extension(pickedFile.path)}';
        final storageRef = FirebaseStorage.instance.ref().child('profile_images').child(fileName);
        
        await storageRef.putFile(file);
        final downloadUrl = await storageRef.getDownloadURL();

        setState(() {
          _imageFile = file; // Tetap update file lokal untuk display sementara jika perlu
        });

        if (_user != null) {
          final updated = _user!.copyWith(profileImagePath: downloadUrl);
          await AuthService.instance.updateProfile(updated);
          setState(() {
            _user = updated;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Foto profil berhasil diperbarui!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil/mengunggah gambar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF6C3CBC)),
              title: Text('Pilih dari Galeri', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Color(0xFF6C3CBC)),
              title: Text('Ambil Foto Baru', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfileChanges() async {
    if (!_formKey.currentState!.validate()) return;

    if (_user != null) {
      final updated = _user!.copyWith(
        name: _nameController.text.trim(),
        nim: _nimController.text.trim(),
        campusName: _campusController.text.trim(),
      );

      await AuthService.instance.updateProfile(updated);
      setState(() {
        _user = updated;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui! 🎉'),
          backgroundColor: Color(0xFF6C3CBC),
        ),
      );
      Navigator.pop(context);
    }
  }

  void _showEditProfileBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Edit Informasi Profil',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6C3CBC),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  labelStyle: GoogleFonts.poppins(fontSize: 13),
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nimController,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'NIM (Nomor Induk Mahasiswa)',
                  labelStyle: GoogleFonts.poppins(fontSize: 13),
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _campusController,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Nama Kampus / Universitas',
                  labelStyle: GoogleFonts.poppins(fontSize: 13),
                  prefixIcon: const Icon(Icons.school_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfileChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C3CBC),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Simpan Perubahan',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        title: Text(
          'Profil Saya',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF6C3CBC),
        elevation: 0,
        centerTitle: true,
      ),
      body: MobileAppWrapper(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Profile Image Header Section
              Center(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF6C3CBC), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C3CBC).withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.white,
                        backgroundImage: _user?.profileImagePath != null && _user!.profileImagePath!.isNotEmpty
                            ? (_user!.profileImagePath!.startsWith('http')
                                ? NetworkImage(_user!.profileImagePath!)
                                : FileImage(File(_user!.profileImagePath!)) as ImageProvider)
                            : null,
                        child: _user?.profileImagePath == null || _user!.profileImagePath!.isEmpty
                            ? const Icon(Icons.person, size: 70, color: Color(0xFF6C3CBC))
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showImageSourceActionSheet,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF9B59B6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _user?.name ?? 'Tamu',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6C3CBC),
                ),
              ),
              Text(
                _user?.email ?? '',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              // Details Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(Icons.badge_outlined, 'NIM', _user?.nim ?? '-'),
                      const Divider(height: 24),
                      _buildDetailRow(Icons.school_outlined, 'Kampus', _user?.campusName ?? '-'),
                      const Divider(height: 24),
                      _buildDetailRow(
                        Icons.admin_panel_settings_outlined,
                        'Role Jabatan',
                        _user?.role.toUpperCase() ?? 'TAMU',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showEditProfileBottomSheet,
                        icon: const Icon(Icons.edit_outlined, color: Colors.white),
                        label: Text(
                          'Edit Profil',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C3CBC),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await AuthService.instance.logout();
                          if (!mounted) return;
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                        },
                        icon: const Icon(Icons.logout_rounded, color: Colors.red),
                        label: Text(
                          'Keluar dari Akun',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    if (_user?.role == 'organization_owner' && _organization != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showOrganizationSettings,
                          icon: const Icon(Icons.settings_applications_rounded, color: Color(0xFF6C3CBC)),
                          label: Text(
                            'Pengaturan Organisasi',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF6C3CBC),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF6C3CBC)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF6C3CBC), size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  void _showOrganizationSettings() {
    if (_organization == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrganizationSettingsScreen(organization: _organization!),
      ),
    ).then((updatedOrg) {
      if (updatedOrg != null && updatedOrg is OrganizationModel) {
        setState(() {
          _organization = updatedOrg;
        });
      }
    });
  }
}
