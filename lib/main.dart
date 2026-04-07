import 'package:autohub/features/auth/presnetation/pages/login_page.dart';
import 'package:autohub/features/auth/presnetation/pages/reset_password.dart';
import 'package:autohub/features/auth/presnetation/provider/auth_provider.dart';
import 'package:autohub/features/car/presentation/pages/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';

import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';

import 'features/car/presentation/provider/car_provider.dart';
import 'features/car/presentation/provider/saved_cars_provider.dart';
import 'features/car/presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CarProvider()),
        ChangeNotifierProvider(create: (_) => SavedCarsProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AutoHUB',
        theme: AppTheme.lightTheme,
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();
  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();

    // ── Deep link listener ─────────────────────────
    _appLinks = AppLinks();
    _appLinks.uriLinkStream.listen((uri) {
      if (uri.path.contains('reset-password') && mounted) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ResetPasswordScreen()));
      }
    });

    // ── Load saved cars whenever auth state changes ─
    supabase.auth.onAuthStateChange.listen((data) {
      if (data.session != null && mounted) {
        context.read<SavedCarsProvider>().loadSavedCars();
      } else if (mounted) {
        context.read<SavedCarsProvider>().clearLocal();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Handle saved cars here instead of initState
        final session = snapshot.data?.session;
        if (session != null) {
          context.read<SavedCarsProvider>().loadSavedCars();
        } else if (snapshot.connectionState != ConnectionState.waiting) {
          context.read<SavedCarsProvider>().clearLocal();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return supabase.auth.currentSession != null
            ? const SplashScreen()
            : const LoginPage();
      },
    );
  }
}
