import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  /// Reset the scraper and load the first page of articles.
  void _runScraper() {
    bloc.add(ResetScraper());
  }

  /// Load the next page of articles.
  void _loadScraper() {
    bloc.add(GetScrapers());
  }

  @override
  void initState() {
    super.initState();
    _loadScraper();
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
              title: const Text('Media Scraper'),
              centerTitle: true,
              actions: [
                if (state is ScraperLoaded)
                  IconButton(
                    tooltip: 'Refresh ALL Data (Takes ~30 seconds)',
                    onPressed: () => _runScraper(),
                    icon: const Icon(Icons.refresh),
                  ),
              ],
            ),
            body: Column(
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  child: state is ScraperLoading || state is ScraperInitial
                      ? const SizedBox(
                          width: double.infinity,
                          child: Center(child: LinearProgressIndicator()),
                        )
                      : !bloc.hasMore
                          ? Container(
                              width: double.infinity,
                              color: Theme.of(context).colorScheme.primary,
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Text(
                                  'No more articles to Load',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: state.scrapers.length,
                    itemBuilder: (context, index) => ScraperTile(
                      scraper: state.scrapers[index],
                      key: ValueKey(state.scrapers[index]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
