import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/announcement_model.dart';
import '../services/data_service.dart';
import '../widgets/mobile_app_wrapper.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/section_title.dart';

class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  List<AnnouncementModel> _announcements = [];
  String _selectedCategory = 'Semua';

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
    DataService.instance.addListener(_loadAnnouncements);
  }

  @override
  void dispose() {
    DataService.instance.removeListener(_loadAnnouncements);
    super.dispose();
  }

  void _loadAnnouncements() {
    setState(() {
      _announcements = DataService.instance.getAnnouncements();
    });
  }

  List<AnnouncementModel> _getFilteredAnnouncements() {
    if (_selectedCategory == 'Semua') {
      return _announcements;
    }
    return _announcements.where((a) => a.category == _selectedCategory).toList();
  }

  void _showAddEditAnnouncementDialog({AnnouncementModel? announcement}) {
    final isEdit = announcement != null;
    final titleController = TextEditingController(text: announcement?.title ?? '');
    final contentController = TextEditingController(text: announcement?.content ?? '');
    String category = announcement?.category ?? 'Umum';

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
          child: SingleChildScrollView(
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
                  isEdit ? 'Edit Pengumuman' : 'Buat Pengumuman Baru',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6C3CBC),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Judul Pengumuman (e.g. 📢 Info Ujian)',
                    labelStyle: GoogleFonts.poppins(fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.campaign_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Isi Pengumuman / Konten',
                    labelStyle: GoogleFonts.poppins(fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Kategori Pengumuman:',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['Umum', 'Penting', 'Keuangan'].map((cat) {
                    final isSelected = category == cat;
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          category = cat;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF6C3CBC) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          cat,
                          style: GoogleFonts.poppins(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Judul pengumuman tidak boleh kosong!')),
                        );
                        return;
                      }
                      if (contentController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Konten pengumuman tidak boleh kosong!')),
                        );
                        return;
                      }

                      if (isEdit) {
                        final updated = announcement.copyWith(
                          title: titleController.text.trim(),
                          content: contentController.text.trim(),
                          category: category,
                        );
                        await DataService.instance.updateAnnouncement(updated);
                      } else {
                        final newAnn = AnnouncementModel(
                          id: '',
                          organizationId: DataService.instance.activeOrganizationId,
                          title: titleController.text.trim(),
                          content: contentController.text.trim(),
                          date: 'Baru saja',
                          category: category,
                        );
                        await DataService.instance.addAnnouncement(newAnn);
                      }

                      _loadAnnouncements();
                      if (!mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEdit ? 'Pengumuman berhasil diperbarui! 🎉' : 'Pengumuman baru berhasil diterbitkan! 🎉',
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
                      isEdit ? 'Simpan Perubahan' : 'Terbitkan Pengumuman',
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
  }

  void _confirmDeleteAnnouncement(AnnouncementModel announcement) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Hapus Pengumuman',
      content: 'Apakah Anda yakin ingin menghapus pengumuman "${announcement.title}"?',
    );
    if (confirm == true) {
      await DataService.instance.deleteAnnouncement(announcement.id);
      _loadAnnouncements();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengumuman berhasil dihapus!')),
      );
    }
  }

  void _showAnnouncementOptions(AnnouncementModel announcement) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Color(0xFF6C3CBC)),
              title: Text('Edit Pengumuman', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                _showAddEditAnnouncementDialog(announcement: announcement);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text('Hapus Pengumuman', style: GoogleFonts.poppins(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteAnnouncement(announcement);
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'Penting':
        return Colors.red;
      case 'Keuangan':
        return Colors.green;
      default:
        return const Color(0xFF6C3CBC);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredAnnouncements = _getFilteredAnnouncements();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditAnnouncementDialog(),
        backgroundColor: const Color(0xFF6C3CBC),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Buat Pengumuman', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
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
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'Pusat Pengumuman',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 48),
                    child: Text(
                      'Informasi penting dan terbaru organisasi',
                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Category Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['Semua', 'Penting', 'Keuangan', 'Umum'].map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategory = cat;
                          });
                        }
                      },
                      selectedColor: const Color(0xFF6C3CBC),
                      labelStyle: GoogleFonts.poppins(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            const SectionTitle(title: 'Daftar Pengumuman'),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: filteredAnnouncements.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada pengumuman dalam kategori ini.',
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: filteredAnnouncements.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final a = filteredAnnouncements[index];
                          final color = _getCategoryColor(a.category);
                          return InkWell(
                            onTap: () => _showAnnouncementOptions(a),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          a.title,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          a.category.toUpperCase(),
                                          style: GoogleFonts.poppins(
                                            color: color,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    a.content,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[800],
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        a.date,
                                        style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 14, color: Colors.grey[400]),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Pilihan',
                                            style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500]),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
