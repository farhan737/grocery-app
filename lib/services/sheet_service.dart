import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../utils/mock_data.dart';

class SheetService {
  // Google Apps Script Web App URL
  // IMPORTANT: Replace this with your actual deployed Apps Script URL
  // The URL should look like: https://script.google.com/macros/s/AKfycbxxxxxxxxxxxxxxxxxxxxx/exec
  final String appsScriptUrl = 'https://script.google.com/macros/s/AKfycbzK8sWfcbhjQMfhffHhCnzHzotkTXNJSlupBcxlIe_uYbobj5B6jUZrhu-JFRHIcntRxw/exec';
  
  // Note: If you get an HTML error response, it means your Apps Script is not properly deployed
  // or not set to be accessible by 'Anyone'. See the deployment instructions.
  
  bool _useMockData = false;
  int _retryCount = 0;
  final int _maxRetries = 3;

  // Fetch all products from the Google Sheet
  Future<List<Product>> fetchProducts() async {
    try {
      // If we've already tried and failed with the API, use mock data
      if (_useMockData) {
        print('Using mock data instead of API');
        return _getMockProducts();
      }
      
      print('Fetching products from Apps Script: $appsScriptUrl');
      print('Retry count: $_retryCount of $_maxRetries');
      
      // Add headers to mimic a browser request
      final headers = {
        'Accept': 'application/json',
        'User-Agent': 'Mozilla/5.0 Flutter App',
      };
      
      final response = await http.get(Uri.parse(appsScriptUrl), headers: headers);
      
      print('Response status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        // Print a sample of the response body for debugging
        print('Response body sample: ${response.body.substring(0, min(500, response.body.length))}...');
        
        // Check if the response is HTML instead of JSON
        if (response.body.trim().startsWith('<!DOCTYPE html>') || 
            response.body.trim().startsWith('<html>')) {
          print('Received HTML instead of JSON. This usually indicates an authentication issue.');
          
          // Try again if we haven't reached max retries
          if (_retryCount < _maxRetries) {
            _retryCount++;
            print('Retrying... Attempt $_retryCount of $_maxRetries');
            // Add a small delay before retrying
            await Future.delayed(Duration(seconds: 2));
            return fetchProducts();
          } else {
            print('Max retries reached. Switching to mock data for testing purposes.');
            _useMockData = true;
            return _getMockProducts();
          }
        }
        
        // Reset retry count on success
        _retryCount = 0;
        
        // Parse JSON data
        List<dynamic> jsonData = json.decode(response.body);
        print('Received ${jsonData.length} products from JSON API');
        
        List<Product> products = [];
        for (var i = 0; i < jsonData.length; i++) {
          try {
            products.add(Product.fromJson(jsonData[i]));
          } catch (e) {
            print('Error parsing product at index $i: $e');
            print('Product data: ${jsonData[i]}');
          }
        }
        print('Successfully parsed ${products.length} products from JSON');
        
        print('Successfully parsed ${products.length} products');
        return products;
      } else {
        print('Failed to load products: ${response.statusCode}');
        print('Response body: ${response.body}');
        
        // Try again if we haven't reached max retries
        if (_retryCount < _maxRetries) {
          _retryCount++;
          print('Retrying... Attempt $_retryCount of $_maxRetries');
          // Add a small delay before retrying
          await Future.delayed(Duration(seconds: 2));
          return fetchProducts();
        } else {
          print('Max retries reached. Switching to mock data for testing purposes.');
          _useMockData = true;
          return _getMockProducts();
        }
      }
    } catch (e, stackTrace) {
      print('Error fetching products: $e');
      print('Stack trace: $stackTrace');
      
      // Try again if we haven't reached max retries
      if (_retryCount < _maxRetries) {
        _retryCount++;
        print('Retrying after error... Attempt $_retryCount of $_maxRetries');
        // Add a small delay before retrying
        await Future.delayed(Duration(seconds: 2));
        return fetchProducts();
      } else {
        print('Max retries reached. Switching to mock data for testing purposes.');
        _useMockData = true;
        return _getMockProducts();
      }
    }
  }
  
  // Get mock products for testing when API is unavailable
  List<Product> _getMockProducts() {
    print('Creating mock products for testing');
    return MockData.getMockProducts();
  }

  // Group products by their type
  Map<String, List<Product>> groupProductsByType(List<Product> products) {
    Map<String, List<Product>> groupedProducts = {};
    
    for (var product in products) {
      if (!groupedProducts.containsKey(product.type)) {
        groupedProducts[product.type] = [];
      }
      groupedProducts[product.type]!.add(product);
    }
    
    return groupedProducts;
  }
}
