import '../models/product.dart';

/// Utility class to parse CSV data into Product objects
class CsvParser {
  /// Parse CSV file content into a list of Product objects
  static List<Product> parseProductsFromCsv(String csvContent) {
    List<Product> products = [];
    List<String> lines = csvContent.split('\n');
    
    // Skip header line
    if (lines.length > 1) {
      lines = lines.sublist(1);
    }
    
    for (String line in lines) {
      // Skip empty lines
      if (line.trim().isEmpty) continue;
      
      try {
        // Split by comma, but handle commas within quotes
        List<String> columns = _splitCsvLine(line);
        
        // Ensure we have enough columns
        if (columns.length < 12) {
          print('Warning: Skipping line with insufficient columns: $line');
          continue;
        }
        
        // Extract product data
        String telugu = columns[0].trim();
        
        // Skip products with empty Telugu name
        if (telugu.isEmpty) continue;
        
        // Parse weight prices
        Map<String, double?> weights = {
          '1K': _parsePrice(columns[2]),
          '0.5K': _parsePrice(columns[3]),
          '250G': _parsePrice(columns[4]),
          '100G': _parsePrice(columns[5]),
          '50G': _parsePrice(columns[6]),
          '25G': _parsePrice(columns[7]),
          '10G': _parsePrice(columns[8]),
          '5K': _parsePrice(columns[9]),
        };
        
        // Parse price per unit
        double? pricePerUnit = _parsePrice(columns[10]);
        
        // Get product type
        String type = columns[11].trim().isEmpty ? 'other' : columns[11].trim();
        
        // Create product
        Product product = Product(
          telugu: telugu,
          weights: weights,
          pricePerUnit: pricePerUnit,
          type: type,
        );
        
        products.add(product);
        
      } catch (e) {
        print('Error parsing line: $line');
        print('Error details: $e');
      }
    }
    
    print('Successfully parsed ${products.length} products from CSV');
    return products;
  }
  
  /// Parse price from string, handling various formats
  static double? _parsePrice(String value) {
    value = value.trim();
    
    // Handle empty or placeholder values
    if (value.isEmpty || value == '\$' || value == 'null') {
      return null;
    }
    
    // Handle price per N format (e.g., "30/6")
    if (value.contains('/')) {
      List<String> parts = value.split('/');
      if (parts.length == 2) {
        try {
          double price = double.parse(parts[0]);
          int quantity = int.parse(parts[1]);
          return price / quantity; // Return price per unit
        } catch (e) {
          print('Error parsing price per unit: $value');
          return null;
        }
      }
    }
    
    // Handle regular price
    try {
      return double.parse(value);
    } catch (e) {
      print('Error parsing price: $value');
      return null;
    }
  }
  
  /// Split CSV line handling commas within quotes
  static List<String> _splitCsvLine(String line) {
    List<String> result = [];
    bool inQuotes = false;
    String currentValue = '';
    
    for (int i = 0; i < line.length; i++) {
      String char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(currentValue);
        currentValue = '';
      } else {
        currentValue += char;
      }
    }
    
    // Add the last value
    result.add(currentValue);
    
    return result;
  }
}
