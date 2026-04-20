import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:maiz_app/screens/home_agricultor.dart';
import 'package:maiz_app/screens/login_screen.dart';
import 'package:maiz_app/services/db_service.dart';
import 'package:maiz_app/services/navigation_service.dart';
import 'package:maiz_app/services/session_service.dart';
import 'package:maiz_app/services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // load environment variables (must be called before any service that uses them)
  // during development, you should place a .env file in the project root.
  // if the file is not bundled (e.g. when running on a device) the package
  // throws FileNotFoundError; we catch it so the app can still start using
  // the hard‑coded fallback in ApiService.baseUrl.
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // ignore missing file; this is expected on a fresh install
    print("⚠️ .env not found, using defaults: $e");
  }

  await DBService.database;

  final connectivity = await Connectivity().checkConnectivity();
  if (connectivity != ConnectivityResult.none) {
    await SyncService.syncOfflineData();
  }

  SyncService.startSyncListener();
  Widget initialHome = const LoginScreen();

  final restored = await SessionService.loadPersistedUser();
  if (restored &&
      SessionService.userId != null &&
      (SessionService.userRole ?? '').trim() == 'Agricultor') {
    initialHome = HomeAgricultor(
      userName: SessionService.userName ?? 'Agricultor',
      userId: SessionService.userId!,
    );
  }

  runApp(MaizApp(initialHome: initialHome, navigatorKey: appNavigatorKey));
}

class MaizApp extends StatelessWidget {
  final Widget initialHome;
  final GlobalKey<NavigatorState> navigatorKey;

  const MaizApp(
      {super.key, required this.initialHome, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          primary: const Color(0xFF2E7D32),
          secondary: const Color(0xFF388E3C),
          background: const Color(0xFFF5F7FA),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF2E7D32),
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Color(0xFF2E7D32),
          unselectedItemColor: Colors.grey,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
      navigatorKey: navigatorKey,
      home: initialHome,
    );
  }
}
