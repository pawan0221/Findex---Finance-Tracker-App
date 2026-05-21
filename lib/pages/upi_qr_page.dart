import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class UpiQrPage extends StatefulWidget {
  const UpiQrPage({super.key});
  @override
  State<UpiQrPage> createState() => _UpiQrPageState();
}

class _UpiQrPageState extends State<UpiQrPage> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _amountCtrl    = TextEditingController();
  final _recipientCtrl = TextEditingController();
  final _noteCtrl      = TextEditingController();
  String _myUpiId      = '';
  String _myName       = '';
  bool _loadingUpi     = true;

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  final List<Map<String, dynamic>> _apps = [
    {'name': 'GPay',       'emoji': '🟢', 'color': 0xFF1A73E8, 'pkg': 'com.google.android.apps.nbu.paisa.user'},
    {'name': 'PhonePe',    'emoji': '🟣', 'color': 0xFF5F259F, 'pkg': 'com.phonepe.app'},
    {'name': 'Paytm',      'emoji': '🔵', 'color': 0xFF00BAF2, 'pkg': 'net.one97.paytm'},
    {'name': 'BHIM',       'emoji': '🔴', 'color': 0xFF1565C0, 'pkg': 'in.org.npci.upiapp'},
    {'name': 'Amazon Pay', 'emoji': '🟠', 'color': 0xFFFF9900, 'pkg': 'in.amazon.mShop.android.shopping'},
    {'name': 'WhatsApp',   'emoji': '💚', 'color': 0xFF25D366, 'pkg': 'com.whatsapp'},
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadMyUpiId();
    _myName = FirebaseAuth.instance.currentUser?.displayName ?? 'User';
  }

  Future<void> _loadMyUpiId() async {
    if (_uid == null) { setState(() => _loadingUpi = false); return; }
    final snap = await FirebaseDatabase.instance.ref('users/$_uid/upi_accounts').get();
    if (snap.exists) {
      final map = Map<String, dynamic>.from(snap.value as Map);
      final defaultAcc = map.values.firstWhere(
        (v) => (v as Map)['isDefault'] == true,
        orElse: () => map.values.first,
      );
      setState(() {
        _myUpiId = (defaultAcc as Map)['upiId'] ?? '';
        _loadingUpi = false;
      });
    } else {
      setState(() => _loadingUpi = false);
    }
  }

  String get _qrData {
    final amount = _amountCtrl.text.trim();
    var url = 'upi://pay?pa=$_myUpiId&pn=${Uri.encodeComponent(_myName)}&cu=INR';
    if (amount.isNotEmpty) url += '&am=$amount';
    if (_noteCtrl.text.isNotEmpty) url += '&tn=${Uri.encodeComponent(_noteCtrl.text.trim())}';
    return url;
  }

  Future<void> _sendViaApp(Map<String, dynamic> app) async {
    final to     = _recipientCtrl.text.trim();
    final amount = _amountCtrl.text.trim();
    final note   = _noteCtrl.text.trim().isEmpty ? 'Payment via Findex' : _noteCtrl.text.trim();

    if (to.isEmpty) { _snack('Enter recipient UPI ID', Colors.redAccent); return; }
    if (amount.isEmpty || double.tryParse(amount) == null) { _snack('Enter valid amount', Colors.redAccent); return; }

    final upiUrl = 'upi://pay?pa=$to&pn=${Uri.encodeComponent(_myName)}&am=$amount&cu=INR&tn=${Uri.encodeComponent(note)}';

    try {
      final uri = Uri.parse(upiUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Open Play Store
        final storeUri = Uri.parse('https://play.google.com/store/apps/details?id=${app['pkg']}');
        await launchUrl(storeUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      _snack('Could not open ${app['name']}', Colors.redAccent);
    }
  }

  void _copyUpi() {
    Clipboard.setData(ClipboardData(text: _myUpiId));
    _snack('UPI ID copied!', const Color(0xFF8B6AFF));
  }

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg, style: GoogleFonts.poppins()), backgroundColor: color, behavior: SnackBarBehavior.floating));

  @override
  void dispose() { _tab.dispose(); _amountCtrl.dispose(); _recipientCtrl.dispose(); _noteCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1628),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('UPI Payments', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        bottom: TabBar(
          controller: _tab,
          labelColor: const Color(0xFF8B6AFF),
          unselectedLabelColor: Colors.white38,
          indicatorColor: const Color(0xFF8B6AFF),
          tabs: const [Tab(text: '📷 Receive (QR)'), Tab(text: '💸 Send Money')],
        ),
      ),
      body: TabBarView(controller: _tab, children: [
        _buildReceiveTab(),
        _buildSendTab(),
      ]),
    );
  }

  Widget _buildReceiveTab() {
    return ListView(padding: const EdgeInsets.all(20), children: [
      // QR Card
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1E2A47), Color(0xFF4B3C93)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(children: [
          Text('My Payment QR', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 20),

          if (_loadingUpi)
            const CircularProgressIndicator(color: Color(0xFF8B6AFF))
          else if (_myUpiId.isEmpty)
            Column(children: [
              const Text('🏦', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text('No UPI ID linked', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(color: const Color(0xFF8B6AFF), borderRadius: BorderRadius.circular(12)),
                  child: Text('Link UPI Account', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600))),
              ),
            ])
          else ...[
            // QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: QrImageView(
                data: _qrData,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            Text(_myName, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),

            // UPI ID with copy
            GestureDetector(
              onTap: _copyUpi,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(_myUpiId, style: GoogleFonts.poppins(color: const Color(0xFFBCA9FF), fontSize: 13)),
                  const SizedBox(width: 8),
                  const Icon(Icons.copy, color: Colors.white38, size: 14),
                ]),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Amount for QR
          if (_myUpiId.isNotEmpty) ...[
            Text('Add Amount (Optional)', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixText: '₹ ', prefixStyle: GoogleFonts.poppins(color: Colors.white54, fontSize: 18),
                  hintText: '0', hintStyle: GoogleFonts.poppins(color: Colors.white24, fontSize: 18),
                  filled: true, fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              )),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => setState(() {}),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(color: const Color(0xFF8B6AFF), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.qr_code, color: Colors.white)),
              ),
            ]),
          ],
        ]),
      ),

      const SizedBox(height: 20),

      // Quick amounts
      Text('Quick Request', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
      const SizedBox(height: 12),
      Wrap(spacing: 10, runSpacing: 10, children: [100, 200, 500, 1000, 2000, 5000].map((amt) =>
        GestureDetector(
          onTap: () => setState(() => _amountCtrl.text = amt.toString()),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _amountCtrl.text == amt.toString()
                  ? const Color(0xFF8B6AFF).withOpacity(0.3) : const Color(0xFF1C2235),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _amountCtrl.text == amt.toString()
                  ? const Color(0xFF8B6AFF) : Colors.white12),
            ),
            child: Text('₹$amt', style: GoogleFonts.poppins(
                color: _amountCtrl.text == amt.toString() ? const Color(0xFFBCA9FF) : Colors.white54,
                fontWeight: FontWeight.w500)),
          ),
        ),
      ).toList()),
    ]);
  }

  Widget _buildSendTab() {
    return ListView(padding: const EdgeInsets.all(20), children: [
      // Input fields
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF1C2235), borderRadius: BorderRadius.circular(18)),
        child: Column(children: [
          // To UPI
          TextField(
            controller: _recipientCtrl,
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Recipient UPI ID (e.g. name@okaxis)',
              hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
              prefixIcon: const Icon(Icons.person_outline, color: Colors.white54),
              filled: true, fillColor: Colors.black26,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),

          // Amount
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              prefixText: '₹ ', prefixStyle: GoogleFonts.poppins(color: Colors.white54, fontSize: 28),
              hintText: '0', hintStyle: GoogleFonts.poppins(color: Colors.white24, fontSize: 28),
              filled: true, fillColor: Colors.black26,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),

          // Note
          TextField(
            controller: _noteCtrl,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Add note (optional)',
              hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
              prefixIcon: const Icon(Icons.note_outlined, color: Colors.white54, size: 20),
              filled: true, fillColor: Colors.black26,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),

          // Quick amounts
          Row(children: [100, 500, 1000, 2000].map((amt) => Expanded(child: GestureDetector(
            onTap: () => setState(() => _amountCtrl.text = amt.toString()),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text('₹$amt', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12))),
            ),
          ))).toList()),
        ]),
      ),

      const SizedBox(height: 24),
      Text('Choose Payment App', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
      const SizedBox(height: 12),

      // Apps grid
      GridView.count(
        crossAxisCount: 3, shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.05,
        children: _apps.map((app) => GestureDetector(
          onTap: () => _sendViaApp(app),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C2235), borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(app['color'] as int).withOpacity(0.25)),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 46, height: 46,
                decoration: BoxDecoration(color: Color(app['color'] as int).withOpacity(0.15), shape: BoxShape.circle),
                child: Center(child: Text(app['emoji'] as String, style: const TextStyle(fontSize: 24)))),
              const SizedBox(height: 8),
              Text(app['name'] as String, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
              const SizedBox(height: 2),
              Text('Tap to pay', style: GoogleFonts.poppins(color: Colors.white24, fontSize: 9)),
            ]),
          ),
        )).toList(),
      ),

      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFF1C2235), borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('💡 How to send money', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          Text('1. Enter recipient UPI ID\n2. Enter the amount\n3. Tap any payment app\n4. App opens with pre-filled details\n5. Confirm & pay securely in the app',
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12, height: 1.7)),
        ]),
      ),
    ]);
  }
}