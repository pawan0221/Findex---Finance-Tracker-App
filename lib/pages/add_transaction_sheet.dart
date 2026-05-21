import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/transaction.dart';
import '../models/transaction_service.dart';

void showAddTransactionSheet(BuildContext context, {VoidCallback? onAdded}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddTransactionSheet(onAdded: onAdded),
  );
}

class _AddTransactionSheet extends StatefulWidget {
  final VoidCallback? onAdded;
  const _AddTransactionSheet({this.onAdded});

  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  bool _isExpense = true;
  final _titleController  = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController   = TextEditingController();
  String _selectedCategory = expenseCategories[0];
  DateTime _selectedDate   = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<String> get _categories => _isExpense ? expenseCategories : incomeCategories;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFF8B6AFF), surface: Color(0xFF1C2235)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    final title      = _titleController.text.trim();
    final amountText = _amountController.text.trim();

    if (title.isEmpty) { _showError('Please enter a title'); return; }
    if (amountText.isEmpty || double.tryParse(amountText) == null) { _showError('Please enter a valid amount'); return; }

    setState(() => _saving = true);

    final tx = Transaction(
      id:        DateTime.now().millisecondsSinceEpoch.toString(),
      title:     title,
      amount:    double.parse(amountText),
      isExpense: _isExpense,
      category:  _selectedCategory,
      date:      _selectedDate,
      note:      _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    try {
      await TransactionService.add(tx);       // save to Firestore
      TransactionStore.add(tx);               // also update local store
      widget.onAdded?.call();
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transaction saved!', style: GoogleFonts.poppins()),
              backgroundColor: const Color(0xFF8B6AFF), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      _showError('Failed to save. Try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.poppins()), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F1628),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Add Transaction', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 20),

            // Type toggle
            Container(
              decoration: BoxDecoration(color: const Color(0xFF1C2235), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  _TypeTab('Expense', _isExpense, true,  () => setState(() { _isExpense = true;  _selectedCategory = expenseCategories[0]; })),
                  _TypeTab('Income',  !_isExpense, false, () => setState(() { _isExpense = false; _selectedCategory = incomeCategories[0]; })),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _Label('Amount (₹)'),
            _Field(controller: _amountController, hint: '0.00', keyboardType: TextInputType.number),
            const SizedBox(height: 16),

            _Label('Title'),
            _Field(controller: _titleController, hint: 'e.g. Coffee, Salary...'),
            const SizedBox(height: 16),

            _Label('Category'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: const Color(0xFF1C2235), borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1C2235),
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                ),
              ),
            ),
            const SizedBox(height: 16),

            _Label('Date'),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(color: const Color(0xFF1C2235), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: Colors.white54, size: 18),
                    const SizedBox(width: 10),
                    Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            _Label('Note (optional)'),
            _Field(controller: _noteController, hint: 'Add a note...'),
            const SizedBox(height: 28),

            GestureDetector(
              onTap: _saving ? null : _save,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF5E5DF0), Color(0xFFFB466B)], begin: Alignment.centerLeft, end: Alignment.centerRight),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: _saving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Save Transaction', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  final String label;
  final bool active;
  final bool isExpense;
  final VoidCallback onTap;
  const _TypeTab(this.label, this.active, this.isExpense, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? (isExpense ? Colors.redAccent : Colors.green) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(label,
              style: GoogleFonts.poppins(color: active ? Colors.white : Colors.white54, fontWeight: FontWeight.w600))),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white54)),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  const _Field({required this.controller, required this.hint, this.keyboardType = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF1C2235),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}