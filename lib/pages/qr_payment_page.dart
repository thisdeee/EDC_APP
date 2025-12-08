import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../state/cart_state.dart';
import 'payment_success_page.dart';

class QRPaymentPage extends StatefulWidget {
  final String qrCode;
  final String transactionId;
  final String? link;
  final double amount;
  final String secretKey;
  final String customerName;
  final String customerPhone;
  
  const QRPaymentPage({
    super.key,
    required this.qrCode,
    required this.transactionId,
    required this.amount,
    required this.secretKey,
    required this.customerName,
    required this.customerPhone,
    this.link,
  });
  
  @override
  State<QRPaymentPage> createState() => _QRPaymentPageState();
}

class _QRPaymentPageState extends State<QRPaymentPage> {
  bool _paymentCompleted = false;
  IO.Socket? _socket;
  String _paymentStatus = 'Waiting for payment...';
  Map<String, dynamic>? _paymentData;

  @override
  void initState() {
    super.initState();
    _connectToPaymentSocket();
  }

  void _connectToPaymentSocket() {
    print('=== CONNECTING TO PHAJAY SOCKET ===');
    print('Secret Key: ${widget.secretKey}');
    print('Transaction ID: ${widget.transactionId}');
    
    try {
      // According to PhaJay documentation
      const String socketUrl = 'https://payment-gateway.phajay.co/';
      
      print('🔌 Socket URL: $socketUrl');
      
      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .build(),
      );

      _socket!.onConnect((_) {
        print('✅ Connected to PhaJay payment socket');
        print('📡 Socket ID: ${_socket!.id}');
        print('📡 Connected: ${_socket!.connected}');
        setState(() {
          _paymentStatus = 'Connected. Scan QR code to pay...';
        });
      });

      // Listen to the correct event format: "join::{SECRET_KEY}"
      final eventName = 'join::${widget.secretKey}';
      print('📡 Subscribing to event: $eventName');
      
      _socket!.on(eventName, (data) {
        print('📥 ========== PAYMENT CALLBACK RECEIVED ==========');
        print('📥 Event: $eventName');
        print('📥 Data: $data');
        if (data != null) {
          setState(() {
            _paymentData = data;
          });
          _handlePaymentCallback(data);
        }
      });

      // Listen to all events for debugging
      _socket!.onAny((event, data) {
        print('📡 Socket event received: $event');
        print('📡 Event data: $data');
      });

      _socket!.onConnectError((error) {
        print('❌ Socket connection error: $error');
        setState(() {
          _paymentStatus = 'Connection error. Please try again.';
        });
      });

      _socket!.onDisconnect((_) {
        print('🔌 Disconnected from payment socket');
      });
    } catch (e) {
      print('❌ Error setting up socket: $e');
    }
  }

  void _handlePaymentCallback(dynamic data) {
    print('=== PROCESSING PAYMENT CALLBACK ===');
    print('Data: $data');
    
    if (_paymentCompleted) {
      print('⚠️ Payment already processed');
      return;
    }
    
    try {
      // Payment callback received means payment is successful
      print('✅ Payment completed successfully!');
      setState(() {
        _paymentData = data;
      });
      _confirmPayment();
    } catch (e) {
      print('❌ Error processing callback: $e');
    }
  }

  @override
  void dispose() {
    _socket?.dispose();
    super.dispose();
  }

  void _copyQRCode() {
    Clipboard.setData(ClipboardData(text: widget.qrCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR Code copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _confirmPayment() {
    if (_paymentCompleted) return;
    
    setState(() => _paymentCompleted = true);
    
    // Save cart items before clearing
    final cartItems = CartState.cart.values.toList();
    
    // Clear cart
    CartState.clear();
    
    // Disconnect socket
    _socket?.dispose();
    
    // Navigate to success page (shows for 2 seconds then goes to receipt)
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentSuccessPage(
            transactionId: widget.transactionId,
            amount: widget.amount,
            paymentData: _paymentData ?? {},
            customerName: widget.customerName,
            cartItems: cartItems,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        title: const Text('BCEL QR Payment'),
        leading: _paymentCompleted
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Cancel Payment?'),
                      content: const Text('Are you sure you want to cancel this payment?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('No'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: const Text('Yes'),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      body: _paymentCompleted
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 80),
                  SizedBox(height: 16),
                  Text(
                    'Payment Confirmed!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Returning to home...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Transaction Info Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.receipt_long, color: Colors.purple),
                              const SizedBox(width: 8),
                              const Text(
                                'Transaction Details',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _buildInfoRow('Transaction ID', widget.transactionId),
                          const SizedBox(height: 8),
                          _buildInfoRow('Amount', '${widget.amount.toStringAsFixed(0)} LAK'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // QR Code Display
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Text(
                            'Scan QR Code to Pay',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // QR Code Container
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: QrImageView(
                              data: widget.qrCode,
                              version: QrVersions.auto,
                              size: 250.0,
                              backgroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Copy QR Code Button
                          OutlinedButton.icon(
                            onPressed: _copyQRCode,
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy QR Code'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Instructions
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Payment Instructions',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInstruction('1. Open your JDB app'),
                          _buildInstruction('2. Scan the QR code above'),
                          _buildInstruction('3. Confirm the payment amount'),
                          _buildInstruction('4. Complete the transaction'),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _paymentStatus,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Debug: Test Payment Button (uncomment to show test button)
                  // if (kDebugMode)
                  //   ElevatedButton.icon(
                  //     onPressed: () {
                  //       print('🧪 Testing payment callback manually');
                  //       final testData = {
                  //         'billNumber': widget.transactionId,
                  //         'transactionId': widget.transactionId,
                  //         'txnAmount': widget.amount,
                  //         'merchantName': 'Jop Jip',
                  //         'paymentMethod': 'JDB',
                  //         'status': 'PAYMENT_COMPLETED',
                  //         'txnDateTime': '${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}',
                  //         'sourceName': 'Test Payment',
                  //         'sourceAccount': '1234567890',
                  //         'refNo': 123456789,
                  //       };
                  //       _handlePaymentCallback(testData);
                  //     },
                  //     icon: const Icon(Icons.check_circle),
                  //     label: const Text('Simulate Payment Success'),
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: Colors.orange,
                  //       foregroundColor: Colors.white,
                  //       padding: const EdgeInsets.symmetric(vertical: 16),
                  //     ),
                  //   ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
