import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/activity_model.dart';
import '../services/data_service.dart';
import '../widgets/mobile_app_wrapper.dart';
import '../widgets/section_title.dart';
import '../widgets/confirm_dialog.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  List<ActivityModel> _activities = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadActivities();
    DataService.instance.addListener(_loadActivities);
  }

  @override
  void dispose() {
    DataService.instance.removeListener(_loadActivities);
    super.dispose();
  }

  void _loadActivities() {
    setState(() {
      _activities = DataService.instance.getActivities();
    });
  }

  Future<File?> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
    return null;
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final fileName = 'activity_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
      final storageRef = FirebaseStorage.instance.ref().child('activity_images').child(fileName);
      await storageRef.putFile(image);
      return await storageRef.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  void _showAddEditActivityDialog({ActivityModel? activity}) {
    final isEdit = activity != null;
    final titleController = TextEditingController(text: activity?.title ?? '');
    final descController = TextEditingController(text: activity?.description ?? '');
    final participantsController = TextEditingController(
      text: activity != null ? activity.participants.toString() : '10',
    );
    
    DateTime selectedDate = DateTime.now();
    if (isEdit) {
      // Try to parse the date from activity
      try {
        final parsed = DateFormat('dd MMM yyyy', 'id').parse(activity.date);
        selectedDate = parsed;
      } catch (_) {
        try {
          final parsed = DateFormat('dd MMMM yyyy', 'id').parse(activity.date);
          selectedDate = parsed;
        } catch (_) {
          // Keep current date
        }
      }
    }

    String emoji = activity?.emoji ?? '🎯';
    File? localImage;
    String? currentImagePath = activity?.imagePath;
    bool isNewImagePicked = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> selectDate(BuildContext context) async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF6C3CBC),
                      onPrimary: Colors.white,
                      onSurface: Colors.black87,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null && picked != selectedDate) {
              setModalState(() {
                selectedDate = picked;
              });
            }
          }

          Future<void> chooseImage(ImageSource source) async {
            final file = await _pickImage(source);
            if (file != null) {
              setModalState(() {
                localImage = file;
                isNewImagePicked = true;
              });
            }
          }

          return Padding(
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
                    isEdit ? 'Edit Kegiatan' : 'Tambah Kegiatan Baru',
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
                      labelText: 'Nama Kegiatan',
                      labelStyle: GoogleFonts.poppins(fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.event),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi Kegiatan',
                      labelStyle: GoogleFonts.poppins(fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.description),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => selectDate(context),
                          icon: const Icon(Icons.calendar_today, color: Color(0xFF6C3CBC)),
                          label: Text(
                            DateFormat('dd MMM yyyy').format(selectedDate),
                            style: GoogleFonts.poppins(color: Colors.black87),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey[400]!),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: participantsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Peserta',
                            labelStyle: GoogleFonts.poppins(fontSize: 13),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.people),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Emoji selection
                  Text(
                    'Pilih Icon/Emoji:',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['🤖', '🎯', '❤️', '💻', '🎨', '🚀', '📢', '📚'].map((e) {
                      final isSelected = emoji == e;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            emoji = e;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF6C3CBC).withOpacity(0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF6C3CBC) : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Text(e, style: const TextStyle(fontSize: 24)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Photo picker section
                  Text(
                    'Foto Kegiatan:',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (localImage != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            localImage!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                localImage = null;
                                isNewImagePicked = true; // Indicates image was removed
                                currentImagePath = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (currentImagePath != null && !isNewImagePicked)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: currentImagePath!.startsWith('http')
                              ? Image.network(
                                  currentImagePath!,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(currentImagePath!),
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                currentImagePath = null;
                                localImage = null;
                                isNewImagePicked = true;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => chooseImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library, color: Color(0xFF6C3CBC)),
                            label: Text('Galeri', style: GoogleFonts.poppins(color: Colors.black87)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey[400]!),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => chooseImage(ImageSource.camera),
                            icon: const Icon(Icons.photo_camera, color: Color(0xFF6C3CBC)),
                            label: Text('Kamera', style: GoogleFonts.poppins(color: Colors.black87)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey[400]!),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (titleController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nama kegiatan tidak boleh kosong!')),
                          );
                          return;
                        }

                        // Tampilkan loading upload
                        if (isNewImagePicked && localImage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Mengunggah foto kegiatan...')),
                          );
                        }

                        final dateStr = DateFormat('dd MMMM yyyy', 'id').format(selectedDate);
                        final participants = int.tryParse(participantsController.text) ?? 10;
                        
                        String? finalImagePath = currentImagePath;
                        if (isNewImagePicked) {
                          if (localImage != null) {
                            finalImagePath = await _uploadImage(localImage!);
                          } else {
                            finalImagePath = null;
                          }
                        }

                        if (isEdit) {
                          final updated = activity.copyWith(
                            title: titleController.text.trim(),
                            description: descController.text.trim(),
                            date: dateStr,
                            emoji: emoji,
                            participants: participants,
                            imagePath: finalImagePath,
                          );
                          await DataService.instance.updateActivity(updated);
                        } else {
                          final newAct = ActivityModel(
                            id: '',
                            organizationId: DataService.instance.activeOrganizationId,
                            title: titleController.text.trim(),
                            description: descController.text.trim(),
                            date: dateStr,
                            emoji: emoji,
                            participants: participants,
                            imagePath: finalImagePath,
                          );
                          await DataService.instance.addActivity(newAct);
                        }

                        _loadActivities();
                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEdit ? 'Kegiatan berhasil diperbarui! 🎉' : 'Kegiatan baru berhasil ditambahkan! 🎉',
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
                        isEdit ? 'Simpan Perubahan' : 'Tambah Kegiatan',
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteActivity(ActivityModel activity) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Hapus Kegiatan',
      content: 'Apakah Anda yakin ingin menghapus kegiatan "${activity.title}"? Dokumentasi ini akan hilang permanen.',
    );
    if (confirm == true) {
      await DataService.instance.deleteActivity(activity.id);
      _loadActivities();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kegiatan berhasil dihapus!')),
      );
    }
  }

  void _showActivityDetailBottomSheet(ActivityModel activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
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
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(activity.emoji, style: const TextStyle(fontSize: 40)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.title,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF6C3CBC),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                activity.date,
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                if (activity.imagePath != null && activity.imagePath!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: activity.imagePath!.startsWith('http')
                        ? Image.network(
                            activity.imagePath!,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 150,
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                              ),
                            ),
                          )
                        : Image.file(
                            File(activity.imagePath!),
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 150,
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Deskripsi',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  activity.description,
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[800], height: 1.5),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.people, color: Color(0xFF6C3CBC), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${activity.participants} Peserta Terlibat',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF6C3CBC),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showAddEditActivityDialog(activity: activity);
                        },
                        icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                        label: Text('Edit', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C3CBC),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDeleteActivity(activity);
                        },
                        icon: const Icon(Icons.delete_forever, color: Colors.red, size: 18),
                        label: Text('Hapus', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditActivityDialog(),
        backgroundColor: const Color(0xFF6C3CBC),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Tambah Kegiatan', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: MobileAppWrapper(
        child: Column(
          children: [
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
                  Text(
                    'Dokumentasi Kegiatan',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kelola dan pantau kegiatan organisasi',
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SectionTitle(title: 'Daftar Dokumentasi'),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _activities.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada dokumentasi kegiatan.\nYuk, buat kegiatan pertamamu!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _activities.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final a = _activities[index];
                          return InkWell(
                            onTap: () => _showActivityDetailBottomSheet(a),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(a.emoji, style: const TextStyle(fontSize: 32)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              a.title,
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    a.date,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 11,
                                                      color: Colors.grey[600],
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right, color: Colors.grey),
                                    ],
                                  ),
                                  if (a.imagePath != null && a.imagePath!.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: a.imagePath!.startsWith('http')
                                          ? Image.network(
                                              a.imagePath!,
                                              height: 120,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                height: 120,
                                                color: Colors.grey[100],
                                                child: const Center(
                                                  child: Icon(Icons.broken_image, color: Colors.grey),
                                                ),
                                              ),
                                            )
                                          : Image.file(
                                              File(a.imagePath!),
                                              height: 120,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                height: 120,
                                                color: Colors.grey[100],
                                                child: const Center(
                                                  child: Icon(Icons.broken_image, color: Colors.grey),
                                                ),
                                              ),
                                            ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    a.description,
                                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.people, size: 14, color: Color(0xFF6C3CBC)),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${a.participants} peserta',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: const Color(0xFF6C3CBC),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
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