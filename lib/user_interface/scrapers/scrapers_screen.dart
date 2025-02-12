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
  late final bloc = context.read<ScraperBloc>();
  final ScrollController _scrollController = ScrollController();

  void _runScraper() {
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
        return SelectionArea(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Web Scraper'),
              centerTitle: true,
              actions: [
                if (state is ScraperLoaded)
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
                if (!bloc.hasMore) const Text('No more articles to load'),
                if (!bloc.hasMore) const Gap(8),
              ],
            ),
          ),
        );
      },
    );
  }
}
