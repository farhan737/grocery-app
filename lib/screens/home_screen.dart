import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../services/sheet_service.dart';
import '../widgets/product_card.dart';
import 'cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SheetService _sheetService = SheetService();
  late Future<List<Product>> _productsFuture;
  String? _selectedCategory;
  bool _usingMockData = false;

  @override
  void initState() {
    super.initState();
    print('HomeScreen: Initializing and fetching products');
    _productsFuture = _sheetService.fetchProducts().catchError((error) {
      print('HomeScreen: Error fetching products: $error');
      return <Product>[];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grocery App'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => const CartScreen(),
                    ),
                  );
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Consumer<CartProvider>(
                  builder: (ctx, cart, _) => cart.itemCount > 0
                      ? Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.purpleAccent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${cart.itemCount}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : Container(),
                ),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print('HomeScreen: Error in FutureBuilder: ${snapshot.error}');
            if (snapshot.error is Exception) {
              print('HomeScreen: Exception details: ${(snapshot.error as Exception).toString()}');
            }
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      print('HomeScreen: Retry button pressed');
                      setState(() {
                        _productsFuture = _sheetService.fetchProducts().catchError((error) {
                          print('HomeScreen: Error on retry: $error');
                          return <Product>[];
                        });
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No products found'),
            );
          }

          final products = snapshot.data!;
          print('HomeScreen: Loaded ${products.length} products');
          
          // Check if we're using mock data (if products length is exactly the mock data length)
          _usingMockData = products.length == 15; // Our mock data has 15 products
          
          final groupedProducts = _sheetService.groupProductsByType(products);
          final categories = groupedProducts.keys.toList();
          print('HomeScreen: Found ${categories.length} categories: $categories');
          
          // Set default category if none is selected
          if (_selectedCategory == null && categories.isNotEmpty) {
            _selectedCategory = categories.first;
            print('HomeScreen: Set default category to $_selectedCategory');
          }

          return Column(
            children: [
              // Mock data warning banner
              if (_usingMockData)
                Container(
                  width: double.infinity,
                  color: Colors.deepPurple.withOpacity(0.2),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber.shade800),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Using sample data for demonstration. The Google Sheets API is currently unavailable.',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Category selector
              Container(
                height: 50,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (ctx, index) {
                    final category = categories[index];
                    final isSelected = category == _selectedCategory;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.secondary
                              : const Color(0xFF2D2D2D),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          category.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Products list
              Expanded(
                child: _selectedCategory != null
                    ? ListView.builder(
                        itemCount: groupedProducts[_selectedCategory]!.length,
                        itemBuilder: (ctx, index) {
                          final product = groupedProducts[_selectedCategory]![index];
                          return ProductCard(product: product);
                        },
                      )
                    : const Center(
                        child: Text('No category selected'),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
