import 'currency_converter_page.dart';
import 'savings_goals_page.dart';
import 'bills_page.dart';
import 'ai_insights_page.dart';
import 'export_page.dart';
import 'family_budget_page.dart';
import 'upi_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'upi_qr_page.dart';
import 'ai_assistant_page.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user  = FirebaseAuth.instance.currentUser;
    final name  = user?.displayName ?? 'User';
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF0F1628),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text("My Account", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.security),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecuritySettingsScreen())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 44,
              backgroundColor: const Color(0xFF8B6AFF),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 14),
            Text(name, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(email, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white54)),

            const SizedBox(height: 28),

            // Spending overview card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: const Color(0xFF1C2235), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Spending Overview", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text("₹12,521.10", style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(value: 0.63, minHeight: 7, backgroundColor: Colors.white12, color: Colors.pinkAccent),
                  ),
                  const SizedBox(height: 6),
                  Text("63% of monthly budget used", style: GoogleFonts.poppins(fontSize: 12, color: Colors.white38)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Menu items
            _MenuItem(
  icon: Icons.qr_code_scanner,
  label: "UPI QR & Payments",
  onTap: () => Navigator.push(context,
      MaterialPageRoute(builder: (_) => const UpiQrPage())),
),      

_MenuItem(
  icon: Icons.auto_awesome,
  label: "AI Financial Assistant",
  onTap: () => Navigator.push(context,
      MaterialPageRoute(builder: (_) => const AIAssistantPage())),
),


             _MenuItem(icon: Icons.currency_exchange, label: "Currency Converter",
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CurrencyConverterPage()))),
_MenuItem(icon: Icons.savings_outlined, label: "Savings Goals",
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavingsGoalsPage()))),
_MenuItem(icon: Icons.receipt_long, label: "Bill Reminders",
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BillsPage()))),
_MenuItem(icon: Icons.auto_awesome, label: "AI Insights",
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIInsightsPage()))),
_MenuItem(icon: Icons.download_outlined, label: "Export Report",
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExportPage()))),
_MenuItem(icon: Icons.group_outlined, label: "Family Budget",
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyBudgetPage()))),
_MenuItem(icon: Icons.account_balance_outlined, label: "UPI & Bank Accounts",
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UpiPage()))),
            


            _MenuItem(icon: Icons.history_rounded,  label: "Transaction History", onTap: () {}),
            _MenuItem(icon: Icons.lock_outline,     label: "Security Settings",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecuritySettingsScreen()))),
            _MenuItem(icon: Icons.people_outline,   label: "Invite Friends",      onTap: () {}),
            _MenuItem(icon: Icons.help_outline,     label: "Help & Support",      onTap: () {}),

            const SizedBox(height: 24),

            // Logout button
            GestureDetector(
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                }
              },
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 10),
                    Text("Log Out", style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 15)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: const Color(0xFF1C2235), borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Icon(icon, color: Colors.white54, size: 20),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14))),
            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }
}

// ── SECURITY SETTINGS ──
class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});
  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool twoFactor = true;
  bool biometric = false;
  bool securityQuestions = true;

  void _changePassword() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email != null) {
      FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent!', style: GoogleFonts.poppins()), backgroundColor: const Color(0xFF8B6AFF)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1628),
      appBar: AppBar(
        title: Text("Security Settings", style: GoogleFonts.poppins()),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildTile("Change Password", onTap: _changePassword),
          const SizedBox(height: 10),
          _buildSwitchTile("Two-Factor Authentication", twoFactor, (v) => setState(() => twoFactor = v)),
          _buildSwitchTile("Biometric Authentication", biometric, (v) {
            setState(() => biometric = v);
            if (v) showDialog(context: context, builder: (_) => const FingerprintAuthDialog());
          }),
          _buildSwitchTile("Security Questions", securityQuestions, (v) => setState(() => securityQuestions = v)),
          _buildTile("Login History", onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildTile(String title, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Expanded(child: Text(title, style: GoogleFonts.poppins(color: Colors.white))),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        title: Text(title, style: GoogleFonts.poppins(color: Colors.white)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: const Color(0xFF8B6AFF),
      ),
    );
  }
}

// ── FINGERPRINT DIALOG ──
class FingerprintAuthDialog extends StatelessWidget {
  const FingerprintAuthDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1C2233),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text("Fingerprint Login", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Scan your fingerprint to authorize your account",
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          const Icon(Icons.fingerprint, color: Colors.pinkAccent, size: 64),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.white70))),
      ],
    );
  }
}