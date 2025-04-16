import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/cart_item_widget.dart';
import '../models/product.dart';
import 'checkout_screen.dart';
import '../services/sheet_service.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sarukulu - Cart'),
        actions: [
          if (cart.itemCount > 0)
            // Export cart button
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Export Cart',
              onPressed: () async {
                try {
                  await cart.exportCart();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cart exported successfully'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to export cart: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          if (cart.itemCount > 0)
            // Clear cart button
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Clear Cart',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear Cart'),
                    content: const Text('Are you sure you want to clear the cart?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          cart.clear();
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
              },
            ),
          if (cart.itemCount == 0)
            // Import cart button (only shown when cart is empty)
            IconButton(
              icon: const Icon(Icons.file_upload),
              tooltip: 'Import Cart',
              onPressed: () async {
                try {
                  // Get products directly from the home screen
                  final products = await _getProductsList(context);
                  if (products.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Unable to load products. Please try again later.'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 3),
                      ),
                    );
                    return;
                  }
                  
                  // Show loading indicator
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Searching for cart files...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  
                  final success = await cart.importCart(products, context);
                  
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cart imported successfully'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  print('Error importing cart: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error importing cart: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),
        ],
      ),
      body: cart.itemCount == 0
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Your cart is empty!',
                    style: TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        // Get products directly from the home screen
                        final products = await _getProductsList(context);
                        if (products.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Unable to load products. Please try again later.'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 3),
                            ),
                          );
                          return;
                        }
                        
                        // Show loading indicator
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Searching for cart files...'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                        
                        final success = await cart.importCart(products, context);
                        
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cart imported successfully'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        print('Error importing cart: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error importing cart: ${e.toString()}'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.file_upload),
                    label: const Text('Import Cart'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.itemCount,
                    itemBuilder: (ctx, index) {
                      return CartItemWidget(
                        cartItem: cart.items[index],
                        index: index,
                      );
                    },
                  ),
                ),
                Card(
                  margin: const EdgeInsets.all(15),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(fontSize: 20),
                        ),
                        const Spacer(),
                        Chip(
                          label: Text(
                            '₹${cart.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: cart.itemCount > 0
                              ? () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (ctx) => const CheckoutScreen(),
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('CHECKOUT'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // Helper method to get products list
  Future<List<Product>> _getProductsList(BuildContext context) async {
    try {
      // Try to get products from provider
      try {
        final productsFuture = Provider.of<Future<List<Product>>>(context, listen: false);
        final products = await productsFuture;
        return List<Product>.from(products);
      } catch (e) {
        print('Error getting products from provider: $e');
      }
      
      // Fallback: fetch products directly
      final sheetService = SheetService();
      final products = await sheetService.fetchProducts();
      return products;
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }
}
