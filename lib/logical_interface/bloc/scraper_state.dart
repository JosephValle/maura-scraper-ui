part of 'scraper_bloc.dart';

@immutable
sealed class ScraperState {
  final List<ScraperModel> scrapers;

  const ScraperState(this.scrapers);
}

final class ScraperInitial extends ScraperState {
  const ScraperInitial(super.scrapers);
}

final class ScraperLoading extends ScraperState {
  const ScraperLoading(super.scrapers);
}

final class ScraperLoaded extends ScraperState {
  const ScraperLoaded(super.scrapers);
}

final class ScraperError extends ScraperState {
  final String error;

  const ScraperError(super.scrapers, {required this.error});
}
