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
  void addItem(Product product, String weightOption, {bool isPerUnit = false}) {
    // Check if the item already exists in the cart
    int existingIndex = _items.indexWhere((item) => 
      item.product.telugu == product.telugu && 
      item.weightOption == weightOption &&
      item.isPerUnit == isPerUnit
    );

    if (existingIndex >= 0) {
      // Increment quantity if item already exists
      _items[existingIndex].quantity += 1;
    } else {
      // Add new item
      _items.add(
        CartItem(
          product: product,
          weightOption: weightOption,
          isPerUnit: isPerUnit,
        ),
      );
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
  void clear() {
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
}
