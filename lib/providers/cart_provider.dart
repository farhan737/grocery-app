import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../services/cart_persistence_service.dart';
import '../services/cart_export_service.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  bool _initialized = false;

  List<CartItem> get items => [..._items];

  int get itemCount => _items.length;

  double get totalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.price);
  }

  // Initialize cart from storage
  Future<void> initializeCart(List<Product> availableProducts) async {
    if (_initialized) return;
    
    print('CartProvider: Initializing cart from storage');
    final savedItems = await CartPersistenceService.loadCart(availableProducts);
    if (savedItems.isNotEmpty) {
      _items = savedItems;
      notifyListeners();
    }
    _initialized = true;
    print('CartProvider: Cart initialized with ${_items.length} items');
  }

  // Add item to cart
  void addItem(Product product, String weightOption, [int quantity = 1, bool isPerUnit = false]) {
    // Check if the item already exists in the cart
    int existingIndex = _items.indexWhere((item) => 
      item.product.telugu == product.telugu && 
      item.weightOption == weightOption &&
      item.isPerUnit == isPerUnit
    );

    if (existingIndex >= 0) {
      // Increment quantity if item already exists
      _items[existingIndex].quantity += quantity;
    } else {
      // Add new item
      final cartItem = CartItem(
        product: product,
        weightOption: weightOption,
        isPerUnit: isPerUnit,
      );
      cartItem.quantity = quantity; // Set the quantity
      _items.add(cartItem);
    }
    
    // Save cart to storage
    CartPersistenceService.saveCart(_items);
    
    notifyListeners();
  }

  // Remove item from cart
  void removeItem(int index) {
    _items.removeAt(index);
    
    // Save cart to storage
    CartPersistenceService.saveCart(_items);
    
    notifyListeners();
  }

  // Update item quantity
  void updateQuantity(int index, int quantity) {
    if (quantity > 0) {
      _items[index].quantity = quantity;
      
      // Save cart to storage
      CartPersistenceService.saveCart(_items);
      
      notifyListeners();
    } else {
      removeItem(index);
    }
  }

  // Clear cart
  void clearCart() {
    _items.clear();
    
    // Clear saved cart
    CartPersistenceService.clearCart();
    
    notifyListeners();
  }
  
  // Export cart to a file and share it
  Future<void> exportCart() async {
    if (_items.isEmpty) return;
    
    final orderNumber = CartExportService.generateOrderNumber();
    await CartExportService.exportCart(_items, orderNumber);
  }
  
  // Import cart from a file
  Future<bool> importCart(List<Product> availableProducts, BuildContext context) async {
    final importedItems = await CartExportService.importCart(availableProducts, context);
    
    if (importedItems == null || importedItems.isEmpty) {
      return false;
    }
    
    // Replace current cart with imported items
    _items = importedItems;
    
    // Save cart to storage
    CartPersistenceService.saveCart(_items);
    
    notifyListeners();
    return true;
  }

  // Clear cart and replace with imported items
  Future<bool> replaceCartWithImported(List<Product> availableProducts, String filePath, {BuildContext? context}) async {
    try {
      print('CartProvider: Replacing cart with imported items from $filePath');
      
      // Read file content
      final file = File(filePath);
      if (!await file.exists()) {
        print('CartProvider: File does not exist: $filePath');
        return false;
      }
      
      final jsonString = await file.readAsString();
      
      // Process the cart items
      final importedItems = await CartExportService.processImportedJson(jsonString, availableProducts);
      
      if (importedItems == null || importedItems.isEmpty) {
        print('CartProvider: No valid items found in import file');
        return false;
      }
      
      // Clear existing cart and add new items
      clearCart();
      
      // Add all imported items
      for (var item in importedItems) {
        addItem(item.product, item.weightOption, item.quantity ?? 1, item.isPerUnit);
      }
      
      // Save cart to storage
      CartPersistenceService.saveCart(_items);
      
      print('CartProvider: Cart replaced with ${importedItems.length} imported items');
      return true;
    } catch (e) {
      print('CartProvider: Error replacing cart: $e');
      
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing cart: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      return false;
    }
  }
}
