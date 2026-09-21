import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'audio/audio_manager.dart';
import 'models/player_data.dart';
import 'ui/screens/home_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for phone/tablet feel
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set immersive status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Init audio and player data settings
  await AudioManager().init();
  await PlayerData().init();

  runApp(const HaruCatsApp());
}

class HaruCatsApp extends StatelessWidget {
  const HaruCatsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Haru Cats: Cute Sliding Puzzle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: GameConstants.fontBrandon,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          primary: const Color(0xFFFF9800),
          secondary: const Color(0xFF4CAF50),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
