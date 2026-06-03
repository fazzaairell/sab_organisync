import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/aspiration_model.dart';
import '../services/data_service.dart';
import '../widgets/mobile_app_wrapper.dart';

class AspirationScreen extends StatefulWidget {
  const AspirationScreen({super.key});

  @override
  State<AspirationScreen> createState() => _AspirationScreenState();
}

class _AspirationScreenState extends State<AspirationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isAnonymous = false;

  List<AspirationModel> _aspirations = [];

  @override
  void initState() {
    super.initState();
    _loadAspirations();
    DataService.instance.addListener(_loadAspirations);
  }

  void _loadAspirations() {
    if (!mounted) return;
    setState(() {
      _aspirations = DataService.instance.getAspirations();
    });
  }

  @override
  void dispose() {
    DataService.instance.removeListener(_loadAspirations);
    super.dispose();
  }

  Future<void> _submitAspiration() async {
    if (_messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pesan aspirasi tidak boleh kosong!',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newAspiration = AspirationModel(
      id: '',
      organizationId: DataService.instance.activeOrganizationId,
      name: _isAnonymous
          ? 'Mahasiswa Anonim'
          : (_nameController.text.isEmpty ? 'Tanpa Nama' : _nameController.text),
      message: _messageController.text,
      date: 'Hari ini',
      status: 'Menunggu',
      reply: '',
    );

    await DataService.instance.addAspiration(newAspiration);
    setState(() {
      _aspirations = DataService.instance.getAspirations();
      _isAnonymous = false;
    });

    _nameController.clear();
    _messageController.clear();

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Aspirasi berhasil dikirim! 🎉',
            style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF6C3CBC),
      ),
    );
  }

  void _showSubmitDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
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
              Text('Kirim Aspirasi',
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // Checkbox anonim
              Row(
                children: [
                  Checkbox(
                    value: _isAnonymous,
                    activeColor: const Color(0xFF6C3CBC),
                    onChanged: (val) {
                      setModalState(() => _isAnonymous = val!);
                      setState(() => _isAnonymous = val!);
                    },
                  ),
                  Text('Kirim sebagai anonim',
                      style: GoogleFonts.poppins(fontSize: 13)),
                ],
              ),
              if (!_isAnonymous) ...[
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama (opsional)',
                    labelStyle: GoogleFonts.poppins(fontSize: 13),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Tulis aspirasimu...',
                  labelStyle: GoogleFonts.poppins(fontSize: 13),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.edit),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitAspiration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C3CBC),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Kirim Aspirasi',
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSubmitDialog,
        backgroundColor: const Color(0xFF6C3CBC),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Kirim Aspirasi',
            style: GoogleFonts.poppins(color: Colors.white)),
      ),
      body: MobileAppWrapper(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6C3CBC), Color(0xFF9B59B6)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Aspirasi Mahasiswa',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Sampaikan pendapat dan saranmu',
                      style: GoogleFonts.poppins(
                          color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // List Aspirasi
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _aspirations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.mark_chat_unread,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada aspirasi yang masuk.\nJadilah yang pertama menyampaikan pendapatmu!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _aspirations.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final a = _aspirations[index];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2))
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: const Color(0xFF6C3CBC).withOpacity(0.1),
                                          child: const Icon(Icons.person, size: 16, color: Color(0xFF6C3CBC)),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 120,
                                          child: Text(a.name,
                                              style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _statusColor(a.status).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(a.status,
                                          style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              color: _statusColor(a.status),
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(a.message,
                                    style: GoogleFonts.poppins(
                                        fontSize: 13, color: Colors.grey[800]),
                                    maxLines: 5,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text(a.date,
                                    style: GoogleFonts.poppins(
                                        fontSize: 11, color: Colors.grey)),
                                if (a.reply.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6C3CBC).withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFF6C3CBC).withOpacity(0.2)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.reply, size: 16, color: Color(0xFF6C3CBC)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(a.reply,
                                              style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: const Color(0xFF6C3CBC))),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}