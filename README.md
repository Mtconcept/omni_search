# Omni Search

[![Pub Version](https://img.shields.io/pub/v/omni_search.svg)](https://pub.dev/packages/omni_search)
[![Pub Points](https://img.shields.io/pub/points/omni_search)](https://pub.dev/packages/omni_search/score)
[![Likes](https://img.shields.io/pub/likes/omni_search)](https://pub.dev/packages/omni_search/score)
[![License](https://img.shields.io/github/license/mtconcept/omni_search)](https://github.com/mtconcept/omni_search/blob/main/LICENSE)

A powerful Flutter package that implements highly efficient search functionality with hybrid local-remote capability. SearchFunction provides instant local results and seamlessly fetches remote data when needed.

## Features

- ⚡ **Instant Local Search**: Lightning-fast search through local data collections
- 🔄 **Automatic Remote Fallback**: Searches remote sources only when local results aren't found
- 🚀 **Optimized Performance**: Debounced API calls to minimize network usage
- 💾 **Smart Caching**: Automatically caches remote results for future searches
- 🧩 **Generic Implementation**: Works with any data type or model
- 📱 **Ready-to-Use UI Components**: Beautiful search widgets with customizable appearance
- 🔍 **Advanced Filtering**: Flexible match functions for sophisticated searching

## Installation

Add `omni_search: ` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  omni_search: ^0.0.2
```

Then run:
```bash
flutter pub get
```

## Basic Usage

Here's a simple example of how to integrate Omni Search into your Flutter app.:

```dart
import 'package:flutter/material.dart';
import 'package:search_function/search_function.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SearchPage(),
    );
  }
}

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late SearchFunction<String> searchFunction;

  @override
  void initState() {
    super.initState();
    
    // Initialize with some local data
    searchFunction = SearchFunction<String>(
      initialData: ['Apple', 'Banana', 'Orange', 'Pineapple'],
      remoteSearchFunction: _fetchRemoteData,
      matchFunction: _matchItem,
    );
  }

  // Remote search function
  Future<List<String>> _fetchRemoteData(String query) async {
    // Simulate API call
    await Future.delayed(Duration(seconds: 1));
    
    // Real implementation would call your API here
    return ['Mango', 'Strawberry', 'Watermelon']
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Match function for local search
  bool _matchItem(String item, String query) {
    return item.toLowerCase().contains(query.toLowerCase());
  }

  @override
  void dispose() {
    searchFunction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SearchFunction Demo')),
      body: SearchFunctionWidget<String>(
        searchFunction: searchFunction,
        hintText: 'Search fruits...',
        itemBuilder: (context, item) {
          return ListTile(title: Text(item));
        },
      ),
    );
  }
}
```

## Detailed Usage Guide

### 1. Initialize the SearchFunction

```dart
SearchFunction<Product> searchFunction = SearchFunction<Product>(
  initialData: myLocalProducts,           // Your local data cache
  remoteSearchFunction: fetchFromApi,     // Function that fetches from API/DB
  matchFunction: matchProductToQuery,     // How to match items to search query
  debounceDuration: Duration(milliseconds: 300),  // Wait time before remote search
);
```

### 2. Define Your Match Function

The match function determines how items are matched against the search query:

```dart
bool matchProductToQuery(Product product, String query) {
  if (query.isEmpty) return true;
  
  final queryLower = query.toLowerCase();
  return product.name.toLowerCase().contains(queryLower) ||
         product.description.toLowerCase().contains(queryLower) ||
         product.category.toLowerCase().contains(queryLower);
}
```

### 3. Implement Remote Search Function

This function is called only when local search returns no results:

```dart
Future<List<Product>> fetchFromApi(String query) async {
  // Example implementation using http package
  final response = await http.get(
    Uri.parse('https://api.example.com/products?search=$query')
  );
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body) as List;
    return data.map((json) => Product.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load products');
  }
}
```

### 4. Use the SearchFunctionWidget

```dart
SearchFunctionWidget<Product>(
  searchFunction: searchFunction,
  hintText: 'Search products...',
  showRefreshButton: true,  // Show button to force remote search
  itemBuilder: (context, product) {
    return ListTile(
      title: Text(product.name),
      subtitle: Text(product.description),
      trailing: Text('\$${product.price.toStringAsFixed(2)}'),
    );
  },
  loadingWidget: Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Searching remote sources...'),
      ],
    ),
  ),
  emptyResultWidget: Center(
    child: Text('No products found'),
  ),
)
```

### 5. Direct Access to Search Results Stream

If you prefer to build your own UI, you can listen to the search results stream directly:

```dart
StreamBuilder<SearchResult<Product>>(
  stream: searchFunction.resultsStream,
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return SizedBox.shrink();
    }
    
    final result = snapshot.data!;
    
    if (result.isLoading && result.isRemote) {
      return CircularProgressIndicator();
    }
    
    if (result.items.isEmpty) {
      return Text('No results found');
    }
    
    return ListView.builder(
      itemCount: result.items.length,
      itemBuilder: (context, index) {
        final product = result.items[index];
        return ListTile(title: Text(product.name));
      },
    );
  },
)
```

## Advanced Usage

### Custom Filtering

You can implement advanced filtering by customizing the match function:

```dart
bool advancedMatch(Product product, String query) {
  // Parse the query for special commands
  if (query.startsWith('category:')) {
    final category = query.substring(9).trim().toLowerCase();
    return product.category.toLowerCase() == category;
  }
  
  if (query.startsWith('price<')) {
    final maxPrice = double.tryParse(query.substring(6).trim()) ?? double.infinity;
    return product.price < maxPrice;
  }
  
  // Default search
  final queryLower = query.toLowerCase();
  return product.name.toLowerCase().contains(queryLower) ||
         product.description.toLowerCase().contains(queryLower);
}
```

### Manual Cache Management

You can manually manage the local data cache:

```dart
// Add new items to the cache
searchFunction.addItems([newProduct1, newProduct2]);

