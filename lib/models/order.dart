import 'dart:convert';
import '../models/cart_item.dart';

class Order {
  final String id;
  final String customerName;
  final String phoneNumber;
  final double totalAmount;
  final DateTime date;
  final List<CartItem> items;

  Order({
    required this.id,
    required this.customerName,
    required this.phoneNumber,
    required this.totalAmount,
    required this.date,
    required this.items,
  });

  // Convert Order to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'phoneNumber': phoneNumber,
      'totalAmount': totalAmount,
      'date': date.toIso8601String(),
      'items': jsonEncode(items.map((item) => {
        'productTelugu': item.product.telugu,
        'productType': item.product.type,
        'weightOption': item.weightOption,
        'quantity': item.quantity,
        'isPerUnit': item.isPerUnit,
        // Calculate price based on weight or per unit
        'price': item.isPerUnit 
            ? (item.product.pricePerUnit ?? 0) * item.quantity
            : (item.product.weights[item.weightOption] ?? 0) * item.quantity,
        'weights': item.product.weights,
        'pricePerUnit': item.product.pricePerUnit,
      }).toList()),
    };
  }

  // Create Order from Map (from database)
  factory Order.fromMap(Map<String, dynamic> map) {
    // Parse the items JSON string back to a List
    final List<dynamic> itemsData = jsonDecode(map['items']);
    
    return Order(
      id: map['id'],
      customerName: map['customerName'],
      phoneNumber: map['phoneNumber'],
      totalAmount: map['totalAmount'],
      date: DateTime.parse(map['date']),
      items: itemsData.map((itemData) {
        // Recreate CartItem from the stored data
        // Note: This is a simplified version as we don't have the full Product object
        // We're storing just enough information to display and print the order
        return CartItem.fromOrderData(itemData);
      }).toList(),
    );
  }
}
