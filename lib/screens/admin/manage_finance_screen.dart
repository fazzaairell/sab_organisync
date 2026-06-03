import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/finance_transaction_model.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/form_input.dart';
import '../../widgets/mobile_app_wrapper.dart';

class ManageFinanceScreen extends StatefulWidget {
  const ManageFinanceScreen({super.key});

  @override
  State<ManageFinanceScreen> createState() => _ManageFinanceScreenState();
}

class _ManageFinanceScreenState extends State<ManageFinanceScreen> {
  List<FinanceTransactionModel> _transactions = [];

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  void _refreshList() {
    setState(() {
      _transactions = DataService.instance.getFinanceTransactions();
    });
  }

  Future<void> _openTransactionForm([FinanceTransactionModel? transaction]) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: transaction?.title ?? '');
    final amountController = TextEditingController(
        text: transaction != null ? transaction.amount.toString() : '');
    final noteController = TextEditingController(text: transaction?.note ?? '');
    final dateController = TextEditingController(text: transaction?.date ?? '');
    String typeValue = transaction?.type ?? 'in';

    Future<void> pickDate() async {
      final initial = DateTime.tryParse(transaction?.date ?? '') ?? DateTime.now();
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
                          transaction == null ? 'Tambah Transaksi' : 'Edit Transaksi',
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        FormInput(
                          controller: titleController,
                          label: 'Judul',
                          hintText: 'Contoh: Dana Sponsor',
                          prefixIcon: const Icon(Icons.title),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Judul wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        FormInput(
                          controller: amountController,
                          label: 'Nominal',
                          hintText: 'Contoh: 1500000',
                          prefixIcon: const Icon(Icons.attach_money),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nominal wajib diisi';
                            }
                            final parsed = int.tryParse(value.replaceAll('.', '').replaceAll(',', ''));
                            if (parsed == null || parsed <= 0) {
                              return 'Nominal harus angka lebih besar dari 0';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: typeValue,
                          decoration: InputDecoration(
                            labelText: 'Tipe Transaksi',
                            labelStyle: GoogleFonts.poppins(fontSize: 13),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'in', child: Text('Pemasukan')),
                            DropdownMenuItem(value: 'out', child: Text('Pengeluaran')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setModalState(() => typeValue = value);
                            }
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
                        FormInput(
                          controller: noteController,
                          label: 'Keterangan',
                          hintText: 'Contoh: Dana untuk seminar',
                          prefixIcon: const Icon(Icons.notes),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Keterangan wajib diisi';
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
                              final amount = int.parse(amountController.text.replaceAll('.', '').replaceAll(',', ''));
                              final newTransaction = FinanceTransactionModel(
                                id: transaction?.id ?? '',
                                organizationId: DataService.instance.activeOrganizationId,
                                title: titleController.text.trim(),
                                amount: amount,
                                type: typeValue,
                                date: dateController.text.trim(),
                                note: noteController.text.trim(),
                              );
                              if (transaction == null) {
                                await DataService.instance.addFinanceTransaction(newTransaction);
                              } else {
                                await DataService.instance.updateFinanceTransaction(newTransaction);
                              }
                              if (!mounted) return;
                              sheetNavigator.pop();
                              _refreshList();
                              snackBarMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    transaction == null
                                        ? 'Transaksi berhasil ditambahkan'
                                        : 'Transaksi berhasil diperbarui',
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
                              transaction == null ? 'Simpan Transaksi' : 'Perbarui Transaksi',
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

  Future<void> _deleteTransaction(String id) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Hapus Transaksi',
      content: 'Apakah Anda yakin ingin menghapus transaksi ini?',
      confirmLabel: 'Hapus',
    );
    if (confirmed != true) return;

    final snackBarMessenger = ScaffoldMessenger.of(context);
    await DataService.instance.deleteFinanceTransaction(id);
    _refreshList();
    if (!mounted) return;
    snackBarMessenger.showSnackBar(
      SnackBar(
        content: Text('Transaksi berhasil dihapus', style: GoogleFonts.poppins()),
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
        title: Text('Kelola Keuangan', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF6C3CBC),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTransactionForm(),
        backgroundColor: const Color(0xFF6C3CBC),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Tambah', style: GoogleFonts.poppins(color: Colors.white)),
      ),
      body: MobileAppWrapper(
        child: _transactions.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.account_balance_wallet, size: 52, color: Color(0xFF6C3CBC)),
                      const SizedBox(height: 16),
                      Text('Belum ada transaksi', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(
                        'Tambahkan transaksi agar laporan keuangan lebih mudah dipantau.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                itemCount: _transactions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _transactions[index];
                  final isIncome = item.type == 'in';
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isIncome ? const Color(0xFF4CAF50).withOpacity(0.12) : const Color(0xFFEF5350).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                color: isIncome ? const Color(0xFF4CAF50) : const Color(0xFFEF5350),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text(item.date, style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12)),
                                ],
                              ),
                            ),
                            Text(
                              'Rp ${item.amount}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                color: isIncome ? const Color(0xFF4CAF50) : const Color(0xFFEF5350),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isIncome ? 'Pemasukan' : 'Pengeluaran',
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[800]),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(item.note, style: GoogleFonts.poppins(color: Colors.grey[800])),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _openTransactionForm(item),
                              icon: const Icon(Icons.edit, color: Color(0xFF6C3CBC)),
                              label: Text('Ubah', style: GoogleFonts.poppins(color: const Color(0xFF6C3CBC))),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () => _deleteTransaction(item.id),
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: Text('Hapus', style: GoogleFonts.poppins(color: Colors.red)),
                            ),
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
}
