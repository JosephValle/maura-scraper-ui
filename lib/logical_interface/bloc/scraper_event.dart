part of 'scraper_bloc.dart';

@immutable
sealed class ScraperEvent {}

class GetScrapers extends ScraperEvent {}

class ResetScraper extends ScraperEvent {}
