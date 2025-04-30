import 'package:flutter/material.dart';
import 'package:omni_search/search_function.dart';
import 'package:omni_search/search_result.dart';

/// Widget that provides a search field and shows results
class SearchFunctionWidget<T> extends StatefulWidget {
  /// Search function to use
  final SearchFunction<T> searchFunction;

  /// Widget builder for individual list items
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Widget to show when loading remote data
  final Widget? loadingWidget;

  /// Widget to show when no results found
  final Widget? emptyResultWidget;

  /// Widget to show when error occurs
  final Widget Function(BuildContext context, String error)? errorBuilder;

  /// Hint text for search field
  final String? hintText;

  /// Decoration for search field
  final InputDecoration? inputDecoration;

  /// Whether to show refresh button to force remote search
  final bool showRefreshButton;

  /// Whether to show local list on initial load before any search is performed
  final bool initialShowLocalList;

  const SearchFunctionWidget({
    super.key,
    required this.searchFunction,
    required this.itemBuilder,
    this.loadingWidget,
    this.emptyResultWidget,
    this.errorBuilder,
    this.hintText,
    this.inputDecoration,
    this.showRefreshButton = true,
    this.initialShowLocalList = false,
  });

  @override
  State<SearchFunctionWidget<T>> createState() =>
      _SearchFunctionWidgetState<T>();
}

class _SearchFunctionWidgetState<T> extends State<SearchFunctionWidget<T>> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Always trigger empty search to initialize if initialShowLocalList is true
    if (widget.initialShowLocalList) {
      // Use a small delay to ensure the stream is set up before data is pushed
      Future.microtask(() {
        widget.searchFunction.search('');
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search input field
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: widget.inputDecoration ??
                      InputDecoration(
                        hintText: widget.hintText ?? 'Search...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                  onChanged: (value) {
                    widget.searchFunction.search(value);
                  },
                ),
              ),
              if (widget.showRefreshButton) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Force remote search',
                  onPressed: () {
                    if (_searchController.text.isNotEmpty) {
                      widget.searchFunction
                          .forceRemoteSearch(_searchController.text);
                    }
                  },
                ),
              ],
            ],
          ),
        ),

        // Results list
        Expanded(
          child: StreamBuilder<SearchResult<T>>(
            stream: widget.searchFunction.resultsStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                // Show empty container if no data
                return const Center(child: Text('Ready to search'));
              }

              final result = snapshot.data!;

              // Show loading indicator ONLY for remote search
              if (result.isLoading && result.isRemote) {
                return widget.loadingWidget ??
                    const Center(child: CircularProgressIndicator());
              }

              // Show error
              if (result.error != null && result.error!.isNotEmpty) {
                return widget.errorBuilder != null
                    ? widget.errorBuilder!(context, result.error!)
                    : Center(child: Text('Error: ${result.error}'));
              }

              // Show empty state - only when user has searched something
              if (result.items.isEmpty && _searchController.text.isNotEmpty) {
                return widget.emptyResultWidget ??
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('No results found'),
                          if (widget.showRefreshButton && result.isLocal) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.search),
                              label: const Text('Search remotely'),
                              onPressed: () {
                                widget.searchFunction
                                    .forceRemoteSearch(_searchController.text);
                              },
                            ),
                          ],
                        ],
                      ),
                    );
              }

              // Show results
              return ListView.builder(
                itemCount: result.items.length,
                itemBuilder: (context, index) {
                  return widget.itemBuilder(context, result.items[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}