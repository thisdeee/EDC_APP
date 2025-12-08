import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ApiService {
  static const String baseUrl = 'https://api.bbbb.com.la';

  // Send GraphQL request using http package
  static Future<Map<String, dynamic>> _sendGraphQLRequest({
    required String query,
    required Map<String, dynamic> variables,
  }) async {
    final response = await http
        .post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'query': query,
        'variables': variables,
      }),
    )
        .timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw TimeoutException('Connection timeout after 30 seconds');
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  static Future<List<Product>> fetchProducts() async {
    try {
      print('========== GraphQL API REQUEST ==========');
      print('Connecting to: $baseUrl');

      // GraphQL Query
      const String query = '''
        query StocksV2(\$where: StockWhereInput, \$skip: Int, \$limit: Int) {
          stocksV2(where: \$where, skip: \$skip, limit: \$limit) {
            total
            data {
              amount
              id
              image
              name
              price
              amountAll
              descriptions {
                image
                title
              }
              unit
              coverImages
              containImages
              isUsingSalePage
            }
          }
        }
      ''';

      // Variables with shop ID
      final variables = {
        'where': {
          'shop': '6864d7d2f32c2508f58eb7e8',
        },
        'skip': 0,
        'limit': 100,
      };

      print('Variables: $variables');

      // Send GraphQL request
      final response = await _sendGraphQLRequest(
        query: query,
        variables: variables,
      );

      print('========== GraphQL RESPONSE ==========');
      print('✅ Response received successfully');

      // Check for GraphQL errors
      if (response.containsKey('errors')) {
        print('❌ GraphQL Errors: ${response['errors']}');
        throw Exception('GraphQL Error: ${response['errors']}');
      }

      final data = response['data'];
      if (data == null) {
        print('⚠️ No data in response');
        throw Exception('No data returned from API');
      }

      // Parse response
      if (data.containsKey('stocksV2')) {
        final stocksV2 = data['stocksV2'];

        if (stocksV2 is Map && stocksV2.containsKey('data')) {
          final productsData = stocksV2['data'] as List<dynamic>;
          final total = stocksV2['total'];

          print('✅ Total products from API: $total');
          print('✅ Products array length: ${productsData.length}');

          if (productsData.isEmpty) {
            print('⚠️ Empty products list from API');
            return [];
          }

          final products =
              productsData.map((json) => Product.fromJson(json)).toList();
          print('✅ Successfully created ${products.length} Product objects');
          return products;
        }
      }

      print('⚠️ Unexpected response structure');
      throw Exception('Invalid API response structure');
    } on TimeoutException {
      print('========== REQUEST TIMEOUT ==========');
      print('Connection timeout after 30 seconds');
      throw Exception(
          'Connection timeout - please check your internet connection');
    } catch (e) {
      print('❌ Error fetching products: $e');
      rethrow;
    }
  }

  // Payment Gateway API - PhaJay BCEL QR Payment
  static Future<Map<String, dynamic>> createQRPayment({
    required double amount,
    required String description,
    required String secretKey,
  }) async {
    try {
      print('========== PHAJAY QR PAYMENT REQUEST ==========');
      print('Amount: $amount LAK');
      print('Description: $description');

      // Build request body - BCEL does not support Lao/Thai characters in description
      final requestBody = {
        'amount': amount,
        'description': description, 
        'tag2': "Jop Jip",
        'tag1': "6864d7d2f32c2508f58eb7e8",
      };
      
      print('Request body: $requestBody');
      
      final response = await http.post(
        Uri.parse('https://payment-gateway.phajay.co/v1/api/payment/generate-jdb-qr'),
        headers: {
          'secretKey': secretKey, // Use testKey if not KYC
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Payment gateway timeout after 30 seconds');
        },
      );

      print('========== QR PAYMENT RESPONSE ==========');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        
        // Check for successful response
        if (data['message'] == 'SUCCESSFULLY' && data['qrCode'] != null) {
          print('✅ QR Payment created successfully');
          print('Transaction ID: ${data['transactionId']}');
          print('QR Code: ${data['qrCode']}');
          print('Link: ${data['link']}');
          return data;
        } else {
          print('⚠️ Unexpected response format: $data');
          throw Exception('Invalid payment gateway response');
        }
      } else {
        print('❌ Payment gateway error: ${response.statusCode}');
        throw Exception('Payment gateway error: ${response.body}');
      }
    } on TimeoutException {
      print('========== PAYMENT REQUEST TIMEOUT ==========');
      throw Exception('Payment gateway timeout - please try again');
    } catch (e) {
      print('❌ Error creating QR payment: $e');
      rethrow;
    }
  }
}
