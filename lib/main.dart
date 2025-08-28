import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maura_scraper_ui/logical_interface/bloc/scraper_bloc.dart';
import 'package:maura_scraper_ui/network_interface/api_client.dart';
import 'package:maura_scraper_ui/user_interface/scrapers/scrapers_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/class_tag_model.dart';

List<TagModel> availableTags = [];
late SharedPreferences sharedPreferences;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool loading = true;
  bool takingAWhile = false;

  @override
  void initState() {
    super.initState();
    _initApp();
    _startTimer();
  }

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
        debugShowCheckedModeBanner: false,
        home: loading ? _buildLoading() : const ScrapersScreen(),
      ),
    );
  }

  Widget _buildLoading() {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 20),
          Center(
            child: Text(takingAWhile
                ? 'Loading from Cold Start... This can take up to 2 minutes'
                : 'Loading...',),
          ),
        ],
      ),
    );
  }

  Future<void> _initApp() async {
    availableTags = await ApiClient().getTags();
    availableTags
        .sort((a, b) => a.tag.toLowerCase().compareTo(b.tag.toLowerCase()));
    sharedPreferences = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && loading) {
        setState(() {
          takingAWhile = true;
        });
      }
    });
  }
}