// Clear the entire cache
searchFunction.clearLocalData();

// Force a remote search even if local results exist
searchFunction.forceRemoteSearch(query);
```

### Checking Result Source

You can identify whether results came from local or remote search:

```dart
StreamBuilder<SearchResult<Product>>(
  stream: searchFunction.resultsStream,
  builder: (context, snapshot) {
    if (!snapshot.hasData) return SizedBox.shrink();
    
    final result = snapshot.data!;
    
    // Check if result is from local search
    if (result.isLocal) {
      return Text('Results from local cache');
    }
    
    // Check if result is from remote search
    if (result.isRemote) {
      return Text('Results from API');
    }
    
    return SizedBox.shrink();
  }
)
```

## Complete Example

For a complete implementation example, please check the [example](https://github.com/yourusername/search_function/tree/main/example) folder in the repository.

## Performance Tips

1. **Keep your match function efficient**: Complex match functions can slow down local search.
2. **Use appropriate debounce duration**: Shorter for better responsiveness, longer to reduce API calls.
3. **Properly implement equals and hashCode**: This ensures correct caching behavior.
4. **Consider result pagination**: For very large data sets, implement pagination in your remote search function.

## Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `initialData` | Starting local data cache | `[]` |
| `remoteSearchFunction` | Function to fetch remote data | Required |
| `matchFunction` | Function to determine item matches | Required |
| `debounceDuration` | Delay before triggering remote search | `300ms` |

## Troubleshooting

**Q: Search is too slow on large datasets**  
A: Make sure your `matchFunction` is optimized. Consider implementing indexing for large collections.

**Q: Remote search is called too frequently**  
A: Increase the `debounceDuration` parameter when initializing SearchFunction.

**Q: Items are duplicated in results**  
A: Ensure you have properly implemented `==` operator and `hashCode` for your data class.

## Contributing

Contributions are welcome! If you find a bug or want to add a feature, please file an issue or submit a PR.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.