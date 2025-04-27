import 'package:omni_search/utils.dart';

/// Class to hold search results
class SearchResult<T> {
  /// List of search result items
  final List<T> items;

  /// Whether search is in progress
  final bool isLoading;

  /// Search query that produced these results
  final String query;

  /// Error message if search failed
  final String? error;

  /// Source of the search results
  final SearchSource? source;

  SearchResult({
    required this.items,
    required this.isLoading,
    required this.query,
    this.error,
    this.source,
  });

  /// Check if this result is from local search
  bool get isLocal => source == SearchSource.local;

  /// Check if this result is from remote search
  bool get isRemote => source == SearchSource.remote;
}
