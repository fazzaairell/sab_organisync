import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../models/schedule_model.dart';
import '../models/activity_model.dart';
import '../services/data_service.dart';
import '../widgets/mobile_app_wrapper.dart';
import '../widgets/section_title.dart';
import '../widgets/confirm_dialog.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  List<ScheduleModel> _allSchedules = [];
  List<ActivityModel> _allActivities = [];

  static const Map<String, int> _monthNames = {
    'januari': 1, 'februari': 2, 'maret': 3, 'april': 4, 'mei': 5, 'juni': 6,
    'juli': 7, 'agustus': 8, 'september': 9, 'oktober': 10, 'november': 11, 'desember': 12,
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'jun': 6, 'jul': 7, 'agu': 8, 'sep': 9, 'okt': 10, 'nov': 11, 'des': 12
  };

  @override
  void initState() {
    super.initState();
    _loadEvents();
    DataService.instance.addListener(_loadEvents);
  }

  @override
  void dispose() {
    DataService.instance.removeListener(_loadEvents);
    super.dispose();
  }

  void _loadEvents() {
    setState(() {
      _allSchedules = DataService.instance.getSchedules();
      _allActivities = DataService.instance.getActivities();
    });
  }

  DateTime? _parseIndonesianDate(String rawDate) {
    final cleaned = rawDate.toLowerCase();
    final match = RegExp(r'(\d{1,2})\s+([a-z]+)\s+(\d{4})').firstMatch(cleaned);
    if (match == null) return null;
    final day = int.tryParse(match.group(1)!);
    final monthName = match.group(2)!;
    final year = int.tryParse(match.group(3)!);
    if (day == null || year == null) return null;
    final month = _monthNames[monthName];
    if (month == null) return null;
    return DateTime(year, month, day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final List<dynamic> events = [];

    // Filter schedules
    for (final s in _allSchedules) {
      final parsedDate = _parseIndonesianDate(s.date);
      if (parsedDate != null && _isSameDay(parsedDate, day)) {
        events.add(s);
      }
    }

    // Filter activities
    for (final a in _allActivities) {
      final parsedDate = _parseIndonesianDate(a.date);
      if (parsedDate != null && _isSameDay(parsedDate, day)) {
        events.add(a);
      }
    }

    return events;
  }

  void _showAddEditScheduleDialog({ScheduleModel? schedule}) {
    final isEdit = schedule != null;
    final titleController = TextEditingController(text: schedule?.title ?? '');
    final locationController = TextEditingController(text: schedule?.location ?? '');
    final timeController = TextEditingController(text: schedule?.time ?? '09.00 - 11.00 WIB');
    final categoryController = TextEditingController(text: schedule?.category ?? 'Rapat');

    DateTime selectedDate = _selectedDay;
    if (isEdit) {
      final parsed = _parseIndonesianDate(schedule.date);
      if (parsed != null) selectedDate = parsed;
    }

    int selectedColor = schedule?.color ?? 0xFF6C3CBC;

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
            );
            if (picked != null) {
              setModalState(() {
                selectedDate = picked;
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
                    isEdit ? 'Edit Agenda / Jadwal' : 'Tambah Agenda Baru',
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
                      labelText: 'Judul Agenda',
                      labelStyle: GoogleFonts.poppins(fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.event_note),
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
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: timeController,
                          decoration: InputDecoration(
                            labelText: 'Waktu (e.g. 10.00 WIB)',
                            labelStyle: GoogleFonts.poppins(fontSize: 13),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.access_time),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: categoryController,
                          decoration: InputDecoration(
                            labelText: 'Kategori (e.g. Rapat)',
                            labelStyle: GoogleFonts.poppins(fontSize: 13),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.label_outline),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: locationController,
                    decoration: InputDecoration(
                      labelText: 'Tempat / Lokasi',
                      labelStyle: GoogleFonts.poppins(fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pilih Warna Label:',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      0xFF6C3CBC,
                      0xFF2196F3,
                      0xFF4CAF50,
                      0xFFFF9800,
                      0xFFE91E63
                    ].map((colVal) {
                      final isSelected = selectedColor == colVal;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selectedColor = colVal;
                          });
                        },
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(colVal),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white, size: 18)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (titleController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Judul agenda tidak boleh kosong!')),
                          );
                          return;
                        }

                        // format day name in Indonesian
                        final dayName = DateFormat('EEEE', 'id').format(selectedDate);
                        final dateStr = '$dayName, ${DateFormat('dd MMMM yyyy', 'id').format(selectedDate)}';

                        if (isEdit) {
                          final updated = schedule.copyWith(
                            title: titleController.text.trim(),
                            date: dateStr,
                            time: timeController.text.trim(),
                            location: locationController.text.trim(),
                            category: categoryController.text.trim(),
                            color: selectedColor,
                          );
                          await DataService.instance.updateSchedule(updated);
                        } else {
                          final newSch = ScheduleModel(
                            id: '',
                            organizationId: DataService.instance.activeOrganizationId,
                            title: titleController.text.trim(),
                            date: dateStr,
                            time: timeController.text.trim(),
                            location: locationController.text.trim(),
                            category: categoryController.text.trim(),
                            color: selectedColor,
                          );
                          await DataService.instance.addSchedule(newSch);
                        }

                        _loadEvents();
                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEdit ? 'Agenda berhasil diperbarui! 🎉' : 'Agenda baru berhasil ditambahkan! 🎉',
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
                        isEdit ? 'Simpan Perubahan' : 'Tambah Agenda',
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

  void _confirmDeleteSchedule(ScheduleModel schedule) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Hapus Agenda',
      content: 'Apakah Anda yakin ingin menghapus agenda "${schedule.title}"?',
    );
    if (confirm == true) {
      await DataService.instance.deleteSchedule(schedule.id);
      _loadEvents();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agenda berhasil dihapus!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dayEvents = _getEventsForDay(_selectedDay);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditScheduleDialog(),
        backgroundColor: const Color(0xFF6C3CBC),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Tambah Agenda', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
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
                  Text(
                    'Kalender & Jadwal',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Agenda dan dokumentasi kegiatan organisasi',
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // TableCalendar Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Container(
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
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  eventLoader: _getEventsForDay,
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: const Color(0xFF9B59B6).withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Color(0xFF6C3CBC),
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: Color(0xFF9B59B6),
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 3,
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                    formatButtonDecoration: BoxDecoration(
                      color: const Color(0xFF6C3CBC).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    formatButtonTextStyle: GoogleFonts.poppins(
                      color: const Color(0xFF6C3CBC),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SectionTitle(
              title: 'Agenda ${DateFormat('dd MMMM yyyy', 'id').format(_selectedDay)}',
            ),
            // Events List
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: dayEvents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_note_outlined, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'Tidak ada agenda atau kegiatan pada tanggal ini.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: dayEvents.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final event = dayEvents[index];
                          if (event is ScheduleModel) {
                            return _buildScheduleItem(event);
                          } else if (event is ActivityModel) {
                            return _buildActivityItem(event);
                          }
                          return const SizedBox.shrink();
                        },
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleItem(ScheduleModel s) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Container(
            width: 4,
            height: 70,
            decoration: BoxDecoration(
              color: Color(s.color),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Color(s.color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'JADWAL: ${s.category}',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: Color(s.color),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.edit, size: 16, color: Colors.grey),
                          onPressed: () => _showAddEditScheduleDialog(schedule: s),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                          onPressed: () => _confirmDeleteSchedule(s),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  s.title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      s.time,
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.location_on, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        s.location,
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(ActivityModel a) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6C3CBC).withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Text(a.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C3CBC).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'DOKUMENTASI KEGIATAN',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: const Color(0xFF6C3CBC),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  a.title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  a.description,
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[700]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}