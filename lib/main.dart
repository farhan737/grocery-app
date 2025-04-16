import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:receive_intent/receive_intent.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'screens/home_screen.dart';
import 'providers/cart_provider.dart';
import 'models/product.dart';
import 'services/sheet_service.dart';
import 'services/cart_export_service.dart';

void main() {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _initialFilePath;
  late CartProvider _cartProvider;
  bool _productsLoaded = false;
  List<Product> _products = [];
  static const platform = MethodChannel('com.example.grocery_app/file_handler');
  bool _pendingImport = false;
  
  @override
  void initState() {
    super.initState();
    _cartProvider = CartProvider();
    _checkForFileIntent();
    _checkForNativeFileContent();
  }
  
  // Check if app was opened from a file
  Future<void> _checkForFileIntent() async {
    try {
      // Get initial platform intent if any
      final receivedIntent = await ReceiveIntent.getInitialIntent();
      print('Received intent: ${receivedIntent?.data}');
      
      if (receivedIntent?.data != null) {
        await _handleIntentData(receivedIntent!.data!);
      } else {
        print('No initial intent data received');
      }
      
      // Listen for new intents (when app is already running)
      ReceiveIntent.receivedIntentStream.listen((intent) {
        print('New intent received: ${intent?.data}');
        if (intent?.data != null) {
          _handleIntentData(intent!.data!);
        }
      });
    } catch (e) {
      print('Error checking for file intent: $e');
    }
  }
  
  // Handle intent data from file open
  Future<void> _handleIntentData(String data) async {
    try {
      print('Handling intent data: $data');
      
      // Check if this is a file URI
      if (data.toLowerCase().endsWith('.srkl')) {
        print('Direct file path detected: $data');
        _initialFilePath = data;
        
        // If products are already loaded, process immediately
        if (_productsLoaded && _products.isNotEmpty) {
          print('Products already loaded, processing file immediately');
          await _processImportFile(data);
        } else {
          print('Products not loaded yet, will process after loading');
          _pendingImport = true;
        }
        return;
      }
      
      // Parse as URI if not a direct file path
      final uri = Uri.parse(data);
      print('Parsed URI: $uri');
      print('URI scheme: ${uri.scheme}');
      print('URI path: ${uri.path}');
      
      if (uri.path.toLowerCase().endsWith('.srkl')) {
        _initialFilePath = uri.scheme == 'file' ? uri.path : data;
        print('Stored file path for processing: $_initialFilePath');
        
        // If products are already loaded, process the file immediately
        if (_productsLoaded && _products.isNotEmpty) {
          print('Products already loaded, processing file immediately');
          if (uri.scheme == 'file') {
            await _processImportFile(uri.path);
          } else if (uri.scheme == 'content') {
            await _processContentUri(data);
          }
        } else {
          print('Products not loaded yet, will process file after products are loaded');
          _pendingImport = true;
        }
      } else {
        print('File does not have .srkl extension: ${uri.path}');
      }
    } catch (e) {
      print('Error handling intent data: $e');
    }
  }
  
  // Process content URI by copying to temp file
  Future<void> _processContentUri(String contentUri) async {
    try {
      print('Processing content URI: $contentUri');
      
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/imported_cart.srkl');
      
      try {
        // Use flutter_file_dialog to handle the content URI
        final savedFilePath = await FlutterFileDialog.saveFile(
          params: SaveFileDialogParams(
            sourceFilePath: contentUri,
          ),
        );
        
        if (savedFilePath != null) {
          print('Saved content URI to file: $savedFilePath');
          await _processImportFile(savedFilePath);
          return;
        } else {
          print('Failed to save content URI to file');
        }
      } catch (e) {
        print('Error saving content URI: $e');
        
        // Try alternative approach
        try {
          // Try to open the file directly
          final file = File(contentUri);
          if (await file.exists()) {
            final content = await file.readAsString();
            await tempFile.writeAsString(content);
            print('Copied content to temp file: ${tempFile.path}');
            await _processImportFile(tempFile.path);
            return;
          } else {
            print('Content URI file does not exist directly: $contentUri');
          }
        } catch (e) {
          print('Error accessing content URI directly: $e');
        }
      }
      
      // If we get here, we couldn't read the content URI
      print('Could not process content URI: $contentUri');
      
      // Show error message and offer alternative
      if (navigatorKey.currentContext != null) {
        showDialog(
          context: navigatorKey.currentContext!,
          builder: (ctx) => AlertDialog(
            title: const Text('Cannot Open File'),
            content: const Text(
              'The app cannot directly open this file. Would you like to try importing a cart file from your device storage instead?'
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await _pickAndImportFile();
                },
                child: const Text('Import File'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error processing content URI: $e');
    }
  }
  
  // Pick a file using the file dialog and import it
  Future<void> _pickAndImportFile() async {
    try {
      final filePath = await FlutterFileDialog.pickFile(
        params: const OpenFileDialogParams(
          fileExtensionsFilter: ['srkl'],
        ),
      );
      
      if (filePath != null) {
        print('Selected file: $filePath');
        await _processImportFile(filePath);
      } else {
        print('No file selected');
      }
    } catch (e) {
      print('Error picking file: $e');
      
      if (navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Process import file and update cart
  Future<void> _processImportFile(String filePath) async {
    try {
      print('Processing import file: $filePath');
      
      // Get products - either use already loaded products or fetch them
      List<Product> products = _products;
      if (products.isEmpty) {
        print('Products not loaded yet, fetching products for import');
        
        // Show loading indicator if context is available
        if (navigatorKey.currentContext != null) {
          ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
            const SnackBar(
              content: Text('Loading products...'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        // Fetch products
        final sheetService = SheetService();
        try {
          products = await sheetService.fetchProducts();
          _productsLoaded = true;
          _products = products;
          print('Fetched ${products.length} products for import');
        } catch (e) {
          print('Error fetching products: $e');
          if (navigatorKey.currentContext != null) {
            ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
              const SnackBar(
                content: Text('Failed to load products. Please try again.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      } else {
        print('Using ${products.length} already loaded products for import');
      }
      
      if (products.isEmpty) {
        print('No products available for import');
        if (navigatorKey.currentContext != null) {
          ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
            const SnackBar(
              content: Text('Unable to load products. Please try again later.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      
      // Use the new importCartFromUri method
      final cartItems = await CartExportService.importCartFromUri(
        filePath, 
        products, 
        navigatorKey.currentContext
      );
      
      if (cartItems != null && cartItems.isNotEmpty) {
        // Clear existing cart and add new items
        _cartProvider.clearCart();
        print('Cleared existing cart');
        
        for (var item in cartItems) {
          print('Adding item to cart: ${item.product.telugu}, ${item.weightOption}, ${item.quantity}');
          _cartProvider.addItem(
            item.product, 
            item.weightOption, 
            item.quantity, 
            item.isPerUnit ?? false
          );
        }
        
        print('Cart updated with ${cartItems.length} imported items');
        
        // Show success message
        if (navigatorKey.currentContext != null) {
          ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
            const SnackBar(
              content: Text('Cart imported successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          print('No context available for showing success message');
        }
      }
    } catch (e) {
      print('Error processing import file: $e');
      if (navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          SnackBar(
            content: Text('Error importing cart: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Check for file content from native side
  Future<void> _checkForNativeFileContent() async {
    try {
      // Get file content from native side
      final fileContent = await platform.invokeMethod<String>('getFileContent');
      print('Received file content from native side: ${fileContent != null ? 'Yes (${fileContent.length} chars)' : 'No'}');
      
      if (fileContent != null && fileContent.isNotEmpty) {
        // Wait for products to load before processing
        if (!_productsLoaded || _products.isEmpty) {
          print('Products not loaded yet, will process native file content after products are loaded');
          // We'll process this in the build method after products are loaded
        } else {
          print('Products already loaded, processing native file content immediately');
          await _processFileContent(fileContent);
        }
      }
    } catch (e) {
      print('Error checking for native file content: $e');
    }
  }
  
  // Process file content directly
  Future<void> _processFileContent(String fileContent) async {
    try {
      print('Processing file content, length: ${fileContent.length}');
      
      // Get products - either use already loaded products or fetch them
      List<Product> products = _products;
      if (products.isEmpty) {
        print('Products not loaded yet, fetching products for import');
        final sheetService = SheetService();
        products = await sheetService.fetchProducts();
        _productsLoaded = true;
        _products = products;
        print('Fetched ${products.length} products for import');
      } else {
        print('Using ${products.length} already loaded products for import');
      }
      
      if (products.isEmpty) {
        print('No products available for import');
        if (navigatorKey.currentContext != null) {
          ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
            const SnackBar(
              content: Text('Unable to load products. Please try again later.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      
      // Process the cart items
      final cartItems = await CartExportService.processImportedJson(fileContent, products);
      print('Processed cart items: ${cartItems?.length ?? 0}');
      
      if (cartItems != null && cartItems.isNotEmpty) {
        // Clear existing cart and add new items
        _cartProvider.clearCart();
        print('Cleared existing cart');
        
        for (var item in cartItems) {
          print('Adding item to cart: ${item.product.telugu}, ${item.weightOption}, ${item.quantity}');
          _cartProvider.addItem(
            item.product, 
            item.weightOption, 
            item.quantity, 
            item.isPerUnit ?? false
          );
        }
        
        print('Cart updated with ${cartItems.length} imported items');
        
        // Show success message
        if (navigatorKey.currentContext != null) {
          ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
            const SnackBar(
              content: Text('Cart imported successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          print('No context available for showing success message');
        }
      } else {
        print('No valid cart items found in the file content');
        if (navigatorKey.currentContext != null) {
          ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
            const SnackBar(
              content: Text('No valid items found in the cart file'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Error processing file content: $e');
      if (navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          SnackBar(
            content: Text('Error importing cart: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Global navigator key to access context from anywhere
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CartProvider>(
          create: (_) => _cartProvider,
        ),
        Provider<Future<List<Product>>>(
          create: (context) async {
            final sheetService = SheetService();
            print('Loading products from Google Sheets...');
            final products = await sheetService.fetchProducts();
            _productsLoaded = true;
            _products = products;
            print('Products loaded successfully: ${products.length} products');
            
            // Process pending file import if there is one
            if (_initialFilePath != null) {
              print('Processing pending file: $_initialFilePath');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final uri = Uri.parse(_initialFilePath!);
                if (uri.scheme == 'file') {
                  _processImportFile(_initialFilePath!);
                } else if (uri.scheme == 'content') {
                  _processContentUri(_initialFilePath!);
                } else {
                  // Try direct file path
                  _processImportFile(_initialFilePath!);
                }
              });
            } else if (_pendingImport) {
              print('Checking for pending imports after products loaded');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _checkForFileIntent();
                _checkForNativeFileContent();
              });
              _pendingImport = false;
            }
            
            return products;
          },
          lazy: false, // Load products immediately
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Sarukulu',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.light(
            primary: Color(0xFF6A1B9A),         // Deep Purple 800
            onPrimary: Colors.white,
            primaryContainer: Color(0xFFD1C4E9), // Deep Purple 100
            onPrimaryContainer: Color(0xFF4A148C), // Deep Purple 900
            secondary: Color(0xFF8E24AA),       // Purple 600
            onSecondary: Colors.white,
            secondaryContainer: Color(0xFFE1BEE7), // Purple 100
            onSecondaryContainer: Color(0xFF4A148C), // Deep Purple 900
            tertiary: Color(0xFFAB47BC),        // Purple 400
            onTertiary: Colors.white,
            error: Color(0xFFB71C1C),           // Red 900
            onError: Colors.white,
            background: Color(0xFFF5F5F5),      // Grey 100
            onBackground: Color(0xFF212121),    // Grey 900
            surface: Colors.white,
            onSurface: Color(0xFF212121),       // Grey 900
            surfaceVariant: Color(0xFFEEEEEE),  // Grey 200
            onSurfaceVariant: Color(0xFF616161), // Grey 700
            outline: Color(0xFF9E9E9E),         // Grey 500
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Color(0xFF6A1B9A),  // Deep Purple 800
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          cardTheme: CardTheme(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6A1B9A),  // Deep Purple 800
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFF6A1B9A),  // Deep Purple 800
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: Color(0xFF6A1B9A),  // Deep Purple 800
              side: BorderSide(color: Color(0xFF6A1B9A), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          iconTheme: IconThemeData(
            color: Color(0xFF6A1B9A),  // Deep Purple 800
            size: 24,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFFBDBDBD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFFBDBDBD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF6A1B9A), width: 2),
            ),
          ),
          dividerTheme: DividerThemeData(
            color: Color(0xFFE0E0E0),  // Grey 300
            thickness: 1,
            space: 24,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.dark(
            primary: Color(0xFFB39DDB),         // Deep Purple 200
            onPrimary: Color(0xFF4A148C),       // Deep Purple 900
            primaryContainer: Color(0xFF6A1B9A), // Deep Purple 800
            onPrimaryContainer: Color(0xFFD1C4E9), // Deep Purple 100
            secondary: Color(0xFFCE93D8),       // Purple 200
            onSecondary: Color(0xFF4A148C),     // Deep Purple 900
            secondaryContainer: Color(0xFF8E24AA), // Purple 600
            onSecondaryContainer: Color(0xFFE1BEE7), // Purple 100
            tertiary: Color(0xFFE1BEE7),        // Purple 100
            onTertiary: Color(0xFF4A148C),      // Deep Purple 900
            error: Color(0xFFEF9A9A),           // Red 200
            onError: Color(0xFF7F0000),         // Red 900
            background: Color(0xFF121212),      // Grey 900
            onBackground: Color(0xFFEEEEEE),    // Grey 200
            surface: Color(0xFF212121),         // Grey 900
            onSurface: Color(0xFFEEEEEE),       // Grey 200
            surfaceVariant: Color(0xFF424242),  // Grey 800
            onSurfaceVariant: Color(0xFFBDBDBD), // Grey 400
            outline: Color(0xFF757575),         // Grey 600
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Color(0xFF4A148C),  // Deep Purple 900
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          cardTheme: CardTheme(
            color: Color(0xFF212121),           // Grey 900
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFB39DDB),  // Deep Purple 200
              foregroundColor: Color(0xFF4A148C),  // Deep Purple 900
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFFB39DDB),  // Deep Purple 200
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: Color(0xFFB39DDB),  // Deep Purple 200
              side: BorderSide(color: Color(0xFFB39DDB), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          iconTheme: IconThemeData(
            color: Color(0xFFB39DDB),  // Deep Purple 200
            size: 24,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Color(0xFF424242),  // Grey 800
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF616161)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF616161)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFFB39DDB), width: 2),
            ),
          ),
          dividerTheme: DividerThemeData(
            color: Color(0xFF424242),  // Grey 800
            thickness: 1,
            space: 24,
          ),
        ),
        themeMode: ThemeMode.system, // Uses the system theme by default
        home: HomeScreen(),
      ),
    );
  }
}
