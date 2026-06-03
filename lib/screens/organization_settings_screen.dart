import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/organization_model.dart';
import '../services/organization_service.dart';
import '../widgets/mobile_app_wrapper.dart';

class OrganizationSettingsScreen extends StatefulWidget {
  final OrganizationModel organization;

  const OrganizationSettingsScreen({super.key, required this.organization});

  @override
  State<OrganizationSettingsScreen> createState() => _OrganizationSettingsScreenState();
}

class _OrganizationSettingsScreenState extends State<OrganizationSettingsScreen> {
  late TextEditingController _codeController;
  late OrganizationModel _org;
  
  // Local state for permissions
  late Map<String, List<String>> _permissions;

  final List<Map<String, String>> _features = [
    {'id': 'finance', 'name': 'Keuangan'},
    {'id': 'schedule', 'name': 'Jadwal'},
    {'id': 'activity', 'name': 'Kegiatan'},
    {'id': 'aspiration', 'name': 'Aspirasi'},
    {'id': 'member', 'name': 'Anggota'},
    {'id': 'inventory', 'name': 'Inventaris'}, // New feature
  ];

  @override
  void initState() {
    super.initState();
    _org = widget.organization;
    _codeController = TextEditingController(text: _org.code);
    
    // Initialize permissions (default allow all if empty for backward compatibility)
    _permissions = Map<String, List<String>>.from(_org.featurePermissions);
    for (var feature in _features) {
      if (!_permissions.containsKey(feature['id'])) {
        _permissions[feature['id']!] = ['organization_owner', 'organization_manager', 'organization_member'];
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final newCode = _codeController.text.trim();
    if (newCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode tidak boleh kosong')),
      );
      return;
    }

    try {
      final updatedOrg = _org.copyWith(
        code: newCode,
        featurePermissions: _permissions,
      );
      
      await OrganizationService.instance.updateOrganization(updatedOrg);
      
      setState(() {
        _org = updatedOrg;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengaturan organisasi berhasil disimpan'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, updatedOrg);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPermissionRow(String featureId, String featureName) {
    final allowedRoles = _permissions[featureId] ?? [];
    
    // organization_owner always has access, we only toggle manager and member
    final isManagerAllowed = allowedRoles.contains('organization_manager') || allowedRoles.contains('org_manager');
    final isMemberAllowed = allowedRoles.contains('organization_member') || allowedRoles.contains('member');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            featureName,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: const Color(0xFF6C3CBC),
                  title: Text('Pengurus', style: GoogleFonts.poppins(fontSize: 13)),
                  value: isManagerAllowed,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        if (!_permissions[featureId]!.contains('organization_manager')) {
                           _permissions[featureId]!.add('organization_manager');
                        }
                      } else {
                        _permissions[featureId]!.removeWhere((r) => r == 'organization_manager' || r == 'org_manager');
                      }
                    });
                  },
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: const Color(0xFF6C3CBC),
                  title: Text('Anggota', style: GoogleFonts.poppins(fontSize: 13)),
                  value: isMemberAllowed,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        if (!_permissions[featureId]!.contains('organization_member')) {
                          _permissions[featureId]!.add('organization_member');
                        }
                      } else {
                        _permissions[featureId]!.removeWhere((r) => r == 'organization_member' || r == 'member');
                      }
                    });
                  },
                ),
              ),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        title: Text(
          'Pengaturan Organisasi',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF6C3CBC),
        elevation: 0,
        centerTitle: true,
      ),
      body: MobileAppWrapper(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Umum',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6C3CBC),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Nama Organisasi: ${_org.name}', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _codeController,
                      style: GoogleFonts.poppins(),
                      decoration: InputDecoration(
                        labelText: 'Kode Akses Organisasi (Untuk mengundang anggota)',
                        labelStyle: GoogleFonts.poppins(fontSize: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hak Akses Fitur (RBAC)',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6C3CBC),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Atur role apa saja yang boleh mengakses menu-menu berikut (Ketua selalu memiliki akses penuh).',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    ..._features.map((f) => _buildPermissionRow(f['id']!, f['name']!)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C3CBC),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Simpan Pengaturan',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
