import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartExportService {
  // Export cart to a .srkl file and share it
  static Future<void> exportCart(List<CartItem> items, String orderNumber) async {
    try {
      print('CartExportService: Exporting ${items.length} items to .srkl file');
      
      // Create a JSON representation of the cart
      final cartData = {
        'orderNumber': orderNumber,
        'timestamp': DateTime.now().toIso8601String(),
        'items': items.map((item) => {
          'productId': item.product.telugu,
          'weightOption': item.weightOption,
          'isPerUnit': item.isPerUnit,
          'quantity': item.quantity,
        }).toList(),
      };
      
      // Convert to JSON string
      final jsonString = jsonEncode(cartData);
      
      // Get temporary directory to store the file
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$orderNumber.srkl';
      
      // Write to file
      final file = File(filePath);
      await file.writeAsString(jsonString);
      
      print('CartExportService: File created at $filePath');
      
      // Save a copy to the app's documents directory for easier import
      try {
        final appDocDir = await getApplicationDocumentsDirectory();
        final savedFilePath = '${appDocDir.path}/$orderNumber.srkl';
        final savedFile = File(savedFilePath);
        await savedFile.writeAsString(jsonString);
        print('CartExportService: Saved copy at $savedFilePath');
      } catch (e) {
        print('CartExportService: Error saving copy: $e');
      }
      
      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Sarukulu Cart Export',
        text: 'Here is my Sarukulu shopping cart. Open this file in the Sarukulu app to import it.',
      );
      
      print('CartExportService: File shared successfully');
    } catch (e) {
      print('CartExportService: Error exporting cart: $e');
      rethrow;
    }
  }
  
  // Import cart from a .srkl file
  static Future<List<CartItem>?> importCart(List<Product> availableProducts, BuildContext context) async {
    try {
      print('CartExportService: Starting cart import');
      
      // Create a sample cart file for testing on first run
      final appDocDir = await getApplicationDocumentsDirectory();
      final sampleFilePath = '${appDocDir.path}/sample-cart.srkl';
      final sampleFile = File(sampleFilePath);
      
      if (!await sampleFile.exists()) {
        try {
          // Create a sample cart JSON
          final sampleCartData = {
            'orderNumber': 'SAMPLE-${DateTime.now().millisecondsSinceEpoch}',
            'timestamp': DateTime.now().toIso8601String(),
            'items': [
              {
                'productId': availableProducts.isNotEmpty ? availableProducts.first.telugu : 'sample-product',
                'weightOption': '1K',
                'isPerUnit': false,
                'quantity': 1,
              }
            ],
          };
          
          // Save the sample file
          await sampleFile.writeAsString(jsonEncode(sampleCartData));
          print('CartExportService: Created sample file at $sampleFilePath');
        } catch (e) {
          print('CartExportService: Error creating sample file: $e');
        }
      }
      
      // List of directories to search for .srkl files
      final List<Directory> dirsToSearch = [];
      
      // Add application documents directory (highest priority)
      dirsToSearch.add(appDocDir);
      print('CartExportService: Added app documents directory: ${appDocDir.path}');
      
      // Add downloads directory if it exists
      try {
        // Try standard Downloads folder
        final downloadsDir = Directory('${appDocDir.parent.path}/Download');
        if (await downloadsDir.exists()) {
          dirsToSearch.add(downloadsDir);
          print('CartExportService: Added downloads directory: ${downloadsDir.path}');
        }
        
        // Try alternative Downloads folder name
        final downloadsDir2 = Directory('${appDocDir.parent.path}/Downloads');
        if (await downloadsDir2.exists()) {
          dirsToSearch.add(downloadsDir2);
          print('CartExportService: Added alternative downloads directory: ${downloadsDir2.path}');
        }
      } catch (e) {
        print('CartExportService: Error accessing downloads directory: $e');
      }
      
      // Add external storage directory if available
      try {
        final externalDirs = await getExternalStorageDirectories();
        if (externalDirs != null && externalDirs.isNotEmpty) {
          dirsToSearch.addAll(externalDirs);
          print('CartExportService: Added ${externalDirs.length} external storage directories:');
          for (var dir in externalDirs) {
            print('  - ${dir.path}');
          }
        }
      } catch (e) {
        print('CartExportService: Error accessing external storage: $e');
      }
      
      // Add temporary directory
      final tempDir = await getTemporaryDirectory();
      dirsToSearch.add(tempDir);
      print('CartExportService: Added temporary directory: ${tempDir.path}');
      
      // Search for .srkl files in all directories
      List<File> allSrklFiles = [];
      
      for (var dir in dirsToSearch) {
        try {
          final srklFiles = await _findSrklFilesInDir(dir);
          allSrklFiles.addAll(srklFiles);
          print('CartExportService: Found ${srklFiles.length} .srkl files in ${dir.path}');
          for (var file in srklFiles) {
            print('  - ${file.path} (${_formatDate(file.statSync().modified)})');
          }
        } catch (e) {
          print('CartExportService: Error searching in ${dir.path}: $e');
        }
      }
      
      if (allSrklFiles.isEmpty) {
        print('CartExportService: No .srkl files found in any directory');
        
        // Create a sample cart file for testing
        if (context.mounted) {
          final bool createSample = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('No Cart Files Found'),
              content: const Text(
                'No .srkl files were found on your device. Would you like to create a sample cart with some items for testing?'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Create Sample'),
                ),
              ],
            ),
          ) ?? false;
          
          if (createSample) {
            return _createSampleCart(availableProducts);
          }
        }
        
        return null;
      }
      
      // Sort by modification time (newest first)
      allSrklFiles.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      
      // Let user choose from available files if there are multiple
      File selectedFile;
      if (allSrklFiles.length > 1 && context.mounted) {
        final selectedFilePath = await _showFileSelectionDialog(context, allSrklFiles);
        if (selectedFilePath == null) {
          print('CartExportService: File selection cancelled');
          return null;
        }
        selectedFile = File(selectedFilePath);
      } else {
        // Use the most recent file
        selectedFile = allSrklFiles.first;
      }
      
      print('CartExportService: Using .srkl file: ${selectedFile.path}');
      
      // Read file content
      String jsonString;
      try {
        jsonString = await selectedFile.readAsString();
        print('CartExportService: File content: ${jsonString.substring(0, min(100, jsonString.length))}...');
      } catch (e) {
        print('CartExportService: Error reading file: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error reading file: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }
      
      final cartItems = await _processCartJson(jsonString, availableProducts);
      print('CartExportService: Processed ${cartItems?.length ?? 0} cart items');
      
      return cartItems;
    } catch (e) {
      print('CartExportService: Error importing cart: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing cart: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      return null;
    }
  }
  
  // Find .srkl files in a directory and its subdirectories
  static Future<List<File>> _findSrklFilesInDir(Directory directory) async {
    List<File> srklFiles = [];
    
    try {
      print('CartExportService: Searching in ${directory.path}');
      
      // Check if directory exists
      if (!await directory.exists()) {
        print('CartExportService: Directory does not exist: ${directory.path}');
        return srklFiles;
      }
      
      // List files in directory (non-recursive for better performance)
      await for (var entity in directory.list(recursive: false, followLinks: false)) {
        try {
          if (entity is File && entity.path.toLowerCase().endsWith('.srkl')) {
            srklFiles.add(entity);
            print('CartExportService: Found file: ${entity.path}');
          } else if (entity is Directory && entity.path.contains('Download')) {
            // Only check subdirectories that might contain downloads
            try {
              await for (var subEntity in entity.list(recursive: false, followLinks: false)) {
                if (subEntity is File && subEntity.path.toLowerCase().endsWith('.srkl')) {
                  srklFiles.add(subEntity);
                  print('CartExportService: Found file in subdirectory: ${subEntity.path}');
                }
              }
            } catch (e) {
              print('CartExportService: Error listing subdirectory ${entity.path}: $e');
            }
          }
        } catch (e) {
          print('CartExportService: Error processing entity ${entity.path}: $e');
        }
      }
    } catch (e) {
      print('CartExportService: Error listing directory ${directory.path}: $e');
    }
    
    return srklFiles;
  }
  
  // Process cart JSON and convert to cart items
  static Future<List<CartItem>?> _processCartJson(String jsonString, List<Product> availableProducts) async {
    try {
      // Parse JSON
      final Map<String, dynamic> cartData = jsonDecode(jsonString);
      
      // Validate data structure
      if (!cartData.containsKey('items') || !(cartData['items'] is List)) {
        print('CartExportService: Invalid file format');
        return null;
      }
      
      // Convert to cart items
      final List<dynamic> itemsJson = cartData['items'];
      final items = <CartItem>[];
      
      for (var itemJson in itemsJson) {
        // Find the product in available products
        final productId = itemJson['productId'];
        final product = availableProducts.firstWhere(
          (p) => p.telugu == productId,
          orElse: () {
            print('CartExportService: Product not found: $productId');
            return Product(telugu: productId, weights: {}, type: 'unknown');
          },
        );
        
        // Skip products that don't exist in the current catalog
        if (product.type == 'unknown') {
          print('CartExportService: Skipping unknown product: $productId');
          continue;
        }
        
        // Create cart item
        final cartItem = CartItem(
          product: product,
          weightOption: itemJson['weightOption'] ?? '1K',
          isPerUnit: itemJson['isPerUnit'] ?? false,
        );
        
        // Set quantity
        cartItem.quantity = itemJson['quantity'] ?? 1;
        
        items.add(cartItem);
      }
      
      print('CartExportService: Imported ${items.length} items');
      return items;
    } catch (e) {
      print('CartExportService: Error processing cart JSON: $e');
      return null;
    }
  }
  
  // Show dialog to choose import action
  static Future<ImportAction> _showImportDialog(BuildContext context) async {
    return await showDialog<ImportAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Cart'),
        content: const Text(
          'The app will search for .srkl files on your device. Make sure you have shared a cart file to your device first.\n\n'
          'You can also create a sample cart with some items for testing.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(ImportAction.cancel),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(ImportAction.createSample),
            child: const Text('Create Sample'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(ImportAction.search),
            child: const Text('Search Files'),
          ),
        ],
      ),
    ) ?? ImportAction.cancel;
  }
  
  // Show dialog to select a file from multiple options
  static Future<String?> _showFileSelectionDialog(BuildContext context, List<File> files) async {
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Cart File'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              final fileName = file.path.split('/').last;
              final modifiedDate = file.statSync().modified;
              
              return ListTile(
                title: Text(fileName),
                subtitle: Text('Modified: ${_formatDate(modifiedDate)}'),
                onTap: () => Navigator.of(context).pop(file.path),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  // Format date for display
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
           '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  // Create a sample cart with some items for testing
  static List<CartItem> _createSampleCart(List<Product> availableProducts) {
    final items = <CartItem>[];
    
    // Add a few sample items if products are available
    if (availableProducts.isNotEmpty) {
      // Try to find rice products
      final riceProducts = availableProducts.where((p) => 
        p.type.toLowerCase() == 'rice' || 
        p.telugu.toLowerCase().contains('బీయ్యం')).toList();
      
      if (riceProducts.isNotEmpty) {
        final riceProduct = riceProducts.first;
        final weightOptions = riceProduct.weights.keys.toList();
        if (weightOptions.isNotEmpty) {
          items.add(CartItem(
            product: riceProduct,
            weightOption: weightOptions.first,
            isPerUnit: false,
          ));
        }
      }
      
      // Try to find flour products
      final flourProducts = availableProducts.where((p) => 
        p.type.toLowerCase() == 'flours_and_grains' || 
        p.telugu.toLowerCase().contains('ఆటా')).toList();
      
      if (flourProducts.isNotEmpty) {
        final flourProduct = flourProducts.first;
        final weightOptions = flourProduct.weights.keys.toList();
        if (weightOptions.isNotEmpty) {
          items.add(CartItem(
            product: flourProduct,
            weightOption: weightOptions.first,
            isPerUnit: false,
          ));
        }
      }
      
      // If we couldn't find specific products, just add the first few available
      if (items.isEmpty && availableProducts.length >= 2) {
        for (var i = 0; i < 2; i++) {
          final product = availableProducts[i];
          final weightOptions = product.weights.keys.toList();
          if (weightOptions.isNotEmpty) {
            items.add(CartItem(
              product: product,
              weightOption: weightOptions.first,
              isPerUnit: false,
            ));
          }
        }
      }
    }
    
    print('CartExportService: Created sample cart with ${items.length} items');
    return items;
  }
  
  // Generate a unique order number
  static String generateOrderNumber() {
    final now = DateTime.now();
    final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    return 'SRKL-$timestamp';
  }
}

enum ImportAction {
  cancel,
  search,
  createSample,
}
