class Product {
  final String telugu; // Product name in Telugu
  final Map<String, double?> weights; // Different weight options and their prices
  final double? pricePerUnit; // Price per unit (₹/N)
  final String type; // Product type (e.g., flours_and_grains)

  Product({
    required this.telugu,
    required this.weights,
    this.pricePerUnit,
    required this.type,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    try {
      // Handle both uppercase and lowercase field names for compatibility
      final telugu = json['telugu'] ?? json['TELUGU'] ?? '';
      print('Parsing product: $telugu');
      
      // Create a map for weights and their prices
      Map<String, double?> weights = {};
      
      // Check if we have a nested weights object (from Apps Script)
      if (json.containsKey('weights') && json['weights'] is Map) {
        print('Using nested weights format from Apps Script');
        Map<String, dynamic> weightsJson = json['weights'];
        
        // Debug weight values
        print('Weight values for $telugu:');
        ['1K', '0.5K', '250G', '100G', '50G', '25G', '10G', '5K'].forEach((weight) {
          final rawValue = weightsJson[weight];
          // Convert int to double if needed
          double? parsedValue;
          if (rawValue is int) {
            parsedValue = rawValue.toDouble();
          } else if (rawValue is double) {
            parsedValue = rawValue;
          }
          weights[weight] = parsedValue;
          print('  $weight: raw=$rawValue, parsed=$parsedValue');
        });
      } else {
        // Original format with weights at top level
        print('Using original format with weights at top level');
        print('Weight values for $telugu:');
        ['1K', '0.5K', '250G', '100G', '50G', '25G', '10G', '5K'].forEach((weight) {
          final rawValue = json[weight];
          final parsedValue = _parsePrice(rawValue);
          weights[weight] = parsedValue;
          print('  $weight: raw=$rawValue, parsed=$parsedValue');
        });
      }
      
      // Handle both formats for price per unit
      double? parsedPerUnit;
      if (json.containsKey('pricePerUnit')) {
        // New format from Apps Script
        var rawPerUnit = json['pricePerUnit'];
        // Convert int to double if needed
        if (rawPerUnit is int) {
          parsedPerUnit = rawPerUnit.toDouble();
        } else if (rawPerUnit is double) {
          parsedPerUnit = rawPerUnit;
        }
        print('  Per unit price (new format): raw=$rawPerUnit, parsed=$parsedPerUnit');
      } else {
        // Original format
        final rawPerUnit = json['₹/N'];
        parsedPerUnit = _parsePrice(rawPerUnit);
        print('  Per unit price (original format): raw=$rawPerUnit, parsed=$parsedPerUnit');
      }
      
      return Product(
        telugu: telugu,
        weights: weights,
        pricePerUnit: parsedPerUnit,
        type: json['type'] ?? 'unknown',
      );
    } catch (e, stackTrace) {
      print('Error creating Product from JSON: $e');
      print('JSON data: $json');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Helper method to parse price values
  static double? _parsePrice(dynamic value) {
    if (value == null || value == '' || value == '\$') {
      return null;
    }
    
    // Try to parse the value as a double
    try {
      if (value is String) {
        // Remove any currency symbols or non-numeric characters except decimal point
        String cleanValue = value.replaceAll(RegExp(r'[^\d.]'), '');
        return double.parse(cleanValue);
      } else if (value is num) {
        return value.toDouble();
      }
    } catch (e) {
      print('Error parsing price: $value');
    }
    
    return null;
  }

  // Get available weight options (non-null prices)
  Map<String, double> getAvailableWeights() {
    Map<String, double> available = {};
    weights.forEach((key, value) {
      if (value != null) {
        available[key] = value;
      }
    });
    return available;
  }

  // Check if per unit price is available
  bool hasPerUnitPrice() {
    return pricePerUnit != null;
  }
}
