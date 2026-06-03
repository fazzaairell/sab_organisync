import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/activity_model.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/form_input.dart';
import '../../widgets/mobile_app_wrapper.dart';

class ManageActivityScreen extends StatefulWidget {
  const ManageActivityScreen({super.key});

  @override
  State<ManageActivityScreen> createState() => _ManageActivityScreenState();
}

class _ManageActivityScreenState extends State<ManageActivityScreen> {
  List<ActivityModel> _activities = [];

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  void _refreshList() {
    setState(() {
      _activities = DataService.instance.getActivities();
    });
  }

  Future<void> _openActivityForm([ActivityModel? activity]) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: activity?.title ?? '');
    final dateController = TextEditingController(text: activity?.date ?? '');
    final descriptionController = TextEditingController(text: activity?.description ?? '');
    final participantsController = TextEditingController(
        text: activity != null ? activity.participants.toString() : '');
    final emojiController = TextEditingController(text: activity?.emoji ?? '');

    Future<void> pickDate() async {
      final initial = DateTime.tryParse(activity?.date ?? '') ?? DateTime.now();
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
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
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
                    activity == null ? 'Tambah Kegiatan' : 'Edit Kegiatan',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  FormInput(
                    controller: titleController,
                    label: 'Judul',
                    hintText: 'Contoh: Workshop Digital Marketing',
                    prefixIcon: const Icon(Icons.event),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Judul wajib diisi';
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
                    controller: descriptionController,
                    label: 'Deskripsi',
                    hintText: 'Isi deskripsi kegiatan',
                    prefixIcon: const Icon(Icons.description),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Deskripsi wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  FormInput(
                    controller: participantsController,
                    label: 'Jumlah Peserta',
                    hintText: 'Contoh: 30',
                    prefixIcon: const Icon(Icons.people),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Jumlah peserta wajib diisi';
                      }
                      final number = int.tryParse(value);
                      if (number == null || number <= 0) {
                        return 'Masukkan angka valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  FormInput(
                    controller: emojiController,
                    label: 'Emoji / Ikon',
                    hintText: 'Contoh: 🎉',
                    prefixIcon: const Icon(Icons.emoji_events),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Emoji wajib diisi';
                      }
                      return null;
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
                        final sheetNavigator = Navigator.of(context);
                        final snackBarMessenger = ScaffoldMessenger.of(rootContext);
                        final participants = int.parse(participantsController.text.trim());
                        final newActivity = ActivityModel(
                          id: activity?.id ?? '',
                          organizationId: DataService.instance.activeOrganizationId,
                          title: titleController.text.trim(),
                          date: dateController.text.trim(),
                          description: descriptionController.text.trim(),
                          participants: participants,
                          emoji: emojiController.text.trim(),
                        );
                        if (activity == null) {
                          await DataService.instance.addActivity(newActivity);
                        } else {
                          await DataService.instance.updateActivity(newActivity);
                        }
                        if (!mounted) return;
                        sheetNavigator.pop();
                        _refreshList();
                        snackBarMessenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              activity == null ? 'Kegiatan berhasil ditambahkan' : 'Kegiatan berhasil diperbarui',
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
                        activity == null ? 'Simpan Kegiatan' : 'Perbarui Kegiatan',
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
    );
  }

  Future<void> _deleteActivity(String id) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Hapus Kegiatan',
      content: 'Apakah Anda yakin ingin menghapus kegiatan ini?',
    );
    if (confirmed != true) return;

    final snackBarMessenger = ScaffoldMessenger.of(context);
    await DataService.instance.deleteActivity(id);
    _refreshList();
    if (!mounted) return;
    snackBarMessenger.showSnackBar(
      SnackBar(
        content: Text('Kegiatan berhasil dihapus', style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(text, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[800])),
        ],
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
        title: Text('Kelola Kegiatan', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF6C3CBC),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openActivityForm(),
        backgroundColor: const Color(0xFF6C3CBC),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Tambah', style: GoogleFonts.poppins(color: Colors.white)),
      ),
      body: MobileAppWrapper(
        child: _activities.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.event_available, size: 52, color: Color(0xFF6C3CBC)),
                      const SizedBox(height: 16),
                      Text('Belum ada kegiatan terdaftar', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(
                        'Tambahkan kegiatan baru untuk menjaga data acara tetap teratur.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                itemCount: _activities.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final activity = _activities[index];
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
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C3CBC).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(activity.emoji, style: const TextStyle(fontSize: 22)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(activity.title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text(activity.date, style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12)),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => _openActivityForm(activity),
                                  icon: const Icon(Icons.edit, color: Color(0xFF6C3CBC)),
                                ),
                                IconButton(
                                  onPressed: () => _deleteActivity(activity.id),
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _infoChip(Icons.access_time, activity.date),
                            _infoChip(Icons.people, '${activity.participants} peserta'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(activity.description, style: GoogleFonts.poppins(color: Colors.grey[800])),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
