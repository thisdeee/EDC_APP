import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

class ApiService {
  // GraphQL JWT Token - REPLACE THIS WITH YOUR ACTUAL JWT TOKEN FROM YOUR BACKEND
  // JWT tokens typically start with "eyJ" and are much longer than this placeholder
  // Example: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  // This is NOT the PhaJay secret key - that's used separately for QR payments
  // static const String GRAPHQL_JWT_TOKEN = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY4NjRkN2Y2Nzk4MzE2NjhmZjEzMzg5OSIsInVzZXJuYW1lIjoidGluYTEyMTIiLCJyb2xlIjoiTEFJTEFPTEFCX1NUQUZGIiwiaWF0IjoxNzY2MDUyNzY4LCJleHAiOjE3NjYyMjU1Njh9.qR7VDJqkix5gLpbmcNUY4zJIOSh_OONnw-rAcb7KQPk';
  static const String GRAPHQL_JWT_TOKEN =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY4NjRkN2Y2Nzk4MzE2NjhmZjEzMzg5OSIsInVzZXJuYW1lIjoidGluYTEyMTIiLCJyb2xlIjoiTEFJTEFPTEFCX1NUQUZGIiwiaWF0IjoxNzY2MzcwNTAzLCJleHAiOjE3NjY1NDMzMDN9.NY3ZshTD90XLLyTEMlJi2P8m8CLJb3AYoHvVGRqTXHM';

  // PhaJay Payment Support Secret for Socket Callbacks
  // Get this from https://portal.phajay.co/?key=<PAYMENT_Support_SECRET>
  // May be different from the QR secret key
  static const String PAYMENT_SUPPORT_SECRET = r'$2b$10$sRx/uTHMydWDIdizURcgxecjFPbvnUNFzOwTl3lxNyV35zoFY4HnO';
  //   required double amount,
  //   required String description,
  //   required List<Map<String, dynamic>> orders,
  //   required Map<String, dynamic> orderGroup,
  // }) async {
  //   const String mutation = '''
  //     mutation CreatePaymentLinkWithPhapay(
  //       \$data: PaymentInput!
  //     ) {
  //       createPaymentLinkWithPhapay(data: \$data) {
  //         data {
  //           id
  //           transactionId
  //           status
  //           amount
  //           sumPrice
  //           sumPriceBaht
  //           sumPriceUsd
  //           totalPrice
  //           orders {
  //             shop {
  //               id
  //               name
  //             }
  //           }
  //         }
  //         qrCode
  //       }
  //     }
  //   ''';

  //   final variables = {
  //     'data': {
  //       'amount': amount,
  //       'description': description,
  //       'orders': orders,
  //       'orderGroup': orderGroup,
  //     }
  //   };

  //   print('📤 Sending createPaymentLinkWithPhapay mutation...');
  //   print('Variables: ' + variables.toString());

  //   final response = await _sendGraphQLRequest(
  //     query: mutation,
  //     variables: variables,
  //   );

  //   print('📥 GraphQL response: ' + response.toString());

  //   if (response.containsKey('errors')) {
  //     throw Exception('GraphQL Error: \\n' + response['errors'].toString());
  //   }

  //   return response['data']['createPaymentLinkWithPhapay'];
  // }

  // Login User
  static Future<Map<String, dynamic>?> loginUser({
    required String username,
    required String password,
  }) async {
    const String mutation = '''
      mutation LoginUser(\$where: LoginUserInput!) {
        loginUser(where: \$where) {
          accessToken
          data {
            id
            username
            role
            shop {
              id
              name
              phone
            }
          }
        }
      }
    ''';

    final variables = {
      'where': {
        'username': username,
        'password': password,
      }
    };

    print('📤 Sending login mutation...');
    print('Variables: $variables');

    final response = await _sendGraphQLRequest(
      query: mutation,
      variables: variables,
    );

    print('📥 GraphQL response: $response');

    if (response.containsKey('errors')) {
      throw Exception('GraphQL Error: \n' + response['errors'].toString());
    }

    final loginData = response['data']['loginUser'];
    if (loginData != null) {
      return loginData;
    }

    return null;
  }

