import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:audio_service/audio_service.dart'; // 🔥 Eklendi

// Servis ve Sayfalar
import 'services/isar_service.dart';
import 'services/app_settings.dart';
import 'services/audio_handler.dart'; // 🔥 Oluşturduğun handler dosyasını import et
import 'pages/workout_page.dart';
import 'pages/history_page.dart';
import 'pages/progress_page.dart';
import 'pages/settings_page.dart';
import 'pages/login_page.dart'; 

// 🔥 Global handler instance (Sayfalardan erişmek için)
late MyAudioHandler audioHandler;

Future<void> main() async {
  // 1. Flutter ve Splash Hazırlığı
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  // 🔥 EKRANI UYANIK TUT
  WakelockPlus.enable();

  // 🔥 1. ADIM: AUDIO SERVICE BAŞLATMA
  // Bu kısım işletim sistemine "Ben ses çalacağım, beni arka planda öldürme" der.
  audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.g39.fitness.audio',
      androidNotificationChannelName: 'G39 Antrenman Sesleri',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      notificationColor: Color(0xFF3B82F6),
    ),
  );

  // 🔥 2. ADIM: GLOBAL SES YAPILANDIRMASI (Apple Music Dostu)
  // category: playback + mixWithOthers = Apple Music kesilmez, beraber çalarlar.
  await AudioPlayer.global.setAudioContext(AudioContext(
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback, 
      options: [
        AVAudioSessionOptions.mixWithOthers, 
        AVAudioSessionOptions.duckOthers, // Bip çalarken arkadaki müziği hafif kısar
      ],
    ),
    android: AudioContextAndroid(
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.none, // Focus almazsan Spotify/Apple Music durmaz
    ),
  ));
  
  try {
    // 3. Temel Servisler
    await Firebase.initializeApp();
    await IsarService.init(); 
    await initializeDateFormatting('tr_TR', null);

    final settings = AppSettings();

    // 4. RevenueCat Ayarı
    await Purchases.setLogLevel(LogLevel.debug);
    await Purchases.configure(
      PurchasesConfiguration("goog_HnrwUHbcPDHQFuFFWOEECCQGlQa"), 
    );

    runApp(
      ChangeNotifierProvider<AppSettings>.value(
        value: settings,
        child: const FitnessApp(),
      ),
    );
  } catch (e) {
    debugPrint("G39 Kritik Başlatma Hatası: $e");
    runApp(
      ChangeNotifierProvider(
        create: (_) => AppSettings(),
        child: const FitnessApp(),
      ),
    );
  }
}

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    
    return MaterialApp(
      title: 'G39',
      debugShowCheckedModeBanner: false,
      themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        primaryColor: const Color(0xFF3B82F6),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      
      darkTheme: ThemeData(
        brightness: Brightness.dark, 
        scaffoldBackgroundColor: const Color(0xFF050816),
        useMaterial3: true,
        primaryColor: const Color(0xFF3B82F6),
        cardColor: const Color(0xFF101826),
        canvasColor: const Color(0xFF050816),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF101826),
        ),
      ),
      
      home: const AuthWrapper(), 
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.waiting) {
          FlutterNativeSplash.remove();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF050816),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
          );
        }

        return snapshot.hasData ? const MainPage() : const LoginPage();
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 0;

  final List<Widget> pages = [
    const WorkoutPage(),
    const HistoryPage(),
    const ProgressPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.watch<AppSettings>().darkMode;

    return Scaffold(
      body: IndexedStack(
        index: currentIndex, 
        children: pages
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        backgroundColor: isDark ? const Color(0xFF101826) : Colors.white,
        selectedItemColor: const Color(0xFF3B82F6),
        unselectedItemColor: isDark ? Colors.white38 : Colors.black38,
        onTap: (index) => setState(() => currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: "Antrenman"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "Geçmiş"),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: "Gelişim"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}