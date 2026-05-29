import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Prevent Google Fonts from making network requests on startup
  GoogleFonts.config.allowRuntimeFetching = false;

  // Minimal sync setup before first frame
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
    ),
  );
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── runApp FIRST — shows the splash screen immediately ──────────────
  // Hive and WorkManager are intentionally initialized AFTER runApp so the
  // UI is never blocked. The 2-second splash delay gives them enough time.
  runApp(const ProviderScope(child: OneWaterApp()));

  // ── Heavy init AFTER the first frame is already visible ─────────────
  try {
    await Hive.initFlutter();
    await Hive.openBox('cache');
  } catch (_) {
    // Non-fatal: cache is simply unavailable; app works online-only
  }

  // Start background notification poll (non-blocking)
  BackgroundService.initialize().catchError((_) {});
}
