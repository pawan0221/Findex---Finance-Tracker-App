import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.show_chart, color: Colors.orange, size: 32),
                        const SizedBox(width: 8),
                        Text(
                          "Findex",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 60),
                    const Text(
                      "Welcome to\nFindex",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Your accessible, intelligent platform\nfor mastering money.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/login'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF5E5DF0), Color(0xFFFB466B)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pinkAccent.withOpacity(0.4),
                              blurRadius: 10,
                              spreadRadius: 1,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            "Get Started",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/login'),
                      child: const Text(
                        "Already a user? Log In",
                        style: TextStyle(fontSize: 14, color: Colors.white70, decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}