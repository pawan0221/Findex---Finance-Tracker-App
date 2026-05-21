import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _googleLoading = false;
  bool _obscure = true;
  String? _error;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _validateEmail(String v) => setState(() =>
    _emailError = v.isEmpty ? null : (!v.contains('@') || !v.contains('.')) ? 'Invalid email format' : null);

  void _validatePassword(String v) => setState(() =>
    _passwordError = v.isEmpty ? null : v.length < 6 ? 'Min 6 characters' : null);

  // ── EMAIL LOGIN ──
  Future<void> _emailLogin() async {
    final email = _emailCtrl.text.trim();
    final pass  = _passwordCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) { setState(() => _error = 'Please fill all fields'); return; }
    if (_emailError != null || _passwordError != null) return;

    setState(() { _loading = true; _error = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: pass);
      if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
    } on FirebaseAuthException catch (e) {
      setState(() => _error = switch (e.code) {
        'user-not-found'     => 'No account found for this email.',
        'wrong-password'     => 'Incorrect password.',
        'invalid-credential' => 'Invalid email or password.',
        'too-many-requests'  => 'Too many attempts. Try later.',
        _                    => 'Login failed. Please try again.',
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── GOOGLE SIGN IN ──
  Future<void> _googleLogin() async {
    setState(() { _googleLoading = true; _error = null; });
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) { setState(() => _googleLoading = false); return; }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      setState(() => _error = 'Google sign-in failed. Try again.');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) { setState(() => _error = 'Enter your email first'); return; }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reset email sent!', style: GoogleFonts.poppins()), backgroundColor: const Color(0xFF8B6AFF)));
    } catch (_) {
      setState(() => _error = 'Could not send reset email.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final emailValid    = _emailError == null && _emailCtrl.text.isNotEmpty;
    final passwordValid = _passwordError == null && _passwordCtrl.text.isNotEmpty;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF0C0E1C), Color(0xFF0F1628)],
              begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  const Icon(Icons.show_chart, color: Colors.orange, size: 28),
                  const SizedBox(width: 8),
                  Text('Findex', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                ]),
                GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, '/dashboard'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text('Skip', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                  ),
                ),
              ]),

              const SizedBox(height: 40),
              Text('Welcome\nBack', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
              const SizedBox(height: 6),
              Text('Sign in to continue', style: GoogleFonts.poppins(fontSize: 14, color: Colors.white54)),
              const SizedBox(height: 30),

              // Error
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.redAccent.withOpacity(0.4))),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 13))),
                  ]),
                ),
                const SizedBox(height: 14),
              ],

              // Email field
              _buildField(_emailCtrl, 'Email', Icons.email_outlined, false,
                  type: TextInputType.emailAddress, onChanged: _validateEmail,
                  error: _emailError, valid: emailValid),
              const SizedBox(height: 14),

              // Password field
              _buildPasswordField(),
              const SizedBox(height: 10),

              // Forgot password
              Align(alignment: Alignment.centerRight,
                child: GestureDetector(onTap: _forgotPassword,
                  child: Text('Forgot Password?', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF8B6AFF))))),
              const SizedBox(height: 24),

              // Login button
              _GradientButton(
                label: 'Log In',
                loading: _loading,
                enabled: emailValid && passwordValid,
                colors: const [Color(0xFF5E5DF0), Color(0xFFFB466B)],
                onTap: _emailLogin,
              ),

              const SizedBox(height: 20),

              // Divider
              Row(children: [
                const Expanded(child: Divider(color: Colors.white12)),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or continue with', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12))),
                const Expanded(child: Divider(color: Colors.white12)),
              ]),

              const SizedBox(height: 20),

              // Social login buttons
              Row(children: [
                // Google
                Expanded(child: _SocialButton(
                  label: 'Google',
                  icon: '🇬',
                  loading: _googleLoading,
                  color: const Color(0xFF1C2235),
                  onTap: _googleLogin,
                )),
                const SizedBox(width: 12),
                // Phone OTP
                Expanded(child: _SocialButton(
                  label: 'Phone OTP',
                  icon: '📱',
                  loading: false,
                  color: const Color(0xFF1C2235),
                  onTap: () => Navigator.pushNamed(context, '/phone-login'),
                )),
              ]),

              const SizedBox(height: 32),

              // Sign up
              Center(child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/signup'),
                child: RichText(text: TextSpan(
                  text: "Don't have an account? ",
                  style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
                  children: [TextSpan(text: 'Sign Up',
                    style: GoogleFonts.poppins(color: const Color(0xFF8B6AFF), fontWeight: FontWeight.bold, fontSize: 14))],
                )),
              )),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon, bool isPassword,
      {TextInputType type = TextInputType.text, ValueChanged<String>? onChanged, String? error, bool valid = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: ctrl, keyboardType: type, onChanged: onChanged,
        style: GoogleFonts.poppins(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint, hintStyle: GoogleFonts.poppins(color: Colors.white38),
          prefixIcon: Icon(icon, color: valid ? Colors.greenAccent : Colors.white54),
          suffixIcon: valid ? const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20) : null,
          filled: true, fillColor: Colors.white.withOpacity(0.07),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: error != null ? Colors.redAccent : Colors.transparent)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: error != null ? Colors.redAccent : Colors.transparent)),
        ),
      ),
      if (error != null) ...[
        const SizedBox(height: 4),
        Text(error, style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 11)),
      ],
    ]);
  }

  Widget _buildPasswordField() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    TextField(
      controller: _passwordCtrl, obscureText: _obscure,
      onChanged: _validatePassword,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Password', hintStyle: GoogleFonts.poppins(color: Colors.white38),
        prefixIcon: Icon(Icons.lock_outline, color: _passwordError == null && _passwordCtrl.text.isNotEmpty ? Colors.greenAccent : Colors.white54),
        suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
          if (_passwordError == null && _passwordCtrl.text.isNotEmpty)
            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
          IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
            onPressed: () => setState(() => _obscure = !_obscure)),
        ]),
        filled: true, fillColor: Colors.white.withOpacity(0.07),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _passwordError != null ? Colors.redAccent : Colors.transparent)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _passwordError != null ? Colors.redAccent : Colors.transparent)),
      ),
    ),
    if (_passwordError != null) ...[
      const SizedBox(height: 4),
      Text(_passwordError!, style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 11)),
    ],
  ]);
}

