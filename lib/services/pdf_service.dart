import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/order.dart';

class PdfService {
  // Google Apps Script URL for fetching product data
  static final String appsScriptUrl = 'https://script.google.com/macros/s/AKfycbxNP4QfPQp6KihAsaYQppSL_vHFON7P0ngpKdWkNFRWBnjLzxBpwq13qSrWVG5CLYfAcg/exec';
  
  // Map to cache English names
  static Map<String, String> _englishNameCache = {};
  
  // Fetch English names from the Google Sheet
  static Future<void> _fetchEnglishNames() async {
    try {
      print('PdfService: Fetching English names from Google Sheet');
      
      if (_englishNameCache.isNotEmpty) {
        print('PdfService: Using cached English names');
        return;
      }
      
      final headers = {
        'Accept': 'application/json',
        'User-Agent': 'Mozilla/5.0 Flutter App',
      };
      
      final response = await http.get(Uri.parse(appsScriptUrl), headers: headers);
      
      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        
        for (var product in jsonData) {
          if (product['telugu'] != null && product['english'] != null) {
            _englishNameCache[product['telugu']] = product['english'];
            print('PdfService: Cached English name for ${product['telugu']}: ${product['english']}');
          }
        }
        
        print('PdfService: Cached ${_englishNameCache.length} English names');
      } else {
        print('PdfService: Failed to fetch English names: ${response.statusCode}');
      }
    } catch (e) {
      print('PdfService: Error fetching English names: $e');
    }
  }
  
  // Get English name for a Telugu product name
  static String _getEnglishName(String teluguName) {
    return _englishNameCache[teluguName] ?? '';
  }

  // Generate and print an order receipt
  static Future<void> generateAndPrintOrder(Order order) async {
    try {
      print('PdfService: Starting PDF generation for order ${order.id}');
      
      // Fetch English names before generating PDF
      await _fetchEnglishNames();
      
      final pdf = await generateOrderPdf(order);
      print('PdfService: PDF document created, initiating printing');
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async {
          print('PdfService: Preparing PDF layout for printing');
          return pdf.save();
        },
      );
      print('PdfService: PDF printing completed');
    } catch (e) {
      print('PdfService: Error in generateAndPrintOrder: $e');
      print('PdfService: Error stack trace:');
      print(StackTrace.current);
      rethrow;
    }
  }

  // Generate and save an order receipt
  static Future<File> generateAndSaveOrder(Order order) async {
    try {
      print('PdfService: Starting PDF generation for saving order ${order.id}');
      
      // Fetch English names before generating PDF
      await _fetchEnglishNames();
      
      final pdf = await generateOrderPdf(order);
      
      // Get the documents directory
      print('PdfService: Getting temporary directory');
      final output = await getTemporaryDirectory();
      final filePath = '${output.path}/Order_${order.id}.pdf';
      print('PdfService: PDF will be saved to: $filePath');
      
      final file = File(filePath);
      
      // Save the PDF file
      print('PdfService: Saving PDF to file');
      await file.writeAsBytes(await pdf.save());
      print('PdfService: PDF saved successfully');
      return file;
    } catch (e) {
      print('PdfService: Error in generateAndSaveOrder: $e');
      print('PdfService: Error stack trace:');
      print(StackTrace.current);
      rethrow;
    }
  }

  // Generate the PDF document for an order
  static Future<pw.Document> generateOrderPdf(Order order) async {
    try {
      print('PdfService: Creating PDF document');
      final pdf = pw.Document();
      
      // Use standard fonts instead of Google Fonts to avoid issues
      print('PdfService: Setting up fonts');
      final font = pw.Font.helvetica();
      final fontBold = pw.Font.helveticaBold();
      
      // For Telugu text, we'll use the English name in the PDF since
      // standard PDF fonts don't support Telugu characters
      
      print('PdfService: Adding page to PDF document');
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            print('PdfService: Building PDF content');
            return [
              _buildHeader(order, fontBold),
              pw.SizedBox(height: 20),
              _buildCustomerInfo(order, font, fontBold),
              pw.SizedBox(height: 20),
              _buildItemsTable(order, font, fontBold),
              pw.SizedBox(height: 20),
              _buildTotal(order, font, fontBold),
              pw.SizedBox(height: 40),
              _buildFooter(font),
            ];
          },
        ),
      );
      
      print('PdfService: PDF document generated successfully');
      return pdf;
    } catch (e) {
      print('PdfService: Error in generateOrderPdf: $e');
      print('PdfService: Error stack trace:');
      print(StackTrace.current);
      rethrow;
    }
  }

  // Build the header section of the PDF
  static pw.Widget _buildHeader(Order order, pw.Font fontBold) {
    try {
      print('PdfService: Building PDF header');
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'GROCERY ORDER RECEIPT',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 24,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Order #: ${order.id}',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 14,
            ),
          ),
          pw.Text(
            'Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(order.date)}',
            style: pw.TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      );
    } catch (e) {
      print('PdfService: Error in _buildHeader: $e');
      rethrow;
    }
  }

  // Build the customer information section
  static pw.Widget _buildCustomerInfo(Order order, pw.Font font, pw.Font fontBold) {
    try {
      print('PdfService: Building customer info section');
      return pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey200,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'CUSTOMER INFORMATION',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 14,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Name: ${order.customerName}'),
            pw.Text('Phone: ${order.phoneNumber}'),
          ],
        ),
      );
    } catch (e) {
      print('PdfService: Error in _buildCustomerInfo: $e');
      rethrow;
    }
  }

  // Build the items table
  static pw.Widget _buildItemsTable(Order order, pw.Font font, pw.Font fontBold) {
    try {
      print('PdfService: Building items table with ${order.items.length} items');
      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400),
        columnWidths: {
          0: const pw.FlexColumnWidth(4),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(2),
          3: const pw.FlexColumnWidth(2),
        },
        children: [
          // Table header
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey300),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  'Item',
                  style: pw.TextStyle(font: fontBold),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  'Quantity',
                  style: pw.TextStyle(font: fontBold),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  'Unit Price',
                  style: pw.TextStyle(font: fontBold),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  'Total',
                  style: pw.TextStyle(font: fontBold),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
          // Table rows for each item
          ...order.items.map((item) {
            try {
              final unitPrice = item.price / item.quantity;
              final englishName = _getEnglishName(item.product.telugu);
              
              // Prioritize English name since Telugu fonts aren't supported
              final displayName = englishName.isNotEmpty 
                  ? englishName
                  : item.product.telugu;
                  
              return pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      item.isPerUnit 
                        ? '$displayName (Per Unit)'
                        : '$displayName (${item.weightOption})',
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('${item.quantity}'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      'Rs ${unitPrice.toStringAsFixed(2)}',
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      'Rs ${item.price.toStringAsFixed(2)}',
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              );
            } catch (e) {
              print('PdfService: Error creating row for item ${item.product.telugu}: $e');
              rethrow;
            }
          }).toList(),
        ],
      );
    } catch (e) {
      print('PdfService: Error in _buildItemsTable: $e');
      rethrow;
    }
  }

  // Build the total section
  static pw.Widget _buildTotal(Order order, pw.Font font, pw.Font fontBold) {
    try {
      print('PdfService: Building total section');
      return pw.Container(
        alignment: pw.Alignment.centerRight,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Divider(),
            pw.SizedBox(height: 5),
            pw.Row(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(
                  'Total Amount:',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 16,
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Text(
                  'Rs ${order.totalAmount.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } catch (e) {
      print('PdfService: Error in _buildTotal: $e');
      rethrow;
    }
  }

  // Build the footer section
  static pw.Widget _buildFooter(pw.Font font) {
    try {
      print('PdfService: Building footer section');
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'Thank you for your order!',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'For any inquiries, please contact us.',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
        ],
      );
    } catch (e) {
      print('PdfService: Error in _buildFooter: $e');
      rethrow;
    }
  }
}
