import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartPersistenceService {
  static const String cartKey = 'cart_items';

  // Save cart items to shared preferences
  static Future<void> saveCart(List<CartItem> items) async {
    try {
      print('CartPersistenceService: Saving ${items.length} items to storage');
      final prefs = await SharedPreferences.getInstance();
      
      // Convert cart items to JSON
      final itemsJson = items.map((item) => {
        'telugu': item.product.telugu,
        'weightOption': item.weightOption,
        'isPerUnit': item.isPerUnit,
        'quantity': item.quantity,
      }).toList();
      
      // Save as JSON string
      await prefs.setString(cartKey, jsonEncode(itemsJson));
      print('CartPersistenceService: Cart saved successfully');
    } catch (e) {
      print('CartPersistenceService: Error saving cart: $e');
    }
  }

  // Load cart items from shared preferences
  static Future<List<CartItem>> loadCart(List<Product> availableProducts) async {
    try {
      print('CartPersistenceService: Loading cart from storage');
      final prefs = await SharedPreferences.getInstance();
      
      // Get JSON string
      final cartJson = prefs.getString(cartKey);
      if (cartJson == null) {
        print('CartPersistenceService: No saved cart found');
        return [];
      }
      
      // Parse JSON
      final List<dynamic> itemsJson = jsonDecode(cartJson);
      
      // Convert to cart items
      final items = <CartItem>[];
      for (var itemJson in itemsJson) {
        // Find the product in available products
        final product = availableProducts.firstWhere(
          (p) => p.telugu == itemJson['telugu'],
          orElse: () => Product(telugu: itemJson['telugu'], weights: {}, type: 'unknown'),
        );
        
        // Create cart item
        final cartItem = CartItem(
          product: product,
          weightOption: itemJson['weightOption'],
          isPerUnit: itemJson['isPerUnit'],
        );
        
        // Set quantity
        cartItem.quantity = itemJson['quantity'];
        
        items.add(cartItem);
      }
      
      print('CartPersistenceService: Loaded ${items.length} items from storage');
      return items;
    } catch (e) {
      print('CartPersistenceService: Error loading cart: $e');
      return [];
    }
  }

  // Clear saved cart
  static Future<void> clearCart() async {
    try {
      print('CartPersistenceService: Clearing saved cart');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(cartKey);
      print('CartPersistenceService: Cart cleared successfully');
    } catch (e) {
      print('CartPersistenceService: Error clearing cart: $e');
    }
  }
}