// ── PHONE OTP LOGIN ──
class PhoneLoginPage extends StatefulWidget {
  const PhoneLoginPage({super.key});
  @override
  State<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends State<PhoneLoginPage> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl   = TextEditingController();
  bool _otpSent    = false;
  bool _loading    = false;
  String? _error;
  String? _verificationId;

  @override
  void dispose() { _phoneCtrl.dispose(); _otpCtrl.dispose(); super.dispose(); }

  Future<void> _sendOtp() async {
    if (kIsWeb) {
      setState(() => _error = 'Phone OTP works on Android only. Use Email or Google login on web.');
      return;
    }
    final phone = '+91${_phoneCtrl.text.trim()}';
    if (_phoneCtrl.text.trim().length != 10) {
      setState(() => _error = 'Enter valid 10-digit number'); return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
        },
        verificationFailed: (e) => setState(() {
          _error = 'Failed: ${e.message}'; _loading = false;
        }),
        codeSent: (verificationId, _) => setState(() {
          _verificationId = verificationId;
          _otpSent = true;
          _loading = false;
        }),
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      setState(() { _error = 'Error: $e'; _loading = false; });
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.trim().length != 6) { setState(() => _error = 'Enter 6-digit OTP'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!, smsCode: _otpCtrl.text.trim());
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
    } on FirebaseAuthException catch (e) {
      setState(() { _error = e.message ?? 'Invalid OTP'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF0C0E1C), Color(0xFF0F1628)],
              begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GestureDetector(onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios, color: Colors.white70)),
              const SizedBox(height: 20),
              if (kIsWeb) Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline, color: Colors.orangeAccent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Phone OTP works on Android. Use Email or Google login on web.',
                      style: GoogleFonts.poppins(color: Colors.orangeAccent, fontSize: 12))),
                ]),
              ),
              const SizedBox(height: 20),
              const Text('📱', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 16),
              Text(_otpSent ? 'Enter OTP' : 'Phone Login',
                  style: GoogleFonts.poppins(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Text(_otpSent
                  ? 'Enter the 6-digit OTP sent to +91 ${_phoneCtrl.text}'
                  : 'Enter your Indian mobile number',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.white54)),
              const SizedBox(height: 36),

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10)),
                  child: Text(_error!, style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 13)),
                ),
                const SizedBox(height: 16),
              ],

              if (!_otpSent) ...[
                // Phone number input
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(14)),
                    child: Text('+91', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, letterSpacing: 2),
                    decoration: InputDecoration(
                      hintText: '9876543210', hintStyle: GoogleFonts.poppins(color: Colors.white24),
                      counterText: '',
                      filled: true, fillColor: Colors.white.withOpacity(0.07),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  )),
                ]),
              ] else ...[
                // OTP input
                TextField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 12),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true, fillColor: Colors.white.withOpacity(0.07),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _loading ? null : _sendOtp,
                  child: Text('Resend OTP', style: GoogleFonts.poppins(color: const Color(0xFF8B6AFF), fontSize: 14)),
                ),
              ],

              const SizedBox(height: 32),
              _GradientButton(
                label: _otpSent ? 'Verify OTP' : 'Send OTP',
                loading: _loading,
                enabled: true,
                colors: const [Color(0xFF5E5DF0), Color(0xFFFB466B)],
                onTap: _otpSent ? _verifyOtp : _sendOtp,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── SHARED WIDGETS ──
class _GradientButton extends StatelessWidget {
  final String label;
  final bool loading, enabled;
  final List<Color> colors;
  final VoidCallback onTap;
  const _GradientButton({required this.label, required this.loading, required this.enabled, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: (enabled && !loading) ? onTap : null,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity, height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: enabled ? colors : [Colors.grey.shade800, Colors.grey.shade700]),
        borderRadius: BorderRadius.circular(30),
        boxShadow: enabled ? [BoxShadow(color: colors[0].withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))] : [],
      ),
      child: Center(child: loading
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(label, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))),
    ),
  );
}

class _SocialButton extends StatelessWidget {
  final String label, icon;
  final bool loading;
  final Color color;
  final VoidCallback onTap;
  const _SocialButton({required this.label, required this.icon, required this.loading, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: loading ? null : onTap,
    child: Container(
      height: 52,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12))),
      child: Center(child: loading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Row(mainAxisSize: MainAxisSize.min, children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(label, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            ])),
    ),
  );
}