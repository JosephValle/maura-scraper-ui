import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maura_scraper_ui/logical_interface/bloc/scraper_bloc.dart';
import 'package:maura_scraper_ui/user_interface/scrapers/scrapers_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ScraperBloc(),
      child: MaterialApp(
        title: 'Maura\'s Scraper',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const ScrapersScreen(),
      ),
    );
  }
}
