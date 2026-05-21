import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _nameController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    final name     = _nameController.text.trim();
    final email    = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm  = _confirmController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user?.updateDisplayName(name);
      if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = switch (e.code) {
          'email-already-in-use' => 'An account already exists for this email.',
          'invalid-email'        => 'Please enter a valid email.',
          'weak-password'        => 'Password is too weak.',
          _                      => 'Sign up failed. Please try again.',
        };
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0C0E1C), Color(0xFF0F1628)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios, color: Colors.white70),
                ),
                const SizedBox(height: 30),

                Text("Create\nAccount",
                    style: GoogleFonts.poppins(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
                const SizedBox(height: 8),
                Text("Start tracking your finances today",
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.white54)),
                const SizedBox(height: 40),

                // Error box
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 13))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                _buildField(_nameController,     "Full Name",        Icons.person_outline,  false),
                const SizedBox(height: 16),
                _buildField(_emailController,    "Email",            Icons.email_outlined,   false, type: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _buildField(_passwordController, "Password",         Icons.lock_outline,     true),
                const SizedBox(height: 16),
                _buildField(_confirmController,  "Confirm Password", Icons.lock_outline,     true),
                const SizedBox(height: 36),

                // Sign up button — GestureDetector + Container (works on web)
                GestureDetector(
                  onTap: _loading ? null : _signup,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5E5DF0), Color(0xFFFB466B)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: Colors.pinkAccent.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Center(
                      child: _loading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text("Create Account", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: RichText(
                      text: TextSpan(
                        text: "Already have an account? ",
                        style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
                        children: [
                          TextSpan(
                            text: "Log In",
                            style: GoogleFonts.poppins(color: const Color(0xFF8B6AFF), fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon, bool isPassword,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      obscureText: isPassword && _obscure,
      keyboardType: type,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.white60),
        prefixIcon: Icon(icon, color: Colors.white54),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}