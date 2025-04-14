import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import '../models/order.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) {
      print('DatabaseHelper: Returning existing database instance');
      return _database!;
    }
    
    print('DatabaseHelper: Getting database instance for the first time');
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    print('DatabaseHelper: Initializing database');
    
    // Initialize FFI for desktop platforms
    if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      print('DatabaseHelper: Using sqflite_ffi for desktop platform');
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    try {
      // Get the database path
      final Directory documentsDirectory = await getApplicationDocumentsDirectory();
      final String path = join(documentsDirectory.path, 'grocery_orders.db');
      print('DatabaseHelper: Database path: $path');
      
      // Open the database
      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
    } catch (e) {
      print('DatabaseHelper: Error initializing database: $e');
      print('DatabaseHelper: Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    print('DatabaseHelper: Creating orders table');
    try {
      await db.execute('''
        CREATE TABLE orders(
          id TEXT PRIMARY KEY,
          customerName TEXT,
          phoneNumber TEXT,
          totalAmount REAL,
          date TEXT,
          items TEXT
        )
      ''');
      print('DatabaseHelper: Orders table created successfully');
    } catch (e) {
      print('DatabaseHelper: Error creating orders table: $e');
      print('DatabaseHelper: Stack trace: ${StackTrace.current}');
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