  // Create Order Group
  static Future<Map<String, dynamic>> createOrderGroup({
    required String shop,
    required String type,
    required int amount,
    required int sumPrice,
    required int sumPriceBaht,
    required int sumPriceUsd,
    required int totalPrice,
    required String customerName,
    required String phone,
    String? logistic,
    String? destinationLogistic,
    String? affiliateName,
    required String orders, // Product ID as string
  }) async {
    const String mutation = '''
      mutation CreateOrderGroup(\$data: OrderGroupInput!) {
        createOrderGroup(data: \$data) {
          id
          transactionId
          status
          amount
          sumPrice
          sumPriceBaht
          sumPriceUsd
          totalPrice
          createdAt
          orders {
            shop {
              id
              name
            }
          }
        }
      }
    ''';

    final variables = {
      'data': {
        'shop': shop,
        'type': type,
        'amount': amount,
        'sumPrice': sumPrice,
        'sumPriceBaht': sumPriceBaht,
        'sumPriceUsd': sumPriceUsd,
        'totalPrice': totalPrice,
        'customerName': customerName,
        'phone': phone,
        'logistic': logistic ?? '',
        'destinationLogistic': destinationLogistic ?? '',
        'affiliateName': affiliateName ?? '',
        'orders': orders,
      }
    };

    print('📤 Sending createOrderGroup mutation...');
    print('Variables: ' + variables.toString());
    print('Using JWT token: ${GRAPHQL_JWT_TOKEN.substring(0, 20)}...');

    final response = await _sendGraphQLRequest(
      query: mutation,
      variables: variables,
    );

    print('📥 GraphQL response: ' + response.toString());

    if (response.containsKey('errors')) {
      throw Exception('GraphQL Error: \\n' + response['errors'].toString());
    }

    return response['data']['createOrderGroup'];
  }

