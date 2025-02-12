import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:maura_scraper_ui/logical_interface/bloc/scraper_bloc.dart';
import 'package:maura_scraper_ui/user_interface/scrapers/widgets/scraper_tile.dart';

class ScrapersScreen extends StatefulWidget {
  const ScrapersScreen({super.key});

  @override
  State<ScrapersScreen> createState() => _ScrapersScreenState();
}

class _ScrapersScreenState extends State<ScrapersScreen> {
  int knownLength = 0;
  late final bloc = context.read<ScraperBloc>();
  final ScrollController _scrollController = ScrollController();

  void _runScraper() {
    setState(() {
      knownLength = 0;
    });
    bloc.add(ResetScraper());
  }

  void _loadScraper() {
    bloc.add(GetScrapers());
  }

  @override
  void initState() {
    super.initState();
    _runScraper();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadScraper();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScraperBloc, ScraperState>(
      listener: (context, state) {},
      builder: (context, state) {
        if (state.scrapers.length > knownLength) {
          knownLength = state.scrapers.length;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Results Loaded'),
                duration: Duration(seconds: 1),
              ),
            );
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Web Scraper'),
            centerTitle: true,
            actions: [
              IconButton(
                onPressed: () => _runScraper(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: Column(
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                child: state is ScraperLoading || state is ScraperInitial
                    ? const Center(child: LinearProgressIndicator())
                    : const SizedBox.shrink(),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: state.scrapers.length,
                  itemBuilder: (context, index) =>
                      ScraperTile(scraper: state.scrapers[index]),
                ),
              ),
              const Gap(8),
            ],
          ),
        );
      },
    );
  }
}
