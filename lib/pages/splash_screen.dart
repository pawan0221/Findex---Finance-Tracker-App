import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;
  late Animation<double> _slide;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));

    _fade     = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)));
    _scale    = Tween<double>(begin: 0.5, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)));
    _slide    = Tween<double>(begin: 30, end: 0).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 0.7, curve: Curves.easeOut)));
    _progress = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.4, 1.0, curve: Curves.easeInOut)));

    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 3000), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    Navigator.pushReplacementNamed(context, user != null ? '/dashboard' : '/');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1628),
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5E5DF0), Color(0xFFFB466B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B6AFF).withOpacity(0.6),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded,
                        color: Colors.white, size: 58),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // App name
              FadeTransition(
                opacity: _fade,
                child: Transform.translate(
                  offset: Offset(0, _slide.value),
                  child: Column(
                    children: [
                      Text('Findex',
                          style: GoogleFonts.poppins(
                            fontSize: 44,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          )),
                      const SizedBox(height: 6),
                      Text('Your Personal Finance Tracker',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white38,
                            letterSpacing: 0.5,
                          )),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 70),

              // Progress bar
              FadeTransition(
                opacity: _fade,
                child: Column(
                  children: [
                    SizedBox(
                      width: 140,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progress.value,
                          minHeight: 3,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B6AFF)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Loading...',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.white24)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}