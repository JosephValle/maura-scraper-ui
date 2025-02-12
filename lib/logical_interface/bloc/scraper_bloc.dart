import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../models/scraper_model.dart';
import '../../network_interface/api_client.dart';

part 'scraper_event.dart';

part 'scraper_state.dart';

class ScraperBloc extends Bloc<ScraperEvent, ScraperState> {
  final ApiClient _apiClient = ApiClient();
  final List<ScraperModel> scrapers = [];
  final int pageSize = 10;
  int page = 1;
  bool hasMore = true;

  ScraperBloc() : super(const ScraperInitial([])) {
    on<GetScrapers>((event, emit) async {
      if (state is ScraperLoading || !hasMore) return;
      emit(ScraperLoading(scrapers));
      try {
        final response =
            await _apiClient.getScrapers(page: page, pageSize: pageSize);
        scrapers.addAll(response.scrapers);
        hasMore = response.hasMore;
        page++;
        emit(ScraperLoaded(scrapers));
      } catch (e) {
        emit(ScraperError(scrapers, error: e.toString()));
      }
    });

    on<ResetScraper>((event, emit) async {
      try {
        page = 1;
        scrapers.clear();
        hasMore = true;
        emit(ScraperInitial(scrapers));
        await _apiClient.runScraper();
        add(GetScrapers());
      } catch (e) {
        emit(ScraperError(scrapers, error: e.toString()));
      }
    });
  }
}
