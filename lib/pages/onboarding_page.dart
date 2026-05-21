import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _current = 0;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  final _pages = [
    _OnboardData(
      emoji: '💰',
      title: 'Track Every\nRupee',
      subtitle: 'Know exactly where your money goes. Log income and expenses in seconds.',
      gradient: [Color(0xFF5E5DF0), Color(0xFF8B6AFF)],
      features: ['Instant transaction logging', 'Smart categorization', 'Real-time balance'],
    ),
    _OnboardData(
      emoji: '📊',
      title: 'Visualize Your\nFinances',
      subtitle: 'Beautiful charts and AI insights help you understand your spending patterns.',
      gradient: [Color(0xFFE91E8C), Color(0xFFFB466B)],
      features: ['Interactive charts', 'AI spending insights', 'Monthly reports'],
    ),
    _OnboardData(
      emoji: '🎯',
      title: 'Achieve Your\nGoals',
      subtitle: 'Set savings goals, track budgets, and get alerts before you overspend.',
      gradient: [Color(0xFF00B09B), Color(0xFF00E676)],
      features: ['Savings goal tracker', 'Budget alerts', 'Bill reminders'],
    ),
    _OnboardData(
      emoji: '🔒',
      title: 'Safe &\nSecure',
      subtitle: 'Your data is protected with Firebase encryption. Share with family safely.',
      gradient: [Color(0xFFFF8C00), Color(0xFFFFB300)],
      features: ['Firebase encrypted', 'Family budget sharing', 'Export anytime'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_current < _pages.length - 1) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _skip() => Navigator.pushReplacementNamed(context, '/login');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1628),
      body: Stack(
        children: [
          // Background gradient that changes with page
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.lerp(const Color(0xFF0F1628), _pages[_current].gradient[0], 0.15)!,
                  const Color(0xFF0F1628),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Skip button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page indicators
                      Row(
                        children: List.generate(_pages.length, (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 6),
                          width: i == _current ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _current
                                ? _pages[_current].gradient[0]
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )),
                      ),
                      if (_current < _pages.length - 1)
                        GestureDetector(
                          onTap: _skip,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('Skip', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
                          ),
                        ),
                    ],
                  ),
                ),

                // Page content
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    onPageChanged: (i) {
                      setState(() => _current = i);
                      _animCtrl.reset();
                      _animCtrl.forward();
                    },
                    itemCount: _pages.length,
                    itemBuilder: (_, i) => FadeTransition(
                      opacity: _fadeAnim,
                      child: _OnboardSlide(data: _pages[i]),
                    ),
                  ),
                ),

                // Bottom buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Column(
                    children: [
                      // Next / Get Started button
                      GestureDetector(
                        onTap: _next,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _pages[_current].gradient,
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: _pages[_current].gradient[0].withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _current == _pages.length - 1 ? 'Get Started' : 'Next',
                                  style: GoogleFonts.poppins(
                                      fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _current == _pages.length - 1
                                      ? Icons.rocket_launch_rounded
                                      : Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      if (_current == _pages.length - 1) ...[
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                          child: RichText(
                            text: TextSpan(
                              text: 'Already have an account? ',
                              style: GoogleFonts.poppins(color: Colors.white38, fontSize: 14),
                              children: [
                                TextSpan(
                                  text: 'Log In',
                                  style: GoogleFonts.poppins(
                                      color: const Color(0xFF8B6AFF),
                                      fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardData {
  final String emoji, title, subtitle;
  final List<Color> gradient;
  final List<String> features;
  const _OnboardData({
    required this.emoji, required this.title,
    required this.subtitle, required this.gradient,
    required this.features,
  });
}

class _OnboardSlide extends StatelessWidget {
  final _OnboardData data;
  const _OnboardSlide({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Big emoji with glow
          Container(
            width: 140, height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [data.gradient[0].withOpacity(0.3), Colors.transparent],
              ),
            ),
            child: Center(
              child: Text(data.emoji, style: const TextStyle(fontSize: 72)),
            ),
          ),
          const SizedBox(height: 32),

          // Title
          Text(data.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 36, fontWeight: FontWeight.bold,
                  color: Colors.white, height: 1.15)),
          const SizedBox(height: 16),

          // Subtitle
          Text(data.subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 15, color: Colors.white54, height: 1.6)),
          const SizedBox(height: 36),

          // Feature pills
          ...data.features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: data.gradient[0].withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.check_rounded, color: data.gradient[0], size: 16),
                ),
                const SizedBox(width: 12),
                Text(f, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}