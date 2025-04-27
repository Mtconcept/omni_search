import 'package:flutter/material.dart';
import 'package:omni_search/omni.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SearchFunction Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SearchDemo(),
    );
  }
}

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Product &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class SearchDemo extends StatefulWidget {
  const SearchDemo({super.key});

  @override
  State<SearchDemo> createState() => _SearchDemoState();
}

class _SearchDemoState extends State<SearchDemo> {
  late SearchFunction<Product> _searchFunction;
  final bool _showLocalLabel = true;
  final TextEditingController _debugController = TextEditingController();

  // Sample local data
  final List<Product> _localProducts = [
    Product(
      id: '1',
      name: 'iPhone 15 Pro',
      description: 'Latest Apple smartphone with advanced camera system',
      price: 999.99,
      category: 'Electronics',
    ),
    Product(
      id: '2',
      name: 'MacBook Pro M3',
      description: 'Powerful laptop for developers and creators',
      price: 1999.99,
      category: 'Computers',
    ),
    Product(
      id: '3',
      name: 'AirPods Pro',
      description: 'Noise-cancelling wireless earbuds with spatial audio',
      price: 249.99,
      category: 'Audio',
    ),
    Product(
      id: '4',
      name: 'Samsung Galaxy S23',
      description: 'Android smartphone with high-performance camera',
      price: 899.99,
      category: 'Electronics',
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Initialize SearchFunction with local data and remote search function
    _searchFunction = SearchFunction<Product>(
      initialData: _localProducts,
      remoteSearchFunction: _mockRemoteSearch,
      matchFunction: _matchProduct,
      debounceDuration: const Duration(milliseconds: 500),
    );
  }

  // Mock remote search function that simulates API call
  Future<List<Product>> _mockRemoteSearch(String query) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Log for debugging
    debugPrint('Performing remote search for: $query');

    // Mock remote data - more extensive catalog
    final remoteProducts = [
      Product(
        id: '5',
        name: 'iPad Air',
        description: 'Thin and light tablet with all-day battery life',
        price: 599.99,
        category: 'Tablets',
      ),
      Product(
        id: '6',
        name: 'Pixel 7',
        description: 'Google phone with incredible AI photography features',
        price: 699.99,
        category: 'Electronics',
      ),
      Product(
        id: '7',
        name: 'Sony WH-1000XM5',
        description: 'Premium noise-cancelling headphones',
        price: 379.99,
        category: 'Audio',
      ),
      Product(
        id: '8',
        name: 'Apple Watch Series 8',
        description: 'Health and fitness tracking smartwatch',
        price: 399.99,
        category: 'Wearables',
      ),
      Product(
        id: '9',
        name: 'Nintendo Switch OLED',
        description: 'Gaming console with vibrant OLED display',
        price: 349.99,
        category: 'Gaming',
      ),
      Product(
        id: '10',
        name: 'Dell XPS 15',
        description: 'Powerful Windows laptop with InfinityEdge display',
        price: 1799.99,
        category: 'Computers',
      ),
      Product(
        id: '11',
        name: 'LG C2 OLED TV',
        description: '65-inch 4K OLED TV with perfect blacks',
        price: 1999.99,
        category: 'TVs',
      ),
      Product(
        id: '12',
        name: 'Sonos Beam',
        description: 'Smart soundbar with voice assistant support',
        price: 449.99,
        category: 'Audio',
      ),
    ];

    // Advanced filtering logic for remote search
    if (query.isEmpty) return [];

    final queryLower = query.toLowerCase();

    // Filter by any field matching the query
    return remoteProducts
        .where((product) =>
    product.name.toLowerCase().contains(queryLower) ||
        product.description.toLowerCase().contains(queryLower) ||
        product.category.toLowerCase().contains(queryLower))
        .toList();
  }

  // Function to determine if a product matches the search query
  bool _matchProduct(Product product, String query) {
    if (query.isEmpty) return true;

    final queryLower = query.toLowerCase();

    // Match against multiple fields
    return product.name.toLowerCase().contains(queryLower) ||
        product.description.toLowerCase().contains(queryLower) ||
        product.category.toLowerCase().contains(queryLower);
  }

  @override
  void dispose() {
    _searchFunction.dispose();
    _debugController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instant Search Demo'),

      ),
      body: Column(
        children: [
          // Debug section to add test products
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _debugController,
                    decoration: const InputDecoration(
                      labelText: 'Test: Add product name',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_debugController.text.isNotEmpty) {
                      final newProduct = Product(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: _debugController.text,
                        description: 'Test product added locally',
                        price: 99.99,
                        category: 'Test',
                      );
                      _searchFunction.addItems([newProduct]);
                      _debugController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added: ${newProduct.name}')),
                      );
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          ),

          Expanded(
            child: SearchFunctionWidget<Product>(
              searchFunction: _searchFunction,
              hintText: 'Search products instantly...',
              showRefreshButton: true,
              itemBuilder: (context, product) {
                return StreamBuilder<SearchResult<Product>>(
                    stream: _searchFunction.resultsStream,
                    builder: (context, snapshot) {
                      final isRemoteResult = snapshot.hasData &&
                          snapshot.data!.isRemote &&
                          snapshot.data!.items.contains(product);

                      return ListTile(
                        title: Text(product.name),
                        subtitle: Text(product.description),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('\$${product.price.toStringAsFixed(2)}'),
                            if (_showLocalLabel) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isRemoteResult ? Colors.blue[100] : Colors.green[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isRemoteResult ? 'Remote' : 'Local',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isRemoteResult ? Colors.blue[800] : Colors.green[800],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        onTap: () {
                          // Show product details
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(product.name),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Description: ${product.description}'),
                                  const SizedBox(height: 8),
                                  Text('Category: ${product.category}'),
                                  const SizedBox(height: 8),
                                  Text('Price: \$${product.price.toStringAsFixed(2)}'),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }
                );
              },
              loadingWidget: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text('Searching remote sources...'),
                    const SizedBox(height: 24),
                    TextButton.icon(
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel Remote Search'),
                      onPressed: () {
                        // Reset search to local results
                        _searchFunction.search(_searchFunction.allData.isNotEmpty ? '' : ' ');
                      },
                    ),
                  ],
                ),
              ),
              emptyResultWidget: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('No products found'),
                    const SizedBox(height: 8),
                    const Text(
                      'Try different keywords or check spelling',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}