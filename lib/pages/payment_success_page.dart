import 'package:flutter/material.dart';
import 'dart:convert';
import '../state/cart_state.dart';
import '../models/product.dart';

class PaymentSuccessPage extends StatefulWidget {
  final String transactionId;
  final double amount;
  final Map<String, dynamic> paymentData;
  final String customerName;
  final List<CartItem> cartItems;

  const PaymentSuccessPage({
    super.key,
    required this.transactionId,
    required this.amount,
    required this.paymentData,
    required this.customerName,
    required this.cartItems,
  });

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();

    // Navigate to receipt after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PaymentReceiptPage(
              transactionId: widget.transactionId,
              amount: widget.amount,
              paymentData: widget.paymentData,
              customerName: widget.customerName,
              cartItems: widget.cartItems,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade600,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 80,
                  color: Colors.green.shade600,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'ຊຳລະສຳເລັດ',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${widget.amount.toStringAsFixed(2)} LAK',
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'ກຳລັງສ້າງໃບເສັດ...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentReceiptPage extends StatelessWidget {
  final String transactionId;
  final double amount;
  final Map<String, dynamic> paymentData;
  final String customerName;
  final List<CartItem> cartItems;

  const PaymentReceiptPage({
    super.key,
    required this.transactionId,
    required this.amount,
    required this.paymentData,
    required this.customerName,
    required this.cartItems,
  });

  @override
  Widget build(BuildContext context) {
    // Extract data from payment callback
    final String merchantName = paymentData['merchantName'] ?? 'Jop Jip';
    final String paymentMethod = paymentData['paymentMethod'] ?? 'Bank Transfer';
    final String sourceName = paymentData['sourceName'] ?? customerName;  // Use customer name if not in callback
    final String sourceAccount = paymentData['sourceAccount'] ?? '-';
    final String txnDateTime = paymentData['txnDateTime'] ?? '';
    final String refNo = paymentData['refNo']?.toString() ?? '-';
    final String billNumber = paymentData['billNumber'] ?? transactionId;
    final String status = paymentData['status'] ?? 'COMPLETED';
    final double txnAmount = (paymentData['txnAmount'] ?? amount).toDouble();
    
    // Parse date/time or use current
    String dateStr = '';
    String timeStr = '';
    if (txnDateTime.isNotEmpty) {
      try {
        // Format: "23/09/2025 11:37:55"
        final parts = txnDateTime.split(' ');
        dateStr = parts[0];
        timeStr = parts.length > 1 ? parts[1] : '';
      } catch (e) {
        final DateTime now = DateTime.now();
        dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
        timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      }
    } else {
      final DateTime now = DateTime.now();
      dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    }

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
        title: const Text('ໃບບິນການຊຳລະ'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Success Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 60,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 24),
            
            // Receipt Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Text(
                          merchantName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'INVOICE',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status == 'PAYMENT_COMPLETED' ? 'ຊຳລະສຳເລັດ' : 'ສຳເລັດ',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Transaction Details
                  _buildDetailRow('ເລກທີ່ບິນ:', billNumber),
                  const SizedBox(height: 12),
                  _buildDetailRow('ເລກອ້າງອີງ:', refNo),
                  const SizedBox(height: 12),
                  _buildDetailRow('ວັນທີ:', dateStr),
                  const SizedBox(height: 12),
                  _buildDetailRow('ເວລາ:', timeStr),
                  const SizedBox(height: 12),
                  _buildDetailRow('ວິທີຊຳລະ:', paymentMethod),
                  const SizedBox(height: 12),
                  _buildDetailRow('ຊື່ຜູ້ຊຳລະ:', sourceName),
                  const SizedBox(height: 12),
                  _buildDetailRow('ເລກບັນຊີ:', sourceAccount),
                  
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Products List
                  const Text(
                    'ລາຍການສິນຄ້າ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Product Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: const [
                        Expanded(flex: 2, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Expanded(flex: 4, child: Text('ລາຍລະອຽດສິນຄ້າ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Expanded(flex: 2, child: Text('ຈຳນວນ', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Expanded(flex: 2, child: Text('ລາຄາ', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Expanded(flex: 2, child: Text('ເປັນເງິນ', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Product Rows
                  ...cartItems.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final item = entry.value;
                    final subtotal = item.product.price * item.qty;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: Text('$index', style: const TextStyle(fontSize: 12))),
                          Expanded(
                            flex: 4,
                            child: Text(
                              item.product.name,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${item.qty}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${item.product.price.toStringAsFixed(0)} ₭',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${subtotal.toStringAsFixed(0)} ₭',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  
                  // Total Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 40),
                        Text(
                          '${txnAmount.toStringAsFixed(0)} ₭',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ຈຳນວນເງິນທັງໝົດ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${txnAmount.toStringAsFixed(2)} LAK',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9C27B0),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Footer
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'ຂອບໃຈທີ່ໃຊ້ບໍລິການ',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'https://www.bbbb.com.la',
                          style: TextStyle(
                            color: Color(0xFF9C27B0),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.purple[700],
                ),
                icon: const Icon(Icons.home),
                label: const Text('ກັບໄປໜ້າຫຼັກ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
