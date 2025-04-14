import 'product.dart';

class CartItem {
  final Product product;
  final String weightOption; // Selected weight option (e.g., '1K', '250G')
  int quantity;
  final bool isPerUnit; // Whether this is a per-unit purchase

  CartItem({
    required this.product,
    required this.weightOption,
    this.quantity = 1,
    this.isPerUnit = false,
  });

  // Create CartItem from order data (for order history)
  factory CartItem.fromOrderData(Map<String, dynamic> data) {
    // Create a simplified Product object with just the data we need
    final product = Product(
      telugu: data['productTelugu'],
      type: data['productType'],
      weights: Map<String, double?>.from(data['weights']),
      pricePerUnit: data['pricePerUnit'],
    );
    
    return CartItem(
      product: product,
      weightOption: data['weightOption'],
      quantity: data['quantity'],
      isPerUnit: data['isPerUnit'],
    );
  }

  // Calculate the price for this cart item
  double get price {
    if (isPerUnit) {
      return (product.pricePerUnit ?? 0) * quantity;
    } else {
      return (product.weights[weightOption] ?? 0) * quantity;
    }
  }

  // Get the display text for this cart item
  String get displayText {
    if (isPerUnit) {
      return '${product.telugu} (Per Unit) x $quantity';
    } else {
      return '${product.telugu} ($weightOption) x $quantity';
    }
  }
}
