import '../models/product.dart';

/// Utility class to provide mock data for testing when the API is unavailable
class MockData {
  /// Returns a list of mock products with realistic data structure
  static List<Product> getMockProducts() {
    return [
      // Flours and Grains
      Product(
        telugu: 'బియ్యం', // Rice
        weights: {
          '1K': 60.0,
          '0.5K': 30.0,
          '250G': 15.0,
          '100G': null,
          '50G': null,
          '25G': null,
          '10G': null,
        },
        pricePerUnit: null,
        type: 'flours_and_grains',
      ),
      Product(
        telugu: 'గోధుమ పిండి', // Wheat Flour
        weights: {
          '1K': 45.0,
          '0.5K': 23.0,
          '250G': 12.0,
          '100G': null,
          '50G': null,
          '25G': null,
          '10G': null,
        },
        pricePerUnit: null,
        type: 'flours_and_grains',
      ),
      Product(
        telugu: 'రవ్వ', // Semolina
        weights: {
          '1K': 50.0,
          '0.5K': 25.0,
          '250G': 13.0,
          '100G': null,
          '50G': null,
          '25G': null,
          '10G': null,
        },
        pricePerUnit: null,
        type: 'flours_and_grains',
      ),
      
      // Spices and Condiments
      Product(
        telugu: 'పసుపు', // Turmeric
        weights: {
          '1K': null,
          '0.5K': null,
          '250G': 60.0,
          '100G': 25.0,
          '50G': 13.0,
          '25G': 7.0,
          '10G': 3.0,
        },
        pricePerUnit: null,
        type: 'spices_and_condiments',
      ),
      Product(
        telugu: 'మిరియాలు', // Black Pepper
        weights: {
          '1K': null,
          '0.5K': null,
          '250G': 180.0,
          '100G': 75.0,
          '50G': 38.0,
          '25G': 20.0,
          '10G': 8.0,
        },
        pricePerUnit: null,
        type: 'spices_and_condiments',
      ),
      Product(
        telugu: 'జీలకర్ర', // Cumin
        weights: {
          '1K': null,
          '0.5K': null,
          '250G': 120.0,
          '100G': 50.0,
          '50G': 25.0,
          '25G': 13.0,
          '10G': 6.0,
        },
        pricePerUnit: null,
        type: 'spices_and_condiments',
      ),
      
      // Salts and Sugars
      Product(
        telugu: 'ఉప్పు', // Salt
        weights: {
          '1K': 20.0,
          '0.5K': 10.0,
          '250G': null,
          '100G': null,
          '50G': null,
          '25G': null,
          '10G': null,
        },
        pricePerUnit: null,
        type: 'salts_and_sugars',
      ),
      Product(
        telugu: 'పంచదార', // Sugar
        weights: {
          '1K': 40.0,
          '0.5K': 20.0,
          '250G': 10.0,
          '100G': null,
          '50G': null,
          '25G': null,
          '10G': null,
        },
        pricePerUnit: null,
        type: 'salts_and_sugars',
      ),
      Product(
        telugu: 'బెల్లం', // Jaggery
        weights: {
          '1K': 60.0,
          '0.5K': 30.0,
          '250G': 15.0,
          '100G': null,
          '50G': null,
          '25G': null,
          '10G': null,
        },
        pricePerUnit: null,
        type: 'salts_and_sugars',
      ),
      
      // Fruits and Vegetables
      Product(
        telugu: 'టమాటో', // Tomato
        weights: {
          '1K': 40.0,
          '0.5K': 20.0,
          '250G': null,
          '100G': null,
          '50G': null,
          '25G': null,
          '10G': null,
        },
        pricePerUnit: null,
        type: 'fruits_and_vegetables',
      ),
      Product(
        telugu: 'ఉల్లిపాయ', // Onion
        weights: {
          '1K': 35.0,
          '0.5K': 18.0,
          '250G': null,
          '100G': null,
          '50G': null,
          '25G': null,
          '10G': null,
        },
        pricePerUnit: null,
        type: 'fruits_and_vegetables',
      ),
      Product(
        telugu: 'బంగాళదుంప', // Potato
        weights: {
          '1K': 30.0,
          '0.5K': 15.0,
          '250G': null,
          '100G': null,
          '50G': null,
          '25G': null,
          '10G': null,
        },
        pricePerUnit: null,
        type: 'fruits_and_vegetables',
      ),
      
      // Per Unit Items
      Product(
        telugu: 'కొబ్బరికాయ', // Coconut
        weights: {
          '1K': null,
          '0.5K': null,
          '250G': null,
          '100G': null,
          '50G': null,
          '25G': null,
          '10G': null,
        },
        pricePerUnit: 25.0,
        type: 'per_unit_items',
      ),
      Product(
        telugu: 'నిమ్మకాయ', // Lemon
        weights: {
          '1K': null,
          '0.5K': null,
          '250G': null,
          '100G': null,
          '50G': null,
          '25G': null,
          '10G': null,
        },
        pricePerUnit: 5.0,
        type: 'per_unit_items',
      ),
      Product(
        telugu: 'గుడ్డు', // Egg
        weights: {
          '1K': null,
          '0.5K': null,
          '250G': null,
          '100G': null,
          '50G': null,
          '25G': null,
          '10G': null,
        },
        pricePerUnit: 7.0,
        type: 'per_unit_items',
      ),
    ];
  }
}
