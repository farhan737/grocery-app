import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';

class CartItemWidget extends StatelessWidget {
  final CartItem cartItem;
  final int index;

  const CartItemWidget({
    Key? key,
    required this.cartItem,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {
              Provider.of<CartProvider>(context, listen: false).removeItem(index);
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: FittedBox(
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Text(
                    '₹${cartItem.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            title: Text(
              cartItem.product.telugu,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              cartItem.isPerUnit
                  ? 'Per Unit - ₹${cartItem.product.pricePerUnit}'
                  : '${cartItem.weightOption} - ₹${cartItem.product.weights[cartItem.weightOption]}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: cartItem.quantity > 1
                      ? () {
                          Provider.of<CartProvider>(context, listen: false)
                              .updateQuantity(index, cartItem.quantity - 1);
                        }
                      : null,
                ),
                Text(
                  '${cartItem.quantity}',
                  style: const TextStyle(fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    Provider.of<CartProvider>(context, listen: false)
                        .updateQuantity(index, cartItem.quantity + 1);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
