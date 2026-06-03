import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/data_service.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/mobile_app_wrapper.dart';
import '../../widgets/stat_card.dart';

class MonthlyMaintenanceScreen extends StatefulWidget {
  const MonthlyMaintenanceScreen({super.key});

  @override
  State<MonthlyMaintenanceScreen> createState() => _MonthlyMaintenanceScreenState();
}

class _MonthlyMaintenanceScreenState extends State<MonthlyMaintenanceScreen> {
  final List<String> _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  late int _selectedMonth;
  late int _selectedYear;
  late bool _isReportClosed;
  Map<String, int> _reportSummary = {
    'totalIncome': 0,
    'totalExpense': 0,
    'balance': 0,
    'activityCount': 0,
    'aspirationTotal': 0,
    'aspirationWaiting': 0,
    'aspirationProcessing': 0,
    'aspirationReplied': 0,
  };

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
    _isReportClosed = false;
    _loadMonthlyReport();
  }

  Future<void> _loadMonthlyReport() async {
    final report = DataService.instance.getMonthlyReportData(_selectedMonth, _selectedYear);
    final isClosed = await DataService.instance.isMonthlyReportClosed(_selectedMonth, _selectedYear);

    if (!mounted) return;
    setState(() {
      _reportSummary = {
        'totalIncome': report['totalIncome'] as int,
        'totalExpense': report['totalExpense'] as int,
        'balance': report['balance'] as int,
        'activityCount': report['activityCount'] as int,
        'aspirationTotal': report['aspirationTotal'] as int,
        'aspirationWaiting': report['aspirationWaiting'] as int,
        'aspirationProcessing': report['aspirationProcessing'] as int,
        'aspirationReplied': report['aspirationReplied'] as int,
      };
      _isReportClosed = isClosed;
    });
  }

  Future<void> _setReportClosed(bool closed) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await ConfirmDialog.show(
      context,
      title: closed ? 'Tutup Laporan Bulanan' : 'Reset Status Laporan',
      content: closed
          ? 'Apakah Anda yakin ingin menutup laporan bulan ini?'
          : 'Reset status laporan akan mengembalikan laporan ke status belum ditutup. Lanjutkan?',
    );

    if (confirmed != true) return;
    await DataService.instance.setMonthlyReportClosed(_selectedMonth, _selectedYear, closed);
    await _loadMonthlyReport();
    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          closed
              ? 'Laporan bulan ini sudah ditutup dan siap dipertanggungjawabkan.'
              : 'Status laporan berhasil di-reset menjadi Belum Ditutup.',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: closed ? const Color(0xFF6C3CBC) : Colors.orange,
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color accentColor) {
    return StatCard(
      label: label,
      value: value,
      accentColor: accentColor,
      backgroundColor: _withOpacity(accentColor, 0.08),
    );
  }

  Color _withOpacity(Color color, double opacity) {
    final int argb = color.toARGB32();
    final int red = (argb >> 16) & 0xFF;
    final int green = (argb >> 8) & 0xFF;
    final int blue = argb & 0xFF;
    return Color.fromRGBO(red, green, blue, opacity);
  }

  Widget _buildRecommendationCard(String title, String message, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _withOpacity(color, 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 8),
          Text(message, style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusText = _isReportClosed ? 'Sudah Ditutup' : 'Belum Ditutup';
    final statusColor = _isReportClosed ? Colors.green : Colors.orange;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        title: Text('Maintenance Bulanan', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF6C3CBC),
      ),
      body: MobileAppWrapper(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Maintenance Bulanan', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF6C3CBC))),
              const SizedBox(height: 6),
              Text('Pastikan laporan bulan ini ditutup dengan rapi sebelum audit berikutnya.',
                  style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF9B59B6))),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: const Color.fromRGBO(0, 0, 0, 0.05), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fitur Unggulan', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF6C3CBC))),
                    const SizedBox(height: 8),
                    Text(
                      'Tutup laporan untuk mengunci data dan menandai status resmi. Reset hanya saat ada koreksi penting.',
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text('Pilih Bulan & Tahun', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: 'Bulan',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      initialValue: _selectedMonth,
                      items: List.generate(
                        12,
                        (index) => DropdownMenuItem(
                          value: index + 1,
                          child: Text(_monthNames[index]),
                        ),
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedMonth = value);
                          _loadMonthlyReport();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: 'Tahun',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      initialValue: _selectedYear,
                      items: List.generate(5, (index) {
                        final year = DateTime.now().year - index;
                        return DropdownMenuItem(value: year, child: Text(year.toString()));
                      }),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedYear = value);
                          _loadMonthlyReport();
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _withOpacity(statusColor, 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status Laporan', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text(statusText, style: GoogleFonts.poppins(fontSize: 14, color: statusColor)),
                          ],
                        ),
                        Icon(Icons.folder, color: statusColor),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isReportClosed
                          ? 'Laporan bulan ini sudah ditutup dan siap untuk pelaporan resmi.'
                          : 'Laporan belum ditutup. Tutup laporan jika semua data sudah valid dan lengkap.',
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                      SizedBox(width: 160, child: _buildSummaryCard('Pemasukan', 'Rp ${_formatAmount(_reportSummary['totalIncome']!)}', Colors.green)),
                  SizedBox(width: 160, child: _buildSummaryCard('Pengeluaran', 'Rp ${_formatAmount(_reportSummary['totalExpense']!)}', Colors.red)),
                  SizedBox(width: 160, child: _buildSummaryCard('Saldo Akhir', 'Rp ${_formatAmount(_reportSummary['balance']!)}', Colors.black87)),
                  SizedBox(width: 160, child: _buildSummaryCard('Kegiatan', _reportSummary['activityCount']!.toString(), const Color(0xFF6C3CBC))),
                  SizedBox(width: 160, child: _buildSummaryCard('Aspirasi Masuk', _reportSummary['aspirationTotal']!.toString(), const Color(0xFF9B59B6))),
                  SizedBox(width: 160, child: _buildSummaryCard('Menunggu', _reportSummary['aspirationWaiting']!.toString(), Colors.orange)),
                  SizedBox(width: 160, child: _buildSummaryCard('Diproses', _reportSummary['aspirationProcessing']!.toString(), Colors.blue)),
                  SizedBox(width: 160, child: _buildSummaryCard('Dibalas', _reportSummary['aspirationReplied']!.toString(), Colors.green)),
                ],
              ),
              const SizedBox(height: 20),
              Text('Rekomendasi Admin', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (_reportSummary['aspirationWaiting']! > 0)
                _buildRecommendationCard(
                  'Tindakan Aspirasi',
                  'Masih ada ${_reportSummary['aspirationWaiting']} aspirasi berstatus Menunggu. Segera proses agar laporan bulanan lebih lengkap.',
                  Colors.orange,
                ),
              if (_reportSummary['balance']! < 0)
                _buildRecommendationCard(
                  'Saldo Negatif',
                  'Saldo akhir bulan negatif. Periksa kembali transaksi pengeluaran dan pemasukan.',
                  Colors.red,
                ),
              if (_isReportClosed)
                _buildRecommendationCard(
                  'Laporan Aman',
                  'Laporan bulan ini sudah ditutup dan siap dipertanggungjawabkan.',
                  Colors.green,
                ),
              const SizedBox(height: 20),
              Text('Penutupan Laporan', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Gunakan tombol di bawah untuk menutup bulan ini ketika semua data sudah diverifikasi. Reset hanya jika terdapat koreksi atau revisi penting.',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _isReportClosed ? null : () => _setReportClosed(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C3CBC),
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Tutup Laporan Bulanan', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: !_isReportClosed ? null : () => _setReportClosed(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6C3CBC),
                  side: const BorderSide(color: Color(0xFF6C3CBC)),
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Reset Status Laporan', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF6C3CBC))),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }
}
