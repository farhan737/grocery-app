import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/order.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    print('DatabaseHelper: Database not initialized, initializing now');
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      print('DatabaseHelper: Getting database path');
      final path = join(await getDatabasesPath(), 'grocery_orders.db');
      print('DatabaseHelper: Database path: $path');
      
      print('DatabaseHelper: Opening database');
      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDb,
      );
    } catch (e) {
      print('DatabaseHelper: Error initializing database: $e');
      print('DatabaseHelper: Error stack trace:');
      print(StackTrace.current);
      rethrow;
    }
  }

  Future<void> _createDb(Database db, int version) async {
    try {
      print('DatabaseHelper: Creating orders table');
      await db.execute('''
        CREATE TABLE orders(
          id TEXT PRIMARY KEY,
          customerName TEXT NOT NULL,
          phoneNumber TEXT NOT NULL,
          totalAmount REAL NOT NULL,
          date TEXT NOT NULL,
          items TEXT NOT NULL
        )
      ''');
      print('DatabaseHelper: Orders table created successfully');
    } catch (e) {
      print('DatabaseHelper: Error creating database table: $e');
      print('DatabaseHelper: Error stack trace:');
      print(StackTrace.current);
      rethrow;
    }
  }

  // Save a new order to the database
  Future<void> saveOrder(Order order) async {
    try {
      print('DatabaseHelper: Getting database instance');
      final db = await database;
      print('DatabaseHelper: Converting order to map');
      final orderMap = order.toMap();
      print('DatabaseHelper: Inserting order into database');
      await db.insert(
        'orders',
        orderMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('DatabaseHelper: Order saved successfully');
    } catch (e) {
      print('DatabaseHelper: Error saving order: $e');
      print('DatabaseHelper: Error stack trace:');
      print(StackTrace.current);
      rethrow;
    }
  }

  // Get all orders
  Future<List<Order>> getOrders() async {
    try {
      print('DatabaseHelper: Getting database instance for retrieving orders');
      final db = await database;
      print('DatabaseHelper: Querying orders table');
      final List<Map<String, dynamic>> maps = await db.query('orders', orderBy: 'date DESC');
      print('DatabaseHelper: Found ${maps.length} orders');
      
      return List.generate(maps.length, (i) {
        try {
          return Order.fromMap(maps[i]);
        } catch (e) {
          print('DatabaseHelper: Error parsing order at index $i: $e');
          rethrow;
        }
      });
    } catch (e) {
      print('DatabaseHelper: Error getting orders: $e');
      print('DatabaseHelper: Error stack trace:');
      print(StackTrace.current);
      return [];
    }
  }

  // Get a specific order by ID
  Future<Order?> getOrder(String id) async {
    try {
      print('DatabaseHelper: Getting database instance for retrieving order $id');
      final db = await database;
      print('DatabaseHelper: Querying order with ID: $id');
      final List<Map<String, dynamic>> maps = await db.query(
        'orders',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isNotEmpty) {
        print('DatabaseHelper: Order found, parsing');
        return Order.fromMap(maps.first);
      }
      print('DatabaseHelper: Order not found');
      return null;
    } catch (e) {
      print('DatabaseHelper: Error getting order $id: $e');
      print('DatabaseHelper: Error stack trace:');
      print(StackTrace.current);
      rethrow;
    }
  }

  // Delete an order
  Future<void> deleteOrder(String id) async {
    try {
      print('DatabaseHelper: Getting database instance for deleting order $id');
      final db = await database;
      print('DatabaseHelper: Deleting order with ID: $id');
      await db.delete(
        'orders',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('DatabaseHelper: Order deleted successfully');
    } catch (e) {
      print('DatabaseHelper: Error deleting order $id: $e');
      print('DatabaseHelper: Error stack trace:');
      print(StackTrace.current);
      rethrow;
    }
  }
}
