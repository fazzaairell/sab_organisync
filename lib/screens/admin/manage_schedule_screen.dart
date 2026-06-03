import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/schedule_model.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/form_input.dart';
import '../../widgets/mobile_app_wrapper.dart';

class ManageScheduleScreen extends StatefulWidget {
  const ManageScheduleScreen({super.key});

  @override
  State<ManageScheduleScreen> createState() => _ManageScheduleScreenState();
}

class _ManageScheduleScreenState extends State<ManageScheduleScreen> {
  List<ScheduleModel> _schedules = [];
  final List<String> _categories = ['Rapat', 'Seminar', 'Sosial', 'Lomba', 'Acara'];

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  void _refreshList() {
    setState(() {
      _schedules = DataService.instance.getSchedules();
    });
  }

  Color _colorForCategory(String category) {
    switch (category) {
      case 'Rapat':
        return const Color(0xFF6C3CBC);
      case 'Seminar':
        return const Color(0xFF2196F3);
      case 'Sosial':
        return const Color(0xFF4CAF50);
      case 'Lomba':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF9B59B6);
    }
  }

  Future<void> _openScheduleForm([ScheduleModel? schedule]) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: schedule?.title ?? '');
    final locationController = TextEditingController(text: schedule?.location ?? '');
    final timeController = TextEditingController(text: schedule?.time ?? '');
    final dateController = TextEditingController(text: schedule?.date ?? '');
    String categoryValue = schedule?.category ?? _categories.first;

    Future<void> pickDate() async {
      final initial = DateTime.tryParse(schedule?.date ?? '') ?? DateTime.now();
      final selected = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (selected != null) {
        dateController.text = DateFormat('dd MMM yyyy', 'id_ID').format(selected);
      }
    }
    final rootContext = context;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final sheetNavigator = Navigator.of(context);
              final snackBarMessenger = ScaffoldMessenger.of(rootContext);

              return Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
                  child: Form(
                    key: formKey,
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
                          schedule == null ? 'Tambah Jadwal' : 'Edit Jadwal',
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        FormInput(
                          controller: titleController,
                          label: 'Nama Kegiatan',
                          hintText: 'Contoh: Rapat Koordinator',
                          prefixIcon: const Icon(Icons.event_note),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nama kegiatan wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        FormInput(
                          controller: dateController,
                          label: 'Tanggal',
                          hintText: 'Pilih tanggal kegiatan',
                          prefixIcon: const Icon(Icons.calendar_today),
                          readOnly: true,
                          onTap: pickDate,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Tanggal wajib dipilih';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        FormInput(
                          controller: timeController,
                          label: 'Jam',
                          hintText: 'Contoh: 14.00 - 16.00 WIB',
                          prefixIcon: const Icon(Icons.access_time),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Jam wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        FormInput(
                          controller: locationController,
                          label: 'Lokasi',
                          hintText: 'Contoh: Aula Gedung A',
                          prefixIcon: const Icon(Icons.location_on),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Lokasi wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: categoryValue,
                          decoration: InputDecoration(
                            labelText: 'Kategori',
                            labelStyle: GoogleFonts.poppins(fontSize: 13),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: _categories
                              .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setModalState(() => categoryValue = value);
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) {
                                return;
                              }
                              final newSchedule = ScheduleModel(
                                id: schedule?.id ?? '',
                                organizationId: DataService.instance.activeOrganizationId,
                                title: titleController.text.trim(),
                                date: dateController.text.trim(),
                                time: timeController.text.trim(),
                                location: locationController.text.trim(),
                                category: categoryValue,
                                color: _colorForCategory(categoryValue).value,
                              );
                              if (schedule == null) {
                                await DataService.instance.addSchedule(newSchedule);
                              } else {
                                await DataService.instance.updateSchedule(newSchedule);
                              }
                              if (!mounted) return;
                              sheetNavigator.pop();
                              _refreshList();
                              snackBarMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    schedule == null ? 'Jadwal berhasil ditambahkan' : 'Jadwal berhasil diperbarui',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor: const Color(0xFF6C3CBC),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C3CBC),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              schedule == null ? 'Simpan Jadwal' : 'Perbarui Jadwal',
                              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );
  }

  Future<void> _deleteSchedule(String id) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Hapus Jadwal',
      content: 'Apakah Anda yakin ingin menghapus jadwal ini?',
    );
    if (confirmed != true) return;

    final snackBarMessenger = ScaffoldMessenger.of(context);
    await DataService.instance.deleteSchedule(id);
    _refreshList();
    if (!mounted) return;
    snackBarMessenger.showSnackBar(
      SnackBar(
        content: Text('Jadwal berhasil dihapus', style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!(AuthService.instance.currentUser?.isAdmin ?? false)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Akses Ditolak')),
        body: const Center(child: Text('Hanya admin dapat mengakses halaman ini')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        title: Text('Kelola Jadwal', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF6C3CBC),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openScheduleForm(),
        backgroundColor: const Color(0xFF6C3CBC),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Tambah', style: GoogleFonts.poppins(color: Colors.white)),
      ),
      body: MobileAppWrapper(
        child: _schedules.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule, size: 52, color: Color(0xFF6C3CBC)),
                      const SizedBox(height: 16),
                      Text('Belum ada jadwal tersimpan', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(
                        'Buat jadwal baru untuk mengatur agenda kegiatan dengan lebih mudah.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                itemCount: _schedules.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final schedule = _schedules[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(schedule.title,
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => _openScheduleForm(schedule),
                                  icon: const Icon(Icons.edit, color: Color(0xFF6C3CBC)),
                                ),
                                IconButton(
                                  onPressed: () => _deleteSchedule(schedule.id),
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _infoChip(Icons.calendar_today, schedule.date),
                            _infoChip(Icons.access_time, schedule.time),
                            _infoChip(Icons.location_on, schedule.location),
                            _categoryChip(schedule.category, _colorForCategory(schedule.category)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(text, style: GoogleFonts.poppins(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _categoryChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
      child: Text(label,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
