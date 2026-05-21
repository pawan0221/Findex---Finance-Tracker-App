import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class Bill {
  final String id;
  final String title;
  final String category;
  final double amount;
  final int dueDayOfMonth;
  final bool isPaid;
  final bool isRecurring;
  final Color color;
  final String emoji;

  const Bill({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.dueDayOfMonth,
    required this.isPaid,
    required this.isRecurring,
    required this.color,
    required this.emoji,
  });

  int get daysUntilDue {
    final now = DateTime.now();
    var due = DateTime(now.year, now.month, dueDayOfMonth);
    if (due.isBefore(now)) due = DateTime(now.year, now.month + 1, dueDayOfMonth);
    return due.difference(now).inDays;
  }

  bool get isOverdue => daysUntilDue < 0;
  bool get isDueSoon => daysUntilDue <= 3 && !isPaid;
}

class BillsPage extends StatefulWidget {
  const BillsPage({super.key});
  @override
  State<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  List<Bill> _bills = [];
  bool _loading = true;

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  static DatabaseReference? get _ref => _uid == null
      ? null : FirebaseDatabase.instance.ref('users/$_uid/bills');

  @override
  void initState() {
    super.initState();
    _ref?.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data == null) { setState(() { _bills = []; _loading = false; }); return; }
      final map = Map<String, dynamic>.from(data as Map);
      setState(() {
        _bills = map.entries.map((e) {
          final v = Map<String, dynamic>.from(e.value as Map);
          return Bill(
            id: e.key, title: v['title'] ?? '', category: v['category'] ?? '',
            amount: (v['amount'] as num).toDouble(),
            dueDayOfMonth: v['dueDayOfMonth'] ?? 1,
            isPaid: v['isPaid'] ?? false, isRecurring: v['isRecurring'] ?? true,
            color: Color(int.parse(v['color'] ?? '0xFF8B6AFF')),
            emoji: v['emoji'] ?? '📄',
          );
        }).toList()..sort((a, b) => a.daysUntilDue.compareTo(b.daysUntilDue));
        _loading = false;
      });
    });
  }

  Future<void> _togglePaid(Bill bill) async {
    await _ref?.child(bill.id).update({'isPaid': !bill.isPaid});
  }

  Future<void> _deleteBill(String id) async => await _ref?.child(id).remove();

  Future<void> _saveBill(Map<String, dynamic> data) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await _ref?.child(id).set(data);
  }

  void _showAddSheet() {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    int dueDay = 1;
    bool recurring = true;
    String emoji = '💡';
    Color color = const Color(0xFF8B6AFF);

    final emojis = ['💡','📱','🌊','🏠','📺','🚗','💳','🌐','🏥','📦','🎵','💰'];
    final colors = [const Color(0xFF8B6AFF), const Color(0xFF00E676), const Color(0xFFFF5252), const Color(0xFFFFB300), const Color(0xFF64B5F6), const Color(0xFFFF80AB)];

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, set) => Container(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        decoration: const BoxDecoration(color: Color(0xFF0F1628), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Add Bill Reminder', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 20),

          // Emoji
          Wrap(spacing: 8, children: emojis.map((e) => GestureDetector(
            onTap: () => set(() => emoji = e),
            child: Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: emoji == e ? const Color(0xFF8B6AFF).withOpacity(0.3) : const Color(0xFF1C2235), borderRadius: BorderRadius.circular(10),
                border: Border.all(color: emoji == e ? const Color(0xFF8B6AFF) : Colors.transparent)),
              child: Text(e, style: const TextStyle(fontSize: 20))),
          )).toList()),
          const SizedBox(height: 16),

          _fieldLabel('Bill Name'),
          _inputField(titleCtrl, 'e.g. Electricity, Netflix...'),
          const SizedBox(height: 14),
          _fieldLabel('Amount (₹)'),
          _inputField(amountCtrl, '0', type: TextInputType.number),
          const SizedBox(height: 14),

          _fieldLabel('Due Day of Month'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: const Color(0xFF1C2235), borderRadius: BorderRadius.circular(12)),
            child: DropdownButtonHideUnderline(child: DropdownButton<int>(
              value: dueDay, isExpanded: true, dropdownColor: const Color(0xFF1C2235),
              style: GoogleFonts.poppins(color: Colors.white),
              items: List.generate(28, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}${_suffix(i + 1)} of every month'))),
              onChanged: (v) => set(() => dueDay = v!),
            )),
          ),
          const SizedBox(height: 14),

          // Color
          Row(children: colors.map((c) => GestureDetector(
            onTap: () => set(() => color = c),
            child: Container(margin: const EdgeInsets.only(right: 10), width: 30, height: 30,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle,
                border: Border.all(color: color == c ? Colors.white : Colors.transparent, width: 2))),
          )).toList()),
          const SizedBox(height: 14),

          Row(children: [
            Text('Recurring monthly', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
            const Spacer(),
            Switch(value: recurring, onChanged: (v) => set(() => recurring = v), activeThumbColor: const Color(0xFF8B6AFF)),
          ]),
          const SizedBox(height: 24),

          GestureDetector(
            onTap: () {
              final title = titleCtrl.text.trim();
              final amount = double.tryParse(amountCtrl.text.trim());
              if (title.isEmpty || amount == null) return;
              _saveBill({'title': title, 'amount': amount, 'dueDayOfMonth': dueDay,
                'isPaid': false, 'isRecurring': recurring, 'color': color.value.toString(),
                'emoji': emoji, 'category': 'Bills'});
              Navigator.pop(ctx);
            },
            child: Container(width: double.infinity, height: 52,
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF5E5DF0), Color(0xFFFB466B)]), borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text('Save Bill', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white))),
            ),
          ),
        ])),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unpaid = _bills.where((b) => !b.isPaid).toList();
    final paid   = _bills.where((b) => b.isPaid).toList();
    final totalDue = unpaid.fold(0.0, (s, b) => s + b.amount);
    final overdue  = unpaid.where((b) => b.isOverdue).length;
    final dueSoon  = unpaid.where((b) => b.isDueSoon).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1628),
      appBar: AppBar(backgroundColor: Colors.transparent,
          title: Text('Bill Reminders', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
      floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF8B6AFF), onPressed: _showAddSheet,
          child: const Icon(Icons.add, size: 28)),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B6AFF)))
          : _bills.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('📄', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text('No bills added yet', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 16)),
                  Text('Tap + to add a bill reminder', style: GoogleFonts.poppins(color: Colors.white24, fontSize: 13)),
                ]))
              : ListView(padding: const EdgeInsets.all(16), children: [
                  // Summary
                  Container(padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1E2A47), Color(0xFF4B3C93)]), borderRadius: BorderRadius.circular(20)),
                    child: Column(children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Total Due', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
                        if (overdue > 0) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                          child: Text('$overdue overdue', style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 12))),
                      ]),
                      const SizedBox(height: 6),
                      Text('₹${_fmt(totalDue)}', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                      if (dueSoon > 0) ...[
                        const SizedBox(height: 8),
                        Text('⚠️ $dueSoon bill${dueSoon > 1 ? 's' : ''} due within 3 days',
                            style: GoogleFonts.poppins(color: Colors.orangeAccent, fontSize: 13)),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 20),

                  if (unpaid.isNotEmpty) ...[
                    Text('Upcoming Bills', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 10),
                    ...unpaid.map((b) => _BillCard(bill: b, onToggle: () => _togglePaid(b), onDelete: () => _deleteBill(b.id))),
                    const SizedBox(height: 16),
                  ],

                  if (paid.isNotEmpty) ...[
                    Text('Paid', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white54)),
                    const SizedBox(height: 10),
                    ...paid.map((b) => _BillCard(bill: b, onToggle: () => _togglePaid(b), onDelete: () => _deleteBill(b.id))),
                  ],
                ]),
    );
  }

  static String _suffix(int d) {
    if (d >= 11 && d <= 13) return 'th';
    switch (d % 10) { case 1: return 'st'; case 2: return 'nd'; case 3: return 'rd'; default: return 'th'; }
  }

  static String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  Widget _fieldLabel(String t) => Padding(padding: const EdgeInsets.only(bottom: 8),
      child: Text(t, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)));

  Widget _inputField(TextEditingController ctrl, String hint, {TextInputType type = TextInputType.text}) =>
    TextField(controller: ctrl, keyboardType: type, style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.poppins(color: Colors.white38),
        filled: true, fillColor: const Color(0xFF1C2235),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)));
}

class _BillCard extends StatelessWidget {
  final Bill bill;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  const _BillCard({required this.bill, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final daysLeft = bill.daysUntilDue;
    final dueText  = bill.isPaid ? 'Paid ✓' : bill.isOverdue ? 'Overdue!' : daysLeft == 0 ? 'Due today!' : 'Due in $daysLeft days';
    final dueColor = bill.isPaid ? Colors.greenAccent : bill.isOverdue ? Colors.redAccent : daysLeft <= 3 ? Colors.orangeAccent : Colors.white54;

    return Dismissible(
      key: Key(bill.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bill.isPaid ? const Color(0xFF1C2235).withOpacity(0.5) : const Color(0xFF1C2235),
          borderRadius: BorderRadius.circular(14),
          border: bill.isDueSoon ? Border.all(color: Colors.orangeAccent.withOpacity(0.4)) : null,
        ),
        child: Row(children: [
          Text(bill.emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(bill.title, style: GoogleFonts.poppins(color: bill.isPaid ? Colors.white38 : Colors.white,
                fontWeight: FontWeight.w500, fontSize: 14,
                decoration: bill.isPaid ? TextDecoration.lineThrough : null)),
            Text(dueText, style: GoogleFonts.poppins(color: dueColor, fontSize: 12)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('₹${bill.amount.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(color: bill.isPaid ? Colors.white38 : bill.color,
                    fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 4),
            GestureDetector(onTap: onToggle, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: bill.isPaid ? Colors.greenAccent.withOpacity(0.1) : const Color(0xFF8B6AFF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(bill.isPaid ? 'Undo' : 'Mark Paid',
                  style: GoogleFonts.poppins(fontSize: 11, color: bill.isPaid ? Colors.greenAccent : const Color(0xFF8B6AFF), fontWeight: FontWeight.w500)),
            )),
          ]),
        ]),
      ),
    );
  }
}