import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/aspiration_model.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/form_input.dart';
import '../../widgets/mobile_app_wrapper.dart';

class ManageAspirationScreen extends StatefulWidget {
  const ManageAspirationScreen({super.key});

  @override
  State<ManageAspirationScreen> createState() => _ManageAspirationScreenState();
}

class _ManageAspirationScreenState extends State<ManageAspirationScreen> {
  List<AspirationModel> _aspirations = [];
  final List<String> _statuses = ['Menunggu', 'Diproses', 'Dibalas'];

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  void _refreshList() {
    setState(() {
      _aspirations = DataService.instance.getAspirations();
    });
  }

  Future<void> _openAspirationForm([AspirationModel? aspiration]) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: aspiration?.name ?? '');
    final messageController = TextEditingController(text: aspiration?.message ?? '');
    final replyController = TextEditingController(text: aspiration?.reply ?? '');
    final dateController = TextEditingController(text: aspiration?.date ?? DateFormat('dd MMM yyyy', 'id_ID').format(DateTime.now()));
    String statusValue = aspiration?.status ?? 'Menunggu';

    Future<void> pickDate() async {
      final initial = DateTime.tryParse(aspiration?.date ?? '') ?? DateTime.now();
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
              return Padding(
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
                          aspiration == null ? 'Tambah Aspirasi' : 'Edit Aspirasi',
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        FormInput(
                          controller: nameController,
                          label: 'Nama Pengirim',
                          hintText: 'Contoh: Andi',
                          prefixIcon: const Icon(Icons.person),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nama wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        FormInput(
                          controller: messageController,
                          label: 'Pesan Aspirasi',
                          hintText: 'Tulis aspirasi masuk',
                          prefixIcon: const Icon(Icons.message),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Pesan wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        FormInput(
                          controller: dateController,
                          label: 'Tanggal',
                          hintText: 'Pilih tanggal',
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
                        DropdownButtonFormField<String>(
                          initialValue: statusValue,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            labelStyle: GoogleFonts.poppins(fontSize: 13),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: _statuses
                              .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setModalState(() => statusValue = value);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        FormInput(
                          controller: replyController,
                          label: 'Balasan',
                          hintText: 'Isi jawaban jika ada',
                          prefixIcon: const Icon(Icons.reply),
                          maxLines: 3,
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
                              final newAspiration = AspirationModel(
                                id: aspiration?.id ?? '',
                                organizationId: DataService.instance.activeOrganizationId,
                                name: nameController.text.trim(),
                                message: messageController.text.trim(),
                                date: dateController.text.trim(),
                                status: statusValue,
                                reply: replyController.text.trim(),
                              );
                              if (aspiration == null) {
                                await DataService.instance.addAspiration(newAspiration);
                              } else {
                                await DataService.instance.updateAspiration(newAspiration);
                              }
                              if (!mounted) return;
                              sheetNavigator.pop();
                              _refreshList();
                              snackBarMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    aspiration == null ? 'Aspirasi berhasil ditambahkan' : 'Aspirasi berhasil diperbarui',
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
                              aspiration == null ? 'Simpan Aspirasi' : 'Perbarui Aspirasi',
                              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
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

  Future<void> _deleteAspiration(String id) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Hapus Aspirasi',
      content: 'Apakah Anda yakin ingin menghapus aspirasi ini?',
    );
    if (confirmed != true) return;

    final snackBarMessenger = ScaffoldMessenger.of(context);
    await DataService.instance.deleteAspiration(id);
    _refreshList();
    if (!mounted) return;
    snackBarMessenger.showSnackBar(
      SnackBar(
        content: Text('Aspirasi berhasil dihapus', style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Dibalas':
        return Colors.green;
      case 'Diproses':
        return Colors.orange;
      default:
        return Colors.grey;
    }
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
        title: Text('Kelola Aspirasi', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF6C3CBC),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAspirationForm(),
        backgroundColor: const Color(0xFF6C3CBC),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Tambah', style: GoogleFonts.poppins(color: Colors.white)),
      ),
      body: MobileAppWrapper(
        child: _aspirations.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.feedback, size: 52, color: Color(0xFF6C3CBC)),
                      const SizedBox(height: 16),
                      Text('Belum ada aspirasi masuk', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(
                        'Simpan aspirasi baru agar tim dapat menindaklanjuti kebutuhan mahasiswa dengan lebih cepat.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                itemCount: _aspirations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final aspiration = _aspirations[index];
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(aspiration.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text(aspiration.date, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => _openAspirationForm(aspiration),
                                  icon: const Icon(Icons.edit, color: Color(0xFF6C3CBC)),
                                ),
                                IconButton(
                                  onPressed: () => _deleteAspiration(aspiration.id),
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(aspiration.message, style: GoogleFonts.poppins(color: Colors.grey[800])),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _statusColor(aspiration.status).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(aspiration.status,
                                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _statusColor(aspiration.status))),
                            ),
                            if (aspiration.reply.isNotEmpty)
                              Text('Sudah dibalas', style: GoogleFonts.poppins(fontSize: 12, color: Colors.green)),
                          ],
                        ),
                        if (aspiration.reply.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C3CBC).withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(aspiration.reply, style: GoogleFonts.poppins(color: const Color(0xFF6C3CBC))),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
