import 'package:autohub/features/auth/presnetation/pages/login_page.dart';
import 'package:autohub/features/car/presentation/pages/home_page.dart';
import 'package:autohub/features/car/presentation/provider/saved_cars_provider.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pinController;
  late AnimationController _textController;
  late AnimationController _taglineController;

  late Animation<double> _pinScale;
  late Animation<double> _pinOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _taglineOpacity;

  @override
  void initState() {
    super.initState();

    // Pin drop animation
    _pinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Text fade+slide
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Tagline fade
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _pinScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pinController, curve: Curves.elasticOut),
    );
    _pinOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pinController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeIn),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    await _pinController.forward();

    await Future.delayed(const Duration(milliseconds: 100));
    await _textController.forward();

    await Future.delayed(const Duration(milliseconds: 100));
    await _taglineController.forward();

    // Load saved cars while showing splash
    if (mounted) {
      final supabase = Supabase.instance.client;
      if (supabase.auth.currentUser != null) {
        await context.read<SavedCarsProvider>().loadSavedCars();
      }
    }

    await Future.delayed(const Duration(milliseconds: 800));
    _navigate();
  }

  void _navigate() {
    if (!mounted) return;
    final session = Supabase.instance.client.auth.currentSession;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            session != null ? const HomePage() : const LoginPage(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _textController.dispose();
    _taglineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Logo icon ──────────────────────────
            AnimatedBuilder(
              animation: _pinController,
              builder: (_, __) => Opacity(
                opacity: _pinOpacity.value,
                child: Transform.scale(
                  scale: _pinScale.value,
                  child: Image.asset(
                    'assets/images/autohub_logo.png',
                    width: 160,
                    height: 160,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── AUTOHUB text ───────────────────────
            AnimatedBuilder(
              animation: _textController,
              builder: (_, __) => FadeTransition(
                opacity: _textOpacity,
                child: SlideTransition(
                  position: _textSlide,
                  child: RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'AUTO',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A1F3A),
                            letterSpacing: 2,
                          ),
                        ),
                        TextSpan(
                          text: 'HUB',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A6FE8),
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ── Tagline ────────────────────────────
            AnimatedBuilder(
              animation: _taglineController,
              builder: (_, __) => Opacity(
                opacity: _taglineOpacity.value,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _line(),
                    const SizedBox(width: 10),
                    const Text(
                      'BUY  •  SELL  •  DRIVE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF888888),
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _line(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line() =>
      Container(width: 28, height: 1.5, color: const Color(0xFF1A6FE8));
}
