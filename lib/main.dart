import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xmihoyo/page/AnnouncementPage.dart';
import 'package:xmihoyo/provider/theme_provider.dart';
import 'package:xmihoyo/provider/announcement_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => AnnouncementProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: '游戏活动',
      theme: themeProvider.isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: AnnouncementPage(),
    );
  }
}
