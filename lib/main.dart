import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maura_scraper_ui/logical_interface/bloc/scraper_bloc.dart';
import 'package:maura_scraper_ui/network_interface/api_client.dart';
import 'package:maura_scraper_ui/user_interface/scrapers/scrapers_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<String> availableTags = [];
late SharedPreferences sharedPreferences;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  availableTags = await ApiClient().getTags();
  availableTags.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  sharedPreferences = await SharedPreferences.getInstance();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ScraperBloc(),
      child: MaterialApp(
        title: "Maura's Scraper",
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const ScrapersScreen(),
      ),
    );
  }
}
