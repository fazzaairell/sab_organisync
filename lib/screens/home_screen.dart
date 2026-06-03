import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../services/data_service.dart';
import 'admin/admin_dashboard_screen.dart';
import '../widgets/mobile_app_wrapper.dart';

import '../models/organization_model.dart';
import '../services/organization_service.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onMenuTap;

  const HomeScreen({super.key, this.onMenuTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  OrganizationModel? _organization;

  @override
  void initState() {
    super.initState();
    _loadOrganization();
  }

  Future<void> _loadOrganization() async {
    final user = AuthService.instance.currentUser;
    if (user?.activeOrganizationId != null) {
      final org = await OrganizationService.instance.getOrganizationById(user!.activeOrganizationId!);
      if (mounted) {
        setState(() {
          _organization = org;
        });
      }
    }
  }

  bool _hasAccess(String featureId) {
    final user = AuthService.instance.currentUser;
    if (user == null || _organization == null) return false;
    if (user.role == 'organization_owner' || user.role == 'admin' || user.role == 'super_admin') return true;

    final permissions = _organization!.featurePermissions;
    if (permissions.isEmpty || !permissions.containsKey(featureId)) return true; // Default allow if not set

    return permissions[featureId]!.contains(user.role) || (user.role == 'org_manager' && permissions[featureId]!.contains('organization_manager'));
  }

  void _handleMenuTap(String featureId, VoidCallback onAllowed) {
    if (_hasAccess(featureId)) {
      onAllowed();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda tidak memiliki akses ke fitur ini.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      body: MobileAppWrapper(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Selamat datang di OrganiSync',
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                          Text(user != null ? user.name : 'Tamu',
                              style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF6C3CBC)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(user != null ? 'Role: ${user.role}' : 'Role: tamu',
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () async {
                            await AuthService.instance.logout();
                            if (!context.mounted) return;
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          icon: const Icon(Icons.logout_rounded,
                              color: Color(0xFF6C3CBC)),
                          tooltip: 'Keluar',
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/profile'),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color(0xFF6C3CBC),
                            backgroundImage: user?.profileImagePath != null && user!.profileImagePath!.isNotEmpty
                                ? (user.profileImagePath!.startsWith('http')
                                    ? NetworkImage(user.profileImagePath!)
                                    : FileImage(File(user.profileImagePath!)) as ImageProvider)
                                : null,
                            child: user?.profileImagePath == null || user!.profileImagePath!.isEmpty
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C3CBC), Color(0xFF9B59B6)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Transparansi Organisasi',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Semua informasi organisasi\nada di satu tempat, mudah diakses.',
                          style: GoogleFonts.poppins(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                if (user?.activeOrganizationId == null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Text(
                      'Anda belum terhubung ke organisasi aktif. Silakan masuk atau pilih organisasi terlebih dahulu agar data yang ditampilkan sesuai.',
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
                // Menu Grid
                Text('Menu Utama',
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.25,
                  children: [
                    _menuCard(Icons.account_balance_wallet_rounded,
                        'Keuangan', 'Lihat laporan dana organisasi', Colors.green, onTap: () => _handleMenuTap('finance', () => widget.onMenuTap?.call(1))),
                    _menuCard(Icons.calendar_month_rounded,
                      'Jadwal', 'Agenda kegiatan terbaru', Colors.blue, onTap: () => _handleMenuTap('schedule', () => widget.onMenuTap?.call(2))),
                    _menuCard(Icons.photo_library_rounded,
                        'Kegiatan', 'Dokumentasi acara & aktivitas', Colors.orange, onTap: () => _handleMenuTap('activity', () => widget.onMenuTap?.call(3))),
                    _menuCard(Icons.campaign_rounded,
                        'Aspirasi', 'Sampaikan pendapat & saran', Colors.purple, onTap: () => _handleMenuTap('aspiration', () => widget.onMenuTap?.call(4))),
                    _menuCard(Icons.people_alt_rounded,
                        'Anggota', 'Direktori & info anggota', Colors.teal, onTap: () => _handleMenuTap('member', () {
                      Navigator.pushNamed(context, '/members');
                    })),
                    // New Inventory Card
                    _menuCard(Icons.inventory_2_rounded,
                        'Inventaris', 'Kelola aset & barang', Colors.brown, onTap: () => _handleMenuTap('inventory', () {
                      Navigator.pushNamed(context, '/inventory');
                    })),
                    if ((user?.isSuperAdmin ?? false) || (user?.isOrganizationOwner ?? false))
                      _menuCard(Icons.admin_panel_settings_rounded, 'Admin Panel',
                          'Kelola sistem & maintenance', const Color(0xFF6C3CBC), onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
                      }),
                  ],
                ),
                const SizedBox(height: 22),
                // Pengumuman
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pengumuman Terbaru',
                        style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/announcements'),
                      child: Text(
                        'Lihat Semua',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF6C3CBC),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ListenableBuilder(
                  listenable: DataService.instance,
                  builder: (context, child) {
                    final list = DataService.instance.getAnnouncements();
                    if (list.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Belum ada pengumuman.',
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      );
                    }
                    final displayList = list.take(3).toList();
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final a = displayList[index];
                        return _announcementCard(a.title, a.content, a.date);
                      },
                    );
                  }
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuCard(IconData icon, String title, String subtitle, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold, fontSize: 13)),
            Text(subtitle,
                style: GoogleFonts.poppins(
                    fontSize: 10, color: Colors.grey[600]),
                maxLines: 2),
          ],
        ),
      ),
    );
  }

  Widget _announcementCard(String title, String desc, String time) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                Text(desc,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
          Text(time,
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}