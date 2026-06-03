import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/inventory_model.dart';
import '../services/data_service.dart';
import '../widgets/mobile_app_wrapper.dart';
import '../widgets/section_title.dart';
import '../widgets/confirm_dialog.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<InventoryModel> _inventories = [];

  @override
  void initState() {
    super.initState();
    _loadInventories();
    DataService.instance.addListener(_loadInventories);
  }

  @override
  void dispose() {
    DataService.instance.removeListener(_loadInventories);
    super.dispose();
  }

  void _loadInventories() {
    setState(() {
      _inventories = DataService.instance.getInventories();
    });
  }

  void _showAddEditDialog({InventoryModel? item}) {
    final isEdit = item != null;
    final nameController = TextEditingController(text: item?.itemName ?? '');
    final quantityController = TextEditingController(text: item != null ? item.quantity.toString() : '');
    final locationController = TextEditingController(text: item?.location ?? '');
    
    String condition = item?.condition ?? 'Baik';
    final List<String> conditions = ['Sangat Baik', 'Baik', 'Rusak Ringan', 'Rusak Berat'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
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
                    isEdit ? 'Edit Barang' : 'Tambah Barang Baru',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6C3CBC),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Barang',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.inventory),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Jumlah',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.numbers),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: condition,
                          decoration: InputDecoration(
                            labelText: 'Kondisi',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.check_circle_outline),
                          ),
                          items: conditions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => condition = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: locationController,
                    decoration: InputDecoration(
                      labelText: 'Lokasi Penyimpanan',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama barang tidak boleh kosong')));
                          return;
                        }
                        
                        final qty = int.tryParse(quantityController.text) ?? 1;

                        if (isEdit) {
                          final updated = item.copyWith(
                            itemName: nameController.text.trim(),
                            quantity: qty,
                            condition: condition,
                            location: locationController.text.trim(),
                          );
                          await DataService.instance.updateInventory(updated);
                        } else {
                          final newInv = InventoryModel(
                            id: '',
                            organizationId: '', // Will be set by service
                            itemName: nameController.text.trim(),
                            quantity: qty,
                            condition: condition,
                            location: locationController.text.trim(),
                          );
                          await DataService.instance.addInventory(newInv);
                        }

                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isEdit ? 'Barang berhasil diupdate!' : 'Barang berhasil ditambahkan!'),
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
                        isEdit ? 'Simpan Perubahan' : 'Tambah Barang',
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

  void _confirmDelete(InventoryModel item) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Hapus Barang',
      content: 'Apakah Anda yakin ingin menghapus "${item.itemName}" dari inventaris?',
    );
    if (confirm == true) {
      await DataService.instance.deleteInventory(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Barang berhasil dihapus!')),
      );
    }
  }
  
  Color _getConditionColor(String condition) {
    switch (condition) {
      case 'Sangat Baik':
      case 'Baik':
        return Colors.green;
      case 'Rusak Ringan':
        return Colors.orange;
      case 'Rusak Berat':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: const Color(0xFF6C3CBC),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Tambah Barang', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
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
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'Manajemen Inventaris',
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
                      'Kelola aset dan inventaris organisasi Anda',
                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SectionTitle(title: 'Daftar Barang'),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _inventories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada barang di inventaris.',
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
                        itemCount: _inventories.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _inventories[index];
                          final condColor = _getConditionColor(item.condition);
                          
                          return InkWell(
                            onTap: () => _showAddEditDialog(item: item),
                            onLongPress: () => _confirmDelete(item),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
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
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6C3CBC).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.inventory, color: Color(0xFF6C3CBC)),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.itemName,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on, size: 12, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                              item.location.isEmpty ? 'Belum ditentukan' : item.location,
                                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${item.quantity} unit',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: condColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          item.condition,
                                          style: GoogleFonts.poppins(
                                            color: condColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
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
