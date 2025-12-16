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
  final String bankName;
  
  const QRPaymentPage({
    super.key,
    required this.qrCode,
    required this.transactionId,
    required this.amount,
    required this.secretKey,
    required this.customerName,
    required this.customerPhone,
    this.link,
    this.bankName = 'JDB',
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
        title: Text('${widget.bankName} Payment'),
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
          ? Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green.shade600,
                        size: 80,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Payment Successful!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Processing your order...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey.shade50,
                    Colors.white,
                  ],
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Amount Card - Compact with Logos
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade200.withOpacity(0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Row 1: Logos with text below
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Image.network(
                                      'https://image2url.com/images/1765170299091-f08fcf1b-f4a4-4be1-ba43-b38df770e8dc.png',
                                      width: 70,
                                      height: 40,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Text(
                                          'JDB',
                                          style: TextStyle(
                                            color: Color(0xFF1E88E5),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Image.network(
                                      'https://image2url.com/images/1765170407629-426827dc-9051-4e21-993e-07892c94829c.png',
                                      width: 80,
                                      height: 50,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Text(
                                          'PHAJAY',
                                          style: TextStyle(
                                            color: Color(0xFF1E88E5),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              
                            ],
                          ),
                          
                          // Divider Line
                          const SizedBox(height: 8),
                          Container(
                            height: 1,
                            color: Colors.white30,
                          ),
                          const SizedBox(height: 8),
                          
                          // Row 2: Amount to Pay
                          Column(
                            children: [
                              const Text(
                                'Amount to Pay',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${widget.amount.toStringAsFixed(0)} ₭',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Text(
                                '#${widget.transactionId.substring(0, 8).toUpperCase()}',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // QR Code Card - Compact Design
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300,
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Scan to Pay',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Use PhaJay or JDB Digital',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // QR Code with clean border
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 2,
                              ),
                            ),
                            child: QrImageView(
                              data: widget.qrCode,
                              version: QrVersions.auto,
                              size: 220.0,
                              backgroundColor: Colors.white,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Colors.black,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Copy QR Button
                          OutlinedButton.icon(
                            onPressed: _copyQRCode,
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('Copy QR Code'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1E88E5),
                              side: const BorderSide(color: Color(0xFF1E88E5)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 28),
                    
                    // Status Indicator
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.shade100,
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _paymentStatus,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.blue.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Payment will be confirmed automatically',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Instructions
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.grey.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'How to Pay',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInstructionStep('1', 'Open your banking app'),
                          _buildInstructionStep('2', 'Select QR Payment'),
                          _buildInstructionStep('3', 'Scan the code above'),
                          _buildInstructionStep('4', 'Confirm the amount'),
                        ],
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

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF1E88E5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
