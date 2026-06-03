import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/data_service.dart';
import 'manage_activity_screen.dart';
import 'manage_aspiration_screen.dart';
import 'manage_finance_screen.dart';
import 'manage_schedule_screen.dart';
import 'monthly_maintenance_screen.dart';
import '../../widgets/mobile_app_wrapper.dart';
import '../../widgets/section_title.dart';
import '../../widgets/stat_card.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activeOrgId = DataService.instance.activeOrganizationId;
    if (activeOrgId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F0FF),
        appBar: AppBar(
          title: Text('Admin Dashboard', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF6C3CBC),
          elevation: 0,
        ),
        body: MobileAppWrapper(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Tidak ada organisasi aktif. Pilih organisasi terlebih dahulu untuk melihat statistik dan melakukan pengelolaan.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
              ),
            ),
          ),
        ),
      );
    }

    final activities = DataService.instance.getActivities();
    final aspirations = DataService.instance.getAspirations();
    final summary = DataService.instance.getMonthlySummary();

    final totalIn = summary['totalIncome'] as int;
    final totalOut = summary['totalExpense'] as int;
    final saldo = summary['balance'] as int;

    final totalActivities = activities.length;
    final totalAspirations = aspirations.length;
    final pendingAspirations = summary['pendingAspirations'] as int;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        title: Text('Admin Dashboard', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6C3CBC),
        elevation: 0,
      ),
      body: MobileAppWrapper(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text('Selamat datang, Admin!',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6C3CBC))),
              const SizedBox(height: 2),
              Text('Kelola seluruh data organisasi dengan mudah dan aman.',
                  style: GoogleFonts.poppins(fontSize: 13, color: Color(0xFF9B59B6))),
              const SizedBox(height: 16),
              const SectionTitle(title: 'Ringkasan Statistik'),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.7,
                children: [
                  StatCard(
                    label: 'Pemasukan',
                    value: 'Rp ${_formatAmount(totalIn)}',
                    accentColor: Colors.green,
                    backgroundColor: const Color.fromRGBO(76, 175, 80, 0.08),
                  ),
                  StatCard(
                    label: 'Pengeluaran',
                    value: 'Rp ${_formatAmount(totalOut)}',
                    accentColor: Colors.red,
                    backgroundColor: const Color.fromRGBO(244, 67, 54, 0.08),
                  ),
                  StatCard(
                    label: 'Saldo',
                    value: 'Rp ${_formatAmount(saldo)}',
                    accentColor: Colors.black87,
                    backgroundColor: Colors.white,
                  ),
                  StatCard(
                    label: 'Jumlah Kegiatan',
                    value: '$totalActivities',
                    accentColor: const Color(0xFF6C3CBC),
                    backgroundColor: const Color(0x146C3CBC),
                  ),
                  StatCard(
                    label: 'Total Aspirasi',
                    value: '$totalAspirations',
                    accentColor: const Color(0xFF9B59B6),
                    backgroundColor: const Color(0x149B59B6),
                  ),
                  StatCard(
                    label: 'Aspirasi Menunggu',
                    value: '$pendingAspirations',
                    accentColor: Colors.orange,
                    backgroundColor: const Color.fromRGBO(255, 152, 0, 0.08),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const SectionTitle(title: 'Panel Pengelolaan'),
              GridView.count(
                crossAxisCount: 1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                childAspectRatio: 3.8,
                children: [
                  _panelCard(context, Icons.account_balance_wallet, 'Kelola Keuangan',
                      'Lihat, tambah, dan edit transaksi keuangan organisasi.', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageFinanceScreen()));
                  }),
                  _panelCard(context, Icons.calendar_month, 'Kelola Jadwal',
                      'Atur agenda dan jadwal kegiatan organisasi.', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageScheduleScreen()));
                  }),
                  _panelCard(context, Icons.photo_library, 'Kelola Kegiatan',
                      'Dokumentasikan dan kelola seluruh aktivitas organisasi.', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageActivityScreen()));
                  }),
                  _panelCard(context, Icons.campaign, 'Kelola Aspirasi',
                      'Tinjau dan balas aspirasi yang masuk dari mahasiswa.', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageAspirationScreen()));
                  }),
                  _panelCard(context, Icons.build_circle, 'Maintenance Bulanan',
                      'Lakukan perawatan data dan reset bulanan.', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MonthlyMaintenanceScreen()));
                  }),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _panelCard(BuildContext context, IconData icon, String title, String desc, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color.fromRGBO(0, 0, 0, 0.06), blurRadius: 10, offset: const Offset(0,2))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF6C3CBC),
              radius: 26,
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF6C3CBC))),
                  const SizedBox(height: 4),
                  Text(desc, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF9B59B6), size: 18),
          ],
        ),
      ),
    );
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }
}