import 'dart:async';

import 'package:omni_search/search_result.dart';
import 'package:omni_search/utils.dart';

/// A highly efficient search functionality for Flutter applications
/// that combines instant local search with fallback remote search capabilities.
class SearchFunction<T> {
  /// Local data cache
  final List<T> _localData;

  /// Function to search remote data source
  final Future<List<T>> Function(String query) _remoteSearchFunction;

  /// Function to determine if item matches search query
  final bool Function(T item, String query) _matchFunction;

  /// Debounce duration for remote search
  final Duration _debounceDuration;

  /// Stream controller for search results
  final _searchResultsController =
  StreamController<SearchResult<T>>.broadcast();

  /// Timer for debouncing remote search
  Timer? _debounceTimer;

  /// Current search query
  String _currentQuery = '';

  /// All data combined (local + remote results)
  List<T> _allData = [];

  /// Flag to track if remote search is in progress
  bool _isRemoteSearchInProgress = false;

  /// Get stream of search results
  Stream<SearchResult<T>> get resultsStream => _searchResultsController.stream;

  /// Get current combined data list
  List<T> get allData => _allData;

  SearchFunction({
    List<T>? initialData,
    required Future<List<T>> Function(String query) remoteSearchFunction,
    required bool Function(T item, String query) matchFunction,
    Duration debounceDuration = const Duration(milliseconds: 300),
  })  : _localData = initialData ?? [],
        _remoteSearchFunction = remoteSearchFunction,
        _matchFunction = matchFunction,
        _debounceDuration = debounceDuration {
    _allData = List.from(_localData);
  }

  /// Search function that combines instant local and debounced remote search
  void search(String query) {
    _currentQuery = query;

    // Cancel previous timer if exists
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    // IMMEDIATELY perform local search - no loading state
    List<T> localResults = _searchLocalData(query);

    // Always emit local results immediately
    _searchResultsController.add(SearchResult<T>(
      items: localResults,
      isLoading: false,
      query: query,
      source: SearchSource.local,
    ));

    // If local search found results, don't trigger remote search
    if (localResults.isNotEmpty) {
      return;
    }

    // Only if local search returned no results, schedule remote search
    _debounceTimer =
        Timer(_debounceDuration, () => _performRemoteSearch(query));
  }

  /// Perform remote search operation
  Future<void> _performRemoteSearch(String query) async {
    // Skip if query is empty or too short
    if (query.isEmpty || query.length < 2) {
      return;
    }

    // Skip if query changed while waiting
    if (query != _currentQuery) return;

    // Set loading state for remote search
    _isRemoteSearchInProgress = true;
    _searchResultsController.add(SearchResult<T>(
      items: [], // Empty during remote loading
      isLoading: true,
      query: query,
      source: SearchSource.remote,
    ));

    try {
      List<T> remoteResults = await _remoteSearchFunction(query);

      // Skip if query changed during remote search
      if (query != _currentQuery) {
        _isRemoteSearchInProgress = false;
        return;
      }

      // Add new remote results to local cache if not already present
      for (var item in remoteResults) {
        if (!_localData.contains(item)) {
          _localData.add(item);
        }
      }

      // Update all data
      _updateAllData();

      // Emit remote results
      _searchResultsController.add(SearchResult<T>(
        items: remoteResults,
        isLoading: false,
        query: query,
        source: SearchSource.remote,
      ));
    } catch (e) {
      // Handle error in remote search
      _searchResultsController.add(SearchResult<T>(
        items: [],
        isLoading: false,
        error: e.toString(),
        query: query,
        source: SearchSource.remote,
      ));
    } finally {
      _isRemoteSearchInProgress = false;
    }
  }

  /// Search local data for matches - this is INSTANT
  List<T> _searchLocalData(String query) {
    if (query.isEmpty) {
      return List.from(_localData);
    }
    return _localData.where((item) => _matchFunction(item, query)).toList();
  }

  /// Update the combined data list
  void _updateAllData() {
    _allData = List.from(_localData);
  }

  /// Add items to local data cache
  void addItems(List<T> items) {
    for (var item in items) {
      if (!_localData.contains(item)) {
        _localData.add(item);
      }
    }
    _updateAllData();
  }

  /// Clear local data cache
  void clearLocalData() {
    _localData.clear();
    _updateAllData();
  }

  /// Force a remote search even if local results exist
  void forceRemoteSearch(String query) {
    _currentQuery = query;

    // Cancel previous timer if exists
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    // Perform remote search immediately
    _performRemoteSearch(query);
  }

  /// Close the search function and release resources
  void dispose() {
    _debounceTimer?.cancel();
    _searchResultsController.close();
  }
}