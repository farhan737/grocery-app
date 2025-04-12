import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/cart_item.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => [..._items];

  int get itemCount => _items.length;

  double get totalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.price);
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
    notifyListeners();
  }

  // Remove item from cart
  void removeItem(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  // Update item quantity
  void updateQuantity(int index, int quantity) {
    if (quantity > 0) {
      _items[index].quantity = quantity;
      notifyListeners();
    } else {
      removeItem(index);
    }
  }

  // Clear cart
  void clear() {
    _items.clear();
    notifyListeners();
  }
}
