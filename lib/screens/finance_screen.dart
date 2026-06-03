import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/finance_transaction_model.dart';
import '../services/data_service.dart';
import '../widgets/mobile_app_wrapper.dart';
import '../widgets/stat_card.dart';
import '../widgets/confirm_dialog.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  List<FinanceTransactionModel> _transactions = [];
  int _totalIn = 0;
  int _totalOut = 0;
  int _saldo = 0;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    DataService.instance.addListener(_loadTransactions);
  }

  @override
  void dispose() {
    DataService.instance.removeListener(_loadTransactions);
    super.dispose();
  }

  void _loadTransactions() {
    final list = DataService.instance.getFinanceTransactions();
    final totalIn = list
        .where((t) => t.isIncome)
        .fold<int>(0, (sum, t) => sum + t.amount);
    final totalOut = list
        .where((t) => !t.isIncome)
        .fold<int>(0, (sum, t) => sum + t.amount);
    setState(() {
      _transactions = list;
      _totalIn = totalIn;
      _totalOut = totalOut;
      _saldo = totalIn - totalOut;
    });
  }

  void _showAddEditTransactionDialog({FinanceTransactionModel? transaction}) {
    final isEdit = transaction != null;
    final titleController = TextEditingController(text: transaction?.title ?? '');
    final amountController = TextEditingController(
      text: transaction != null ? transaction.amount.toString() : '',
    );
    final noteController = TextEditingController(text: transaction?.note ?? '');
    
    String transactionType = transaction?.type ?? 'in'; // 'in' or 'out'
    DateTime selectedDate = DateTime.now();

    if (isEdit) {
      try {
        final parsed = DateFormat('dd MMM yyyy', 'id').parse(transaction.date);
        selectedDate = parsed;
      } catch (_) {
        try {
          final parsed = DateFormat('dd MMMM yyyy', 'id').parse(transaction.date);
          selectedDate = parsed;
        } catch (_) {
          // default
        }
      }
    }

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
                    isEdit ? 'Edit Transaksi Keuangan' : 'Tambah Transaksi Baru',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6C3CBC),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Segmented type selector
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => transactionType = 'in'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: transactionType == 'in' ? Colors.green.withOpacity(0.15) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: transactionType == 'in' ? Colors.green : Colors.grey[400]!,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.arrow_downward, color: Colors.green),
                                const SizedBox(width: 6),
                                Text(
                                  'Pemasukan',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: transactionType == 'in' ? Colors.green : Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => transactionType = 'out'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: transactionType == 'out' ? Colors.red.withOpacity(0.15) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: transactionType == 'out' ? Colors.red : Colors.grey[400]!,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.arrow_upward, color: Colors.red),
                                const SizedBox(width: 6),
                                Text(
                                  'Pengeluaran',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: transactionType == 'out' ? Colors.red : Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Judul Transaksi',
                      labelStyle: GoogleFonts.poppins(fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.receipt_long_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Jumlah (Rp)',
                            labelStyle: GoogleFonts.poppins(fontSize: 13),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.attach_money),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => selectDate(context),
                        icon: const Icon(Icons.calendar_today, color: Color(0xFF6C3CBC), size: 18),
                        label: Text(
                          DateFormat('dd MMM yyyy').format(selectedDate),
                          style: GoogleFonts.poppins(color: Colors.black87, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          side: BorderSide(color: Colors.grey[400]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Catatan / Keterangan',
                      labelStyle: GoogleFonts.poppins(fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.note_alt_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (titleController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Judul transaksi tidak boleh kosong!')),
                          );
                          return;
                        }
                        final amount = int.tryParse(amountController.text) ?? 0;
                        if (amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Jumlah uang harus lebih besar dari 0!')),
                          );
                          return;
                        }

                        final dateStr = DateFormat('dd MMMM yyyy', 'id').format(selectedDate);

                        if (isEdit) {
                          final updated = transaction.copyWith(
                            title: titleController.text.trim(),
                            amount: amount,
                            type: transactionType,
                            date: dateStr,
                            note: noteController.text.trim(),
                          );
                          await DataService.instance.updateFinanceTransaction(updated);
                        } else {
                          final newTx = FinanceTransactionModel(
                            id: '',
                            organizationId: DataService.instance.activeOrganizationId,
                            title: titleController.text.trim(),
                            amount: amount,
                            type: transactionType,
                            date: dateStr,
                            note: noteController.text.trim(),
                          );
                          await DataService.instance.addFinanceTransaction(newTx);
                        }

                        _loadTransactions();
                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEdit ? 'Transaksi berhasil diperbarui! 🎉' : 'Transaksi baru berhasil dicatat! 🎉',
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
                        isEdit ? 'Simpan Perubahan' : 'Catat Transaksi',
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

  void _confirmDeleteTransaction(FinanceTransactionModel tx) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Hapus Transaksi',
      content: 'Apakah Anda yakin ingin menghapus catatan transaksi "${tx.title}"?',
    );
    if (confirm == true) {
      await DataService.instance.deleteFinanceTransaction(tx.id);
      _loadTransactions();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan transaksi berhasil dihapus!')),
      );
    }
  }

  void _showTransactionOptions(FinanceTransactionModel tx) {
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
              title: Text('Edit Transaksi', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                _showAddEditTransactionDialog(transaction: tx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text('Hapus Transaksi', style: GoogleFonts.poppins(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteTransaction(tx);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditTransactionDialog(),
        backgroundColor: const Color(0xFF6C3CBC),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Catat Keuangan', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: MobileAppWrapper(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
                    'Transparansi Keuangan',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 120,
                        child: StatCard(
                          label: 'Pemasukan',
                          value: 'Rp ${_formatAmount(_totalIn)}',
                          accentColor: Colors.green,
                          backgroundColor: Colors.green.withOpacity(0.12),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: StatCard(
                          label: 'Pengeluaran',
                          value: 'Rp ${_formatAmount(_totalOut)}',
                          accentColor: Colors.red,
                          backgroundColor: Colors.red.withOpacity(0.12),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: StatCard(
                          label: 'Saldo',
                          value: 'Rp ${_formatAmount(_saldo)}',
                          accentColor: Colors.black87,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // List Transaksi
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Riwayat Transaksi',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _transactions.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Belum ada transaksi keuangan tercatat.\nCatat pemasukan atau pengeluaran pertamamu!',
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
                              itemCount: _transactions.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final t = _transactions[index];
                                final isIn = t.isIncome;
                                return InkWell(
                                  onTap: () => _showTransactionOptions(t),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 6,
                                        )
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: isIn ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            isIn ? Icons.arrow_downward : Icons.arrow_upward,
                                            color: isIn ? Colors.green : Colors.red,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                t.title,
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                t.date,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  color: Colors.grey[600],
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${isIn ? '+' : '-'} Rp ${_formatAmount(t.amount)}',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            color: isIn ? Colors.green : Colors.red,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }
}