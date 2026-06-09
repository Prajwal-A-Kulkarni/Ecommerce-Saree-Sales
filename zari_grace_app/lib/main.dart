import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/welcome_screen.dart';
import 'theme/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: const ZariGraceApp(),
    ),
  );
}

class ZariGraceApp extends StatelessWidget {
  const ZariGraceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zari & Grace',
      debugShowCheckedModeBanner: false,
      theme: BoutiqueTheme.darkTheme,
      home: const WelcomeScreen(),
    );
  }
}
