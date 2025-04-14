import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../services/database_helper.dart';
import '../services/pdf_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _refreshOrders();
  }

  void _refreshOrders() {
    setState(() {
      _ordersFuture = _dbHelper.getOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sarukulu - Order History'),
      ),
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No order history found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          final orders = snapshot.data!;
          return ListView.builder(
            itemCount: orders.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (ctx, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order #${order.id.substring(4, 12)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            DateFormat('dd MMM yyyy, hh:mm a').format(order.date),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 16),
                          const SizedBox(width: 8),
                          Text(order.customerName),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 16),
                          const SizedBox(width: 8),
                          Text(order.phoneNumber),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total: ₹${order.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              // Show loading indicator
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Preparing PDF for printing...'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                              
                              // Generate and print the PDF
                              await PdfService.generateAndPrintOrder(order);
                            },
                            icon: const Icon(Icons.print),
                            label: const Text('Print'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.secondary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      // Show a preview of items (first 3)
                      if (order.items.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Items:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...order.items.take(3).map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.displayText,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text('₹${item.price.toStringAsFixed(2)}'),
                            ],
                          ),
                        )),
                        if (order.items.length > 3)
                          Text(
                            '+ ${order.items.length - 3} more items',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
