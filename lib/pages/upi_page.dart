import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class UpiPage extends StatefulWidget {
  const UpiPage({super.key});
  @override
  State<UpiPage> createState() => _UpiPageState();
}

class _UpiPageState extends State<UpiPage> {
  List<_UpiAccount> _accounts = [];
  bool _loading = true;

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  static DatabaseReference? get _ref => _uid == null
      ? null : FirebaseDatabase.instance.ref('users/$_uid/upi_accounts');

  final List<Map<String, dynamic>> _banks = [
    {'name': 'SBI', 'logo': '🏦', 'color': 0xFF1565C0, 'suffix': '@sbi'},
    {'name': 'HDFC', 'logo': '🏛️', 'color': 0xFF00897B, 'suffix': '@hdfcbank'},
    {'name': 'ICICI', 'logo': '🏢', 'color': 0xFFE65100, 'suffix': '@icici'},
    {'name': 'Axis', 'logo': '🏬', 'color': 0xFF6A1B9A, 'suffix': '@axisbank'},
    {'name': 'Kotak', 'logo': '🏪', 'color': 0xFFD84315, 'suffix': '@kotak'},
    {'name': 'Yes Bank', 'logo': '🏩', 'color': 0xFF2E7D32, 'suffix': '@yesbank'},
    {'name': 'PNB', 'logo': '🏦', 'color': 0xFF1A237E, 'suffix': '@pnb'},
    {'name': 'BOI', 'logo': '🏛️', 'color': 0xFF004D40, 'suffix': '@boi'},
  ];

  final List<Map<String, dynamic>> _upiApps = [
    {'name': 'GPay', 'emoji': '🟢', 'color': 0xFF1A73E8},
    {'name': 'PhonePe', 'emoji': '🟣', 'color': 0xFF5F259F},
    {'name': 'Paytm', 'emoji': '🔵', 'color': 0xFF00BAF2},
    {'name': 'BHIM', 'emoji': '🔴', 'color': 0xFF1565C0},
    {'name': 'Amazon Pay', 'emoji': '🟠', 'color': 0xFFFF9900},
    {'name': 'WhatsApp Pay', 'emoji': '🟢', 'color': 0xFF25D366},
  ];

