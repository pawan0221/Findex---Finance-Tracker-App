import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class FamilyBudgetPage extends StatefulWidget {
  const FamilyBudgetPage({super.key});
  @override
  State<FamilyBudgetPage> createState() => _FamilyBudgetPageState();
}

class _FamilyBudgetPageState extends State<FamilyBudgetPage> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<_Member> _members = [];
  List<_SharedTx> _sharedTxs = [];
  bool _loading = true;
  String? _inviteCode;

  static String? get _uid  => FirebaseAuth.instance.currentUser?.uid;
  static String? get _email => FirebaseAuth.instance.currentUser?.email;
  static String? get _name  => FirebaseAuth.instance.currentUser?.displayName ?? 'You';

  DatabaseReference? get _groupRef {
    if (_uid == null) return null;
    return FirebaseDatabase.instance.ref('family_groups/$_uid');
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _loadData();
    _generateInviteCode();
  }

  void _generateInviteCode() {
    final code = _uid?.substring(0, 8).toUpperCase() ?? 'XXXXXXXX';
    setState(() => _inviteCode = 'FINDEX-$code');
  }

  void _loadData() {
    _groupRef?.child('members').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data == null) {
        // Add self as first member
        _groupRef?.child('members').child(_uid!).set({
          'name': _name, 'email': _email, 'role': 'admin',
          'budget': 10000, 'spent': 0, 'color': '0xFF8B6AFF',
        });
        return;
      }
      final map = Map<String, dynamic>.from(data as Map);
      setState(() {
        _members = map.entries.map((e) {
          final v = Map<String, dynamic>.from(e.value as Map);
          return _Member(
            id: e.key, name: v['name'] ?? 'Member', email: v['email'] ?? '',
            role: v['role'] ?? 'member', budget: (v['budget'] as num).toDouble(),
            spent: (v['spent'] as num).toDouble(),
            color: Color(int.parse(v['color'] ?? '0xFF8B6AFF')),
          );
        }).toList();
        _loading = false;
      });
    });

    _groupRef?.child('transactions').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data == null) { setState(() => _sharedTxs = []); return; }
      final map = Map<String, dynamic>.from(data as Map);
      setState(() {
        _sharedTxs = map.entries.map((e) {
          final v = Map<String, dynamic>.from(e.value as Map);
          return _SharedTx(
            id: e.key, title: v['title'] ?? '', amount: (v['amount'] as num).toDouble(),
            addedBy: v['addedBy'] ?? '', date: DateTime.parse(v['date']),
            category: v['category'] ?? '', isExpense: v['isExpense'] ?? true,
          );
        }).toList()..sort((a, b) => b.date.compareTo(a.date));
      });
    });
  }

  Future<void> _addSharedTransaction() async {
    final titleCtrl  = TextEditingController();
    final amountCtrl = TextEditingController();
    bool isExpense   = true;
    String category  = 'Food & Dining';

    await showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, set) => Container(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        decoration: const BoxDecoration(color: Color(0xFF0F1628), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Add Shared Transaction', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 20),

          // Toggle
          Container(
            decoration: BoxDecoration(color: const Color(0xFF1C2235), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Expanded(child: GestureDetector(onTap: () => set(() => isExpense = true),
                child: Container(padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: isExpense ? Colors.redAccent : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text('Expense', style: GoogleFonts.poppins(color: isExpense ? Colors.white : Colors.white54, fontWeight: FontWeight.w600)))))),
              Expanded(child: GestureDetector(onTap: () => set(() => isExpense = false),
                child: Container(padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: !isExpense ? Colors.green : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text('Income', style: GoogleFonts.poppins(color: !isExpense ? Colors.white : Colors.white54, fontWeight: FontWeight.w600)))))),
            ]),
          ),
          const SizedBox(height: 16),

          TextField(controller: amountCtrl, keyboardType: TextInputType.number,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            decoration: InputDecoration(hintText: '₹ 0', hintStyle: GoogleFonts.poppins(color: Colors.white24, fontSize: 28),
              border: InputBorder.none)),
          const SizedBox(height: 12),

          TextField(controller: titleCtrl, style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(hintText: 'Description...', hintStyle: GoogleFonts.poppins(color: Colors.white38),
              filled: true, fillColor: const Color(0xFF1C2235),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 24),

          GestureDetector(
            onTap: () async {
              final title  = titleCtrl.text.trim();
              final amount = double.tryParse(amountCtrl.text.replaceAll('₹', '').trim());
              if (title.isEmpty || amount == null) return;
              final id = DateTime.now().millisecondsSinceEpoch.toString();
              await _groupRef?.child('transactions/$id').set({
                'title': title, 'amount': amount, 'isExpense': isExpense,
                'addedBy': _name, 'category': category, 'date': DateTime.now().toIso8601String(),
              });
              // Update member spent
              final me = _members.firstWhere((m) => m.id == _uid, orElse: () => _members.first);
              if (isExpense) {
                await _groupRef?.child('members/$_uid').update({'spent': me.spent + amount});
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Container(width: double.infinity, height: 52,
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF5E5DF0), Color(0xFFFB466B)]), borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text('Add Transaction', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)))),
          ),
        ]),
      )),
    );
  }

  void _showInviteDialog() {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1C2235),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Invite Family Members', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Share this code with family members:', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(color: const Color(0xFF8B6AFF).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF8B6AFF).withOpacity(0.4))),
          child: Text(_inviteCode ?? '...', style: GoogleFonts.poppins(color: const Color(0xFFBCA9FF),
              fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2))),
        const SizedBox(height: 12),
        Text('They can join using this code in their Findex app', style: GoogleFonts.poppins(color: Colors.white24, fontSize: 11), textAlign: TextAlign.center),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Close', style: GoogleFonts.poppins(color: Colors.white54))),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B6AFF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: Text('Copy Code', style: GoogleFonts.poppins(color: Colors.white)),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final totalBudget = _members.fold(0.0, (s, m) => s + m.budget);
    final totalSpent  = _members.fold(0.0, (s, m) => s + m.spent);
    final sharedIncome  = _sharedTxs.where((t) => !t.isExpense).fold(0.0, (s, t) => s + t.amount);
    final sharedExpense = _sharedTxs.where((t) =>  t.isExpense).fold(0.0, (s, t) => s + t.amount);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1628),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Family Budget', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(icon: const Icon(Icons.person_add_outlined), onPressed: _showInviteDialog, tooltip: 'Invite'),
        ],
        bottom: TabBar(controller: _tab, labelColor: const Color(0xFF8B6AFF), unselectedLabelColor: Colors.white38,
          indicatorColor: const Color(0xFF8B6AFF),
          tabs: const [Tab(text: 'Overview'), Tab(text: 'Members'), Tab(text: 'Transactions')]),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF8B6AFF), onPressed: _addSharedTransaction,
        child: const Icon(Icons.add, size: 28)),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B6AFF)))
          : TabBarView(controller: _tab, children: [
              // Overview tab
              ListView(padding: const EdgeInsets.all(16), children: [
                Container(padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1E2A47), Color(0xFF4B3C93)]), borderRadius: BorderRadius.circular(20)),
                  child: Column(children: [
                    Text('Family Budget', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
                    const SizedBox(height: 8),
                    Text('₹${_fmt(totalSpent)} / ₹${_fmt(totalBudget)}',
                        style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 12),
                    ClipRRect(borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(value: totalBudget > 0 ? (totalSpent / totalBudget).clamp(0, 1) : 0,
                        minHeight: 10, backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          totalSpent > totalBudget ? Colors.redAccent : const Color(0xFF8B6AFF)))),
                    const SizedBox(height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                      _FamilyStat('Members', '${_members.length}', Colors.white),
                      _FamilyStat('Income', '₹${_fmt(sharedIncome)}', const Color(0xFF00E676)),
                      _FamilyStat('Expense', '₹${_fmt(sharedExpense)}', const Color(0xFFFF5252)),
                    ]),
                  ])),
                const SizedBox(height: 20),
                Text('Member Spending', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 12),
                ..._members.map((m) => _MemberSpendCard(member: m, totalSpent: totalSpent)),
              ]),

              // Members tab
              ListView(padding: const EdgeInsets.all(16), children: [
                ..._members.map((m) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF1C2235), borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    CircleAvatar(radius: 22, backgroundColor: m.color.withOpacity(0.2),
                      child: Text(m.name[0].toUpperCase(), style: GoogleFonts.poppins(color: m.color, fontWeight: FontWeight.bold, fontSize: 18))),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(m.name, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        if (m.role == 'admin') Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFF8B6AFF).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                          child: Text('Admin', style: GoogleFonts.poppins(color: const Color(0xFF8B6AFF), fontSize: 10))),
                      ]),
                      Text(m.email, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('₹${_fmt(m.spent)}', style: GoogleFonts.poppins(color: const Color(0xFFFF5252), fontWeight: FontWeight.w600)),
                      Text('Budget: ₹${_fmt(m.budget)}', style: GoogleFonts.poppins(color: Colors.white24, fontSize: 11)),
                    ]),
                  ]),
                )),
                const SizedBox(height: 12),
                GestureDetector(onTap: _showInviteDialog, child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF1C2235), borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF8B6AFF).withOpacity(0.3), style: BorderStyle.solid)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.person_add_outlined, color: Color(0xFF8B6AFF)),
                    const SizedBox(width: 10),
                    Text('Invite Family Member', style: GoogleFonts.poppins(color: const Color(0xFF8B6AFF), fontWeight: FontWeight.w600)),
                  ]),
                )),
              ]),

              // Transactions tab
              _sharedTxs.isEmpty
                  ? Center(child: Text('No shared transactions yet', style: GoogleFonts.poppins(color: Colors.white38)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _sharedTxs.length,
                      itemBuilder: (_, i) {
                        final tx = _sharedTxs[i];
                        final color = tx.isExpense ? const Color(0xFFFF5252) : const Color(0xFF00E676);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(color: const Color(0xFF1C2235), borderRadius: BorderRadius.circular(14)),
                          child: Row(children: [
                            Container(width: 40, height: 40,
                              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                              child: Icon(tx.isExpense ? Icons.arrow_upward : Icons.arrow_downward, color: color, size: 18)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(tx.title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                              Text('By ${tx.addedBy} • ${tx.date.day}/${tx.date.month}',
                                  style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
                            ])),
                            Text('${tx.isExpense ? '-' : '+'}₹${tx.amount.toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.w600)),
                          ]),
                        );
                      }),
            ]),
    );
  }

  static String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }
}

