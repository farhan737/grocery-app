import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';

class ProductCard extends StatefulWidget {
  final Product product;

  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _expanded = false;
  String? _selectedWeight;
  bool _isPerUnit = false;
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final availableWeights = widget.product.getAvailableWeights();
    final hasPerUnitPrice = widget.product.hasPerUnitPrice();

    // Reset selection if nothing is available
    if (availableWeights.isEmpty && !hasPerUnitPrice) {
      _expanded = false;
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          print('ProductCard: Tapped on ${widget.product.telugu}');
          print('ProductCard: Available weights: ${availableWeights.keys.toList()}');
          print('ProductCard: Has per unit price: $hasPerUnitPrice');
          
          // Only allow expansion if there are options available
          if (availableWeights.isNotEmpty || hasPerUnitPrice) {
            setState(() {
              _expanded = !_expanded;
              print('ProductCard: Expanded state changed to $_expanded');
              
              // Set default selection when expanding
              if (_expanded) {
                if (hasPerUnitPrice) {
                  _isPerUnit = true;
                  _selectedWeight = null;
                  print('ProductCard: Default selection set to per unit price');
                } else {
                  _isPerUnit = false;
                  _selectedWeight = availableWeights.keys.first;
                  print('ProductCard: Default selection set to weight: $_selectedWeight');
                }
              }
            });
          } else {
            print('ProductCard: No options available for expansion');
          }
        },
        child: Column(
          children: [
            ListTile(
              title: Text(
                widget.product.telugu,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              subtitle: Text(
                widget.product.type.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(color: Theme.of(context).colorScheme.secondary.withOpacity(0.8)),
              ),
              trailing: _expanded
                  ? const Icon(Icons.expand_less)
                  : const Icon(Icons.expand_more),
            ),
            if (_expanded)
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Per unit option
                    if (hasPerUnitPrice)
                      RadioListTile<bool>(
                        title: Text('Per Unit - ₹${widget.product.pricePerUnit}'),
                        value: true,
                        groupValue: _isPerUnit,
                        onChanged: (value) {
                          setState(() {
                            _isPerUnit = true;
                            _selectedWeight = null;
                          });
                        },
                      ),
                    
                    // Weight options
                    if (availableWeights.isNotEmpty)
                      ..._buildWeightOptions(availableWeights),
                    
                    const SizedBox(height: 16),
                    
                    // Quantity selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _quantity > 1
                              ? () {
                                  setState(() {
                                    _quantity--;
                                  });
                                }
                              : null,
                        ),
                        Text(
                          '$_quantity',
                          style: const TextStyle(fontSize: 18),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              _quantity++;
                            });
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Add to cart button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _canAddToCart()
                            ? () => _addToCart(context)
                            : null,
                        child: const Text('Add to Cart'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildWeightOptions(Map<String, double> availableWeights) {
    return availableWeights.entries.map((entry) {
      return RadioListTile<String>(
        title: Text('${entry.key} - ₹${entry.value}'),
        value: entry.key,
        groupValue: _isPerUnit ? null : _selectedWeight,
        onChanged: (value) {
          setState(() {
            _isPerUnit = false;
            _selectedWeight = value;
          });
        },
      );
    }).toList();
  }

  bool _canAddToCart() {
    return _isPerUnit || _selectedWeight != null;
  }

  void _addToCart(BuildContext context) {
    print('ProductCard: Adding to cart - ${widget.product.telugu}');
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    if (_isPerUnit) {
      print('ProductCard: Adding per unit item with quantity $_quantity');
      // Add the item with quantity
      cartProvider.addItem(
        widget.product,
        'Per Unit',
        _quantity,
        true, // isPerUnit
      );
    } else if (_selectedWeight != null) {
      print('ProductCard: Adding weight item: $_selectedWeight with quantity $_quantity');
      // Add the item with quantity
      cartProvider.addItem(
        widget.product,
        _selectedWeight!,
        _quantity,
        false, // isPerUnit
      );
    } else {
      print('ProductCard: Error - No valid selection for adding to cart');
      return;
    }
    
    // Reset quantity
    setState(() {
      _quantity = 1;
      _expanded = false;
      print('ProductCard: Reset quantity and collapsed card');
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added to cart!'),
        duration: Duration(seconds: 1),
      ),
    );
    print('ProductCard: Item added to cart successfully');
  }
}
