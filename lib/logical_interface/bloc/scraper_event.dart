part of 'scraper_bloc.dart';

@immutable
sealed class ScraperEvent {}

class GetScrapers extends ScraperEvent {}

class ResetScraper extends ScraperEvent {}

class UpdateTags extends ScraperEvent {
  final List<String> tags;

  UpdateTags(this.tags);
}

class UpdateTagList extends ScraperEvent {
  final List<String> tags;

  UpdateTagList(this.tags);
}