  @override
  void initState() {
    super.initState();
    _ref?.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data == null) { setState(() { _accounts = []; _loading = false; }); return; }
      final map = Map<String, dynamic>.from(data as Map);
      setState(() {
        _accounts = map.entries.map((e) {
          final v = Map<String, dynamic>.from(e.value as Map);
          return _UpiAccount(
            id: e.key, upiId: v['upiId'] ?? '', bankName: v['bankName'] ?? '',
            accountName: v['accountName'] ?? '', logo: v['logo'] ?? '🏦',
            color: Color(int.parse(v['color'] ?? '0xFF8B6AFF')),
            isDefault: v['isDefault'] ?? false,
            balance: (v['balance'] as num?)?.toDouble() ?? 0,
          );
        }).toList();
        _loading = false;
      });
    });
  }

  Future<void> _addAccount(Map<String, dynamic> data) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await _ref?.child(id).set(data);
  }

  Future<void> _deleteAccount(String id) async => await _ref?.child(id).remove();

  Future<void> _setDefault(String id) async {
    for (final acc in _accounts) {
      await _ref?.child(acc.id).update({'isDefault': acc.id == id});
    }
  }

  void _showAddSheet() {
    final upiCtrl  = TextEditingController();
    final nameCtrl = TextEditingController();
    Map<String, dynamic>? selectedBank;
    bool isDefault = _accounts.isEmpty;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, set) => Container(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        decoration: const BoxDecoration(color: Color(0xFF0F1628), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Link UPI / Bank Account', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 6),
          Text('Your data is stored securely on Firebase', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 20),

          // Select bank
          Text('Select Bank', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 10),
          GridView.count(crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.1,
            children: _banks.map((b) => GestureDetector(
              onTap: () {
                set(() { selectedBank = b; upiCtrl.text = nameCtrl.text.toLowerCase().replaceAll(' ', '') + (b['suffix'] ?? ''); });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: selectedBank?['name'] == b['name'] ? Color(b['color'] as int).withOpacity(0.3) : const Color(0xFF1C2235),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selectedBank?['name'] == b['name'] ? Color(b['color'] as int) : Colors.transparent),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(b['logo'] as String, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(b['name'] as String, style: GoogleFonts.poppins(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
                ]),
              ),
            )).toList()),
          const SizedBox(height: 16),

          Text('Account Holder Name', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(controller: nameCtrl, style: GoogleFonts.poppins(color: Colors.white),
            onChanged: (v) {
              if (selectedBank != null) {
                set(() => upiCtrl.text = v.toLowerCase().replaceAll(' ', '') + (selectedBank!['suffix'] ?? ''));
              }
            },
            decoration: InputDecoration(hintText: 'e.g. Pawan Soni', hintStyle: GoogleFonts.poppins(color: Colors.white38),
              filled: true, fillColor: const Color(0xFF1C2235),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 14),

          Text('UPI ID', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(controller: upiCtrl, style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(hintText: 'yourname@bankname', hintStyle: GoogleFonts.poppins(color: Colors.white38),
              filled: true, fillColor: const Color(0xFF1C2235),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              suffixIcon: const Icon(Icons.verified_user_outlined, color: Colors.greenAccent, size: 20))),
          const SizedBox(height: 14),

          Row(children: [
            Text('Set as default account', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
            const Spacer(),
            Switch(value: isDefault, onChanged: (v) => set(() => isDefault = v), activeThumbColor: const Color(0xFF8B6AFF)),
          ]),
          const SizedBox(height: 24),

          GestureDetector(
            onTap: () {
              if (selectedBank == null || upiCtrl.text.isEmpty || nameCtrl.text.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Please fill all fields', style: GoogleFonts.poppins()), backgroundColor: Colors.redAccent));
                return;
              }
              _addAccount({
                'upiId': upiCtrl.text.trim(), 'bankName': selectedBank!['name'],
                'accountName': nameCtrl.text.trim(), 'logo': selectedBank!['logo'],
                'color': Color(selectedBank!['color'] as int).value.toString(),
                'isDefault': isDefault, 'balance': 0,
              });
              Navigator.pop(ctx);
            },
            child: Container(width: double.infinity, height: 52,
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF5E5DF0), Color(0xFFFB466B)]), borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text('Link Account', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)))),
          ),
        ])),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1628),
      appBar: AppBar(backgroundColor: Colors.transparent,
          title: Text('UPI & Bank Accounts', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
      floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF8B6AFF), onPressed: _showAddSheet,
          child: const Icon(Icons.add, size: 28)),
      body: ListView(padding: const EdgeInsets.all(16), children: [

        // Security notice
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.greenAccent.withOpacity(0.2))),
          child: Row(children: [
            const Icon(Icons.lock_outline, color: Colors.greenAccent, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text('Your UPI IDs are stored securely. We never store PINs or passwords.',
                style: GoogleFonts.poppins(color: Colors.greenAccent, fontSize: 12))),
          ]),
        ),
        const SizedBox(height: 20),

        if (_loading)
          const Center(child: CircularProgressIndicator(color: Color(0xFF8B6AFF)))
        else if (_accounts.isEmpty) ...[
          Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🏦', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('No accounts linked yet', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 16)),
            Text('Tap + to link your UPI / bank account', style: GoogleFonts.poppins(color: Colors.white24, fontSize: 13)),
          ])),
        ] else ...[
          Text('Linked Accounts', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 12),
          ..._accounts.map((acc) => Dismissible(
            key: Key(acc.id),
            direction: DismissDirection.endToStart,
            background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.delete_outline, color: Colors.redAccent)),
            onDismissed: (_) => _deleteAccount(acc.id),
            child: GestureDetector(
              onTap: () => _setDefault(acc.id),
              child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2235), borderRadius: BorderRadius.circular(16),
                  border: acc.isDefault ? Border.all(color: const Color(0xFF8B6AFF), width: 1.5) : null),
                child: Column(children: [
                  Row(children: [
                    Container(width: 48, height: 48,
                      decoration: BoxDecoration(color: acc.color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                      child: Center(child: Text(acc.logo, style: const TextStyle(fontSize: 24)))),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(acc.bankName, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                        if (acc.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFF8B6AFF).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                            child: Text('Default', style: GoogleFonts.poppins(color: const Color(0xFF8B6AFF), fontSize: 10, fontWeight: FontWeight.w600))),
                        ],
                      ]),
                      Text(acc.accountName, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                    ])),
                    const Icon(Icons.chevron_right, color: Colors.white24),
                  ]),
                  const SizedBox(height: 12),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      const Icon(Icons.account_balance_wallet_outlined, color: Colors.white54, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(acc.upiId, style: GoogleFonts.poppins(color: const Color(0xFFBCA9FF), fontSize: 13))),
                      GestureDetector(
                        onTap: () { Clipboard.setData(ClipboardData(text: acc.upiId));
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('UPI ID copied!', style: GoogleFonts.poppins()), backgroundColor: const Color(0xFF8B6AFF), behavior: SnackBarBehavior.floating)); },
                        child: const Icon(Icons.copy, color: Colors.white38, size: 16)),
                    ])),
                  const SizedBox(height: 6),
                  Text('Tap to set as default • Swipe left to remove', style: GoogleFonts.poppins(color: Colors.white12, fontSize: 10)),
                ]),
              ),
            ),
          )),
        ],

        const SizedBox(height: 24),
        Text('Supported UPI Apps', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 12),
        GridView.count(crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.3,
          children: _upiApps.map((app) => Container(
            decoration: BoxDecoration(color: const Color(0xFF1C2235), borderRadius: BorderRadius.circular(14)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(app['emoji'] as String, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(app['name'] as String, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
            ]),
          )).toList()),
      ]),
    );
  }
}

class _UpiAccount {
  final String id, upiId, bankName, accountName, logo;
  final Color color;
  final bool isDefault;
  final double balance;
  const _UpiAccount({required this.id, required this.upiId, required this.bankName,
    required this.accountName, required this.logo, required this.color,
    required this.isDefault, required this.balance});
}