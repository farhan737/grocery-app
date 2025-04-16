import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/cart_provider.dart';
import '../models/cart_item.dart';
import '../services/cart_export_service.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import '../widgets/cart_item_widget.dart';
import '../models/product.dart';
import 'checkout_screen.dart';
import '../services/sheet_service.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItems = cartProvider.items;
    final totalAmount = cartProvider.totalAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sarukulu - Cart'),
        actions: [
          // Export cart button
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: cartItems.isEmpty
                ? null
                : () async {
                    try {
                      await cartProvider.exportCart();
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
            tooltip: 'Export Cart',
          ),
          // Import cart button
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () async {
              try {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Import Cart'),
                    content: const Text(
                      'This will replace your current cart with the imported items. Continue?'
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Import'),
                      ),
                    ],
                  ),
                );
                
                if (confirmed == true) {
                  await _importCartFile(context);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            tooltip: 'Import Cart',
          ),
          // Clear cart button
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: cartItems.isEmpty
                ? null
                : () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Clear Cart'),
                        content: const Text(
                            'Are you sure you want to remove all items?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                            },
                            child: const Text('No'),
                          ),
                          TextButton(
                            onPressed: () {
                              cartProvider.clearCart();
                              Navigator.of(ctx).pop();
                            },
                            child: const Text('Yes'),
                          ),
                        ],
                      ),
                    );
                  },
            tooltip: 'Clear Cart',
          ),
        ],
      ),
      body: cartItems.isEmpty
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
                        
                        final success = await cartProvider.importCart(products, context);
                        
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
                    itemCount: cartItems.length,
                    itemBuilder: (ctx, index) {
                      return CartItemWidget(
                        cartItem: cartItems[index],
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
                            '₹${totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: cartItems.isNotEmpty
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

  Future<void> _importCartFile(BuildContext context) async {
    try {
      // Get products
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
      
      // Pick file
      final filePath = await FlutterFileDialog.pickFile(
        params: const OpenFileDialogParams(
          fileExtensionsFilter: ['srkl'],
        ),
      );
      
      if (filePath == null) {
        return;
      }
      
      // Use the new importCartFromUri method
      final cartItems = await CartExportService.importCartFromUri(
        filePath, 
        products, 
        context
      );
      
      if (cartItems == null || cartItems.isEmpty) {
        return;
      }
      
      // Clear existing cart and add new items
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.clearCart();
      
      for (var item in cartItems) {
        cartProvider.addItem(
          item.product, 
          item.weightOption, 
          item.quantity, 
          item.isPerUnit ?? false
        );
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart imported successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error importing cart file: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing cart file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