  // PhaJay Credit Card Payment
  static Future<Map<String, dynamic>> createCreditCardPayment({
    required double amount,
    required String description,
    required String secretKey,
    String? tag1,
    String? tag2,
    String? tag3,
  }) async {
    const endpoint =
        'https://payment-gateway.phajay.co/v1/api/jdb2c2p/payment/payment-link';
    final requestBody = {
      'amount': amount,
      'description': description,
      if (tag1 != null) 'tag1': tag1,
      if (tag2 != null) 'tag2': tag2,
      if (tag3 != null) 'tag3': tag3,
    };
    final auth = base64Encode(utf8.encode(secretKey));
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Basic $auth',
    };
    try {
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: headers,
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['paymentUrl'] != null) {
          return data;
        } else {
          throw Exception('No paymentUrl in response: $data');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  static const String baseUrl = 'https://api.bbbb.com.la';

  // Send GraphQL request using http package
  static Future<Map<String, dynamic>> _sendGraphQLRequest({
    required String query,
    required Map<String, dynamic> variables,
  }) async {
    // Get access token from SharedPreferences, fallback to static token
    String authToken = GRAPHQL_JWT_TOKEN;
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      if (accessToken != null && accessToken.isNotEmpty) {
        authToken = accessToken;
      }
    } catch (e) {
      // If SharedPreferences fails, use static token
      print('⚠️ Could not load access token from SharedPreferences, using static token');
    }

    final response = await http
        .post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': '$authToken',
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

  // Payment Gateway API - PhaJay Multi-Bank QR Payment
  static Future<Map<String, dynamic>> createQRPayment({
    required double amount,
    required String description,
    required String secretKey,
    String bankCode = 'jdb', // Default to JDB
  }) async {
    try {
      print('========== PHAJAY QR PAYMENT REQUEST ==========');
      print('Bank: ${bankCode.toUpperCase()}');
      print('Amount: $amount LAK');
      print('Description: $description');

      // Determine API endpoint based on bank code
      String endpoint;
      switch (bankCode.toLowerCase()) {
        case 'ldb':
          endpoint =
              'https://payment-gateway.phajay.co/v1/api/payment/generate-ldb-qr';
          break;
        case 'bcel':
          endpoint =
              'https://payment-gateway.phajay.co/v1/api/payment/generate-bcel-qr';
          break;
        case 'ib':
          endpoint =
              'https://payment-gateway.phajay.co/v1/api/payment/generate-ib-qr';
          break;
        case 'jdb':
        default:
          endpoint =
              'https://payment-gateway.phajay.co/v1/api/payment/generate-jdb-qr';
          break;
      }

      // Build request body
      final requestBody = {
        'amount': amount.toInt(),
        'description': description,
        'tag2': "Jop Jip",
        'tag1': "6864d7d2f32c2508f58eb7e8",
      };

      print('Endpoint: $endpoint');
      print('Request body: $requestBody');

      final response = await http
          .post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'secretKey': secretKey,
        },
        body: json.encode(requestBody),
      )
          .timeout(
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

  // Create Order and Update Stock after successful payment
  static Future<void> createOrderAndUpdateStock({
    required String transactionId,
    required List<CartItem> cartItems,
    required String customerName,
    required String customerPhone,
    String? customerAddress,
    required String shopId,
    required String shopName,
  }) async {
    try {
      print('========== CREATING ORDER AND UPDATING STOCK ==========');
      print('Transaction ID: $transactionId');
      print('Shop: $shopName ($shopId)');
      print('Customer: $customerName - $customerPhone');
      print('Items: ${cartItems.length}');

      // First, update stock for each item
      for (final item in cartItems) {
        await updateStock(item.product.id, item.qty);
      }

      // Then create order record
      await _createOrderRecord(
        transactionId: transactionId,
        cartItems: cartItems,
        customerName: customerName,
        customerPhone: customerPhone,
        customerAddress: customerAddress ?? customerName,
        shopId: shopId,
        shopName: shopName,
      );

      print('✅ Order created and stock updated successfully');
    } catch (e) {
      print('❌ Error creating order or updating stock: $e');
      rethrow;
    }
  }

  // Update stock for a product
  // แก้ไขฟังก์ชัน updateStock ใน ApiService class

// Update stock for a product
  // แก้ไขฟังก์ชันตัดสต็อกใน api_service.dart

// ===== ฟังก์ชัน updateStock ที่สมบูรณ์ =====
static Future<void> updateStock(String productId, int quantitySold) async {
  try {
    print('🔄 Starting stock update for product: $productId, quantity sold: $quantitySold');

    // Get current stock values
    final stockData = await _getStockData(productId);
    
    if (stockData == null) {
      print('⚠️ Could not retrieve current stock for product $productId. Skipping stock update.');
      return;
    }

    final currentAmount = stockData['amount'] ?? 0;
    final currentAmountSale = stockData['amountSale'] ?? 0;
    final currentAmountAll = stockData['amountAll'] ?? 0;

    // Calculate new values
    final newAmount = currentAmount - quantitySold;
    final newAmountSale = currentAmountSale + quantitySold;

    print('📊 Stock calculation:');
    print('  amountAll (total imported): $currentAmountAll (unchanged)');
    print('  amount (remaining): $currentAmount → ${newAmount < 0 ? 0 : newAmount}');
    print('  amountSale (sold): $currentAmountSale → $newAmountSale');

    // ตรวจสอบว่าสมดุล
    if (newAmount < 0) {
      print('⚠️ Warning: Stock going negative! Setting to 0');
    }

    const String updateMutation = '''
      mutation UpdateStock(\$data: StockInput!, \$where: StockWhereInputOne!) {
        updateStock(data: \$data, where: \$where) {
          id
          name
          amount
          amountAll
          amountSale
          updatedAt
        }
      }
    ''';

    final updateVariables = {
      'where': {
        'id': productId,
      },
      'data': {
        'amountAll': currentAmountAll,
        'amount': newAmount < 0 ? 0 : newAmount,
        'amountSale': newAmountSale,
      }
    };

    print('📤 Sending stock update mutation...');
    print('Variables: $updateVariables');

    final updateResponse = await _sendGraphQLRequest(
      query: updateMutation,
      variables: updateVariables,
    );

    if (updateResponse.containsKey('errors')) {
      print('❌ GraphQL Error: ${updateResponse['errors']}');
      throw Exception('GraphQL Error: ${updateResponse['errors']}');
    }

    print('✅ Stock updated successfully!');
    final result = updateResponse['data']['updateStock'];
    print('📥 Updated stock details:');
    print('  Product: ${result['name']} (${result['id']})');
    print('  Amount: ${result['amount']}');
    print('  Amount Sale: ${result['amountSale']}');
    print('  Amount All: ${result['amountAll']}');
    print('  Updated At: ${result['updatedAt']}');
    
    // ตรวจสอบความถูกต้อง
    final finalAmount = result['amount'] as int;
    final finalAmountSale = result['amountSale'] as int;
    final finalAmountAll = result['amountAll'] as int;
    
    if (finalAmount + finalAmountSale == finalAmountAll) {
      print('✅ Stock balance verified: $finalAmount + $finalAmountSale = $finalAmountAll');
    } else {
      print('⚠️ Stock imbalance detected: $finalAmount + $finalAmountSale ≠ $finalAmountAll');
    }
  } catch (e) {
    print('❌ Error updating stock for product $productId: $e');
    print('⚠️ Continuing with order creation despite stock update failure');
  }
}

// แก้ไข _getStockData ให้ใช้ where parameter

// ===== แก้ไขให้ใช้ "where" parameter =====
static Future<Map<String, dynamic>?> _getStockData(String productId) async {
  // ใช้ where: StockWhereInputOne! แทน id: ID!
  const String query = '''
    query Stock(\$where: StockWhereInputOne!) {
      stock(where: \$where) {
        id
        amount
        amountSale
        amountAll
      }
    }
  ''';

  final variables = {
    'where': {
      'id': productId,
    }
  };

  print('🔍 Getting stock data for product: $productId');
  print('Query variables: $variables');

  try {
    final response = await _sendGraphQLRequest(
      query: query,
      variables: variables,
    );

    print('📊 Stock query response: $response');

    if (response.containsKey('errors')) {
      print('❌ Stock query failed: ${response['errors']}');
      return null;
    }

    final data = response['data'];
    if (data != null && data['stock'] != null) {
      final stockData = data['stock'];
      print('✅ Current stock found:');
      print('  Amount: ${stockData['amount']}');
      print('  Amount Sale: ${stockData['amountSale']}');
      print('  Amount All: ${stockData['amountAll']}');
      
      return {
        'amount': stockData['amount'] as int? ?? 0,
        'amountSale': stockData['amountSale'] as int? ?? 0,
        'amountAll': stockData['amountAll'] as int? ?? 0,
      };
    }

    print('⚠️ No stock data found in response');
    return null;
  } catch (e) {
    print('❌ Error getting stock data: $e');
    return null;
  }
}

// ===== ตัวอย่างการทดสอบ =====
/*
ตัวอย่างการใช้งาน:

1. ลูกค้าซื้อสินค้า 1 ชิ้น:
   - Current: amount=100, amountSale=0, amountAll=100
   - After: amount=99, amountSale=1, amountAll=100

2. ลูกค้าซื้อสินค้า 5 ชิ้น:
   - Current: amount=99, amountSale=1, amountAll=100
   - After: amount=94, amountSale=6, amountAll=100

3. สินค้าหมด (ซื้อ 94 ชิ้น):
   - Current: amount=94, amountSale=6, amountAll=100
   - After: amount=0, amountSale=100, amountAll=100

สูตร:
- amount = จำนวนคงเหลือ = amount_เดิม - ขายไป
- amountSale = ยอดขายสะสม = amountSale_เดิม + ขายไป  
- amountAll = จำนวนนำเข้าทั้งหมด (ไม่เปลี่ยน)

การตรวจสอบ:
amount + amountSale = amountAll (เสมอ)
*/

  static Future<int?> getCurrentAmountSale(String productId) async {
    // Use StocksV2 query
    const String fallbackQuery = '''
      query StocksV2(\$where: StockWhereInput, \$skip: Int, \$limit: Int) {
        stocksV2(where: \$where, skip: \$skip, limit: \$limit) {
          total
          data {
            id
            amountSale
          }
        }
      }
    ''';

    final fallbackVariables = {
      'where': {
        'id': productId,
        'shop': '6864d7d2f32c2508f58eb7e8',
      },
      'skip': 0,
      'limit': 1,
    };

    print(
        '🔍 Getting current amountSale for product: $productId (using StocksV2 query)');

    try {
      final fallbackResponse = await _sendGraphQLRequest(
        query: fallbackQuery,
        variables: fallbackVariables,
      );

      print('📊 StocksV2 query response: $fallbackResponse');

      if (fallbackResponse.containsKey('errors')) {
        print('❌ StocksV2 query failed: ${fallbackResponse['errors']}');
        return 0;
      }

      final data = fallbackResponse['data'];
      if (data != null && data['stocksV2'] != null) {
        final stocksV2 = data['stocksV2'];
        if (stocksV2['data'] != null && stocksV2['data'].isNotEmpty) {
          final amountSale = stocksV2['data'][0]['amountSale'] as int? ?? 0;
          print('✅ Found amountSale: $amountSale for product: $productId');
          return amountSale;
        }
      }

      print('⚠️ No amountSale data found in StocksV2 query');
      return 0;
    } catch (e) {
      print('❌ Error getting current amountSale for product $productId: $e');
      return 0;
    }
  }

  // Get current amountAll for a product
  static Future<int?> getCurrentAmountAll(String productId) async {
    const String query = '''
      query StocksV2(\$where: StockWhereInput, \$skip: Int, \$limit: Int) {
        stocksV2(where: \$where, skip: \$skip, limit: \$limit) {
          total
          data {
            id
            amountAll
          }
        }
      }
    ''';
    try {
      final response = await _sendGraphQLRequest(
        query: query,
        variables: {
          'where': {
            'id': productId,
            'shop': '6864d7d2f32c2508f58eb7e8',
          },
          'skip': 0,
          'limit': 1,
        },
      );
      if (response.containsKey('errors')) {
        print('GraphQL Error: ' + response['errors'].toString());
        return null;
      }
      final data = response['data'];
      if (data != null && data['stocksV2'] != null) {
        final stocksV2 = data['stocksV2'];
        if (stocksV2['data'] != null && stocksV2['data'].isNotEmpty) {
          final amountAll = stocksV2['data'][0]['amountAll'] as int?;
          return amountAll;
        }
      }
      return null;
    } catch (e) {
      print('❌ Error getting amountAll for product $productId: $e');
      return null;
    }
  }

  // Create order record
  static Future<void> _createOrderRecord({
    required String transactionId,
    required List<CartItem> cartItems,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    required String shopId,
    required String shopName,
  }) async {
    // Get schema information for debugging
    await getGraphQLSchema();

    const String mutation = '''
      mutation CreateOrderSalePage(\$data: SalePageInputData!) {
        createOrderSalePage(data: \$data) {
          id
          amount
          address
          totalPrice
          sumPriceBaht
          sumPriceUsd
          sumPrice
          status
          createdAt
          orders {
            id
            amount
            code
            note
            isDeleted
            stock {
              id
              name
              price
              image
              unit
              currency
            }
          }
        }
      }
    ''';

    final variables = {
      'data': {
        'orderGroup': {
          'shop': shopId,
          'transactionId': transactionId,
          'amount': cartItems.fold(0, (sum, item) => sum + item.qty),
          'address': customerAddress,
          'totalPrice':
              cartItems.fold(0.0, (sum, item) => sum + item.lineTotal),
          'sumPriceBaht': 0.0,
          'sumPriceUsd': 0.0,
          'sumPrice': cartItems.fold(0.0, (sum, item) => sum + item.lineTotal),
          'customerName': customerName,
          'status': 'COMPLETED',
          'code': 'SP-${DateTime.now().millisecondsSinceEpoch}',
          'createdAt': DateTime.now().toIso8601String(),
        },
        'orders': cartItems
            .map((item) => {
                  'stock': item.product.id,
                  'amount': item.qty,
                  'note': item.product.name,
                })
            .toList(),
      }
    };

    try {
      print('📤 Sending GraphQL request for order creation...');
      print('Variables: $variables');

      final response = await _sendGraphQLRequest(
        query: mutation,
        variables: variables,
      );

      print('📥 GraphQL response: $response');

      if (response.containsKey('errors')) {
        throw Exception('GraphQL Error: ${response['errors']}');
      }

      print('✅ Order created with transaction ID: $transactionId');
    } catch (e) {
      print('❌ Error creating order: $e');
      rethrow;
    }
  }

  // Get GraphQL schema information
  static Future<Map<String, dynamic>?> getGraphQLSchema() async {
    const String query = '''
      query IntrospectionQuery {
        __schema {
          mutationType {
            name
            fields {
              name
              description
              args {
                name
                description
                type {
                  name
                  kind
                  ofType {
                    name
                    kind
                  }
                }
              }
              type {
                name
                kind
              }
            }
          }
          types {
            name
            kind
            description
            fields {
              name
              description
              type {
                name
                kind
                ofType {
                  name
                  kind
                }
              }
            }
            inputFields {
              name
              description
              type {
                name
                kind
                ofType {
                  name
                  kind
                }
              }
            }
            enumValues {
              name
              description
            }
          }
        }
      }
    ''';

    try {
      final response = await _sendGraphQLRequest(
        query: query,
        variables: {},
      );

      if (response.containsKey('errors')) {
        print('❌ Schema query errors: ${response['errors']}');
        return null;
      }

      print('✅ GraphQL Schema retrieved successfully');
      final data = response['data'];
      if (data != null) {
        // Print mutations
        final mutationType = data['__schema']?['mutationType'];
        if (mutationType != null) {
          print('🔄 Available Mutations:');
          final fields = mutationType['fields'] ?? [];
          for (var field in fields) {
            print(
                '  - ${field['name']}: ${field['description'] ?? 'No description'}');
            final args = field['args'] ?? [];
            if (args.isNotEmpty) {
              print('    Args:');
              for (var arg in args) {
                print(
                    '      ${arg['name']}: ${arg['type']?['name'] ?? arg['type']?['ofType']?['name'] ?? 'Unknown'}');
              }
            }
          }
        }

        // Print types related to orders and stock
        final types = data['__schema']?['types'] ?? [];
        print('📋 Types related to orders and stock:');
        for (var type in types) {
          final name = type['name'];
          if (name != null &&
              (name.contains('Order') ||
                  name.contains('Stock') ||
                  name.contains('Sale'))) {
            print('  - $name (${type['kind']})');
            if (type['description'] != null) {
              print('    Description: ${type['description']}');
            }

            // Print fields for object types
            if (type['kind'] == 'OBJECT') {
              final fields = type['fields'] ?? [];
              if (fields.isNotEmpty) {
                print('    Fields:');
                for (var field in fields) {
                  print(
                      '      ${field['name']}: ${field['type']?['name'] ?? field['type']?['ofType']?['name'] ?? 'Unknown'}');
                }
              }
            }

            // Print input fields for input types
            if (type['kind'] == 'INPUT_OBJECT') {
              final inputFields = type['inputFields'] ?? [];
              if (inputFields.isNotEmpty) {
                print('    Input Fields:');
                for (var field in inputFields) {
                  print(
                      '      ${field['name']}: ${field['type']?['name'] ?? field['type']?['ofType']?['name'] ?? 'Unknown'}');
                }
              }
            }

            // Print enum values for enums
            if (type['kind'] == 'ENUM') {
              final enumValues = type['enumValues'] ?? [];
              if (enumValues.isNotEmpty) {
                print('    Enum Values:');
                for (var value in enumValues) {
                  print(
                      '      ${value['name']}: ${value['description'] ?? 'No description'}');
                }
              }
            }
          }

          // Special focus on SalePageInputData
          if (name == 'SalePageInputData') {
            print('🎯 SalePageInputData Details:');
            print('  Kind: ${type['kind']}');
            if (type['inputFields'] != null) {
              print('  Input Fields:');
              for (var field in type['inputFields']) {
                print(
                    '    ${field['name']}: ${field['type']?['name'] ?? field['type']?['ofType']?['name'] ?? 'Unknown'}');
                if (field['description'] != null) {
                  print('      Description: ${field['description']}');
                }
              }
            }
          }

          // Special focus on OrderGroupInput
          if (name == 'OrderGroupInput') {
            print('🎯 OrderGroupInput Details:');
            print('  Kind: ${type['kind']}');
            if (type['inputFields'] != null) {
              print('  Input Fields:');
              for (var field in type['inputFields']) {
                print(
                    '    ${field['name']}: ${field['type']?['name'] ?? field['type']?['ofType']?['name'] ?? 'Unknown'}');
                if (field['description'] != null) {
                  print('      Description: ${field['description']}');
                }
              }
            }
          }

          // Special focus on OrderInput
          if (name == 'OrderInput') {
            print('🎯 OrderInput Details:');
            print('  Kind: ${type['kind']}');
            if (type['inputFields'] != null) {
              print('  Input Fields:');
              for (var field in type['inputFields']) {
                print(
                    '    ${field['name']}: ${field['type']?['name'] ?? field['type']?['ofType']?['name'] ?? 'Unknown'}');
                if (field['description'] != null) {
                  print('      Description: ${field['description']}');
                }
              }
            }
          }

          // Special focus on OrderStatus
          if (name == 'OrderStatus') {
            print('🎯 OrderStatus Details:');
            print('  Kind: ${type['kind']}');
            if (type['enumValues'] != null) {
              print('  Enum Values:');
              for (var value in type['enumValues']) {
                print(
                    '    ${value['name']}: ${value['description'] ?? 'No description'}');
              }
            }
          }
        }
      }

      return data;
    } catch (e) {
      print('❌ Error getting GraphQL schema: $e');
      return null;
    }
  }

  // Update Order Status
  static Future<Map<String, dynamic>?> updateOrderStatus({
    required String orderId,
    required String status,
    String? payment,
    String? paymentMethod,
    String? paymentType,
    bool? isPaymented,
  }) async {
    // Get schema information for debugging
    await getGraphQLSchema();

    const String mutation = '''
      mutation UpdateOrderGroup(\$data: OrderGroupInput!, \$where: OrderGroupWhereInputOne!) {
        updateOrderGroup(data: \$data, where: \$where) {
          id
          status
          payment
          paymentMethod
          paymentType
          updatedAt
          isPaymented
        }
      }
    ''';

    final Map<String, dynamic> data = {'status': status};

    // Add payment fields if provided
    if (payment != null) data['payment'] = payment;
    if (paymentMethod != null) data['paymentMethod'] = paymentMethod;
    if (paymentType != null) data['paymentType'] = paymentType;
    if (isPaymented != null) data['isPaymented'] = isPaymented;

    final variables = {
      'where': {'id': orderId},
      'data': data,
    };

    print('📤 Sending updateOrderGroup mutation for status update...');
    print('Variables: $variables');

    final response = await _sendGraphQLRequest(
      query: mutation,
      variables: variables,
    );

    print('📥 GraphQL response: $response');

    if (response.containsKey('errors')) {
      throw Exception('GraphQL Error: \n' + response['errors'].toString());
    }

    return response['data']['updateOrderGroup'];
  }
}