class _Member { final String id, name, email, role; final double budget, spent; final Color color;
  const _Member({required this.id, required this.name, required this.email, required this.role, required this.budget, required this.spent, required this.color}); }

class _SharedTx { final String id, title, addedBy, category; final double amount; final bool isExpense; final DateTime date;
  const _SharedTx({required this.id, required this.title, required this.amount, required this.addedBy, required this.date, required this.category, required this.isExpense}); }

class _FamilyStat extends StatelessWidget {
  final String label, value; final Color color;
  const _FamilyStat(this.label, this.value, this.color);
  @override Widget build(BuildContext context) => Column(children: [
    Text(value, style: GoogleFonts.poppins(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
    Text(label, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
  ]);
}

class _MemberSpendCard extends StatelessWidget {
  final _Member member; final double totalSpent;
  const _MemberSpendCard({required this.member, required this.totalSpent});
  @override Widget build(BuildContext context) {
    final ratio = member.budget > 0 ? (member.spent / member.budget).clamp(0.0, 1.0) : 0.0;
    return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF1C2235), borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Row(children: [
          CircleAvatar(radius: 18, backgroundColor: member.color.withOpacity(0.2),
            child: Text(member.name[0], style: GoogleFonts.poppins(color: member.color, fontWeight: FontWeight.bold))),
          const SizedBox(width: 12),
          Expanded(child: Text(member.name, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500))),
          Text('₹${member.spent.toStringAsFixed(0)} / ₹${member.budget.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(color: member.color, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: ratio, minHeight: 6, backgroundColor: Colors.white.withOpacity(0.08),
            valueColor: AlwaysStoppedAnimation<Color>(ratio > 0.9 ? Colors.redAccent : member.color))),
      ]));
  }
}