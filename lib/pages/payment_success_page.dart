import 'package:flutter/material.dart';
import '../state/cart_state.dart';
import '../models/product.dart';
import 'package:intl/intl.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';

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

    // Navigate to receipt after 1 second
    Future.delayed(const Duration(seconds: 1), () {
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
              '${NumberFormat('#,##0.00').format(widget.amount)} LAK',
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentReceiptPage extends StatefulWidget {
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
  State<PaymentReceiptPage> createState() => _PaymentReceiptPageState();
}

class _PaymentReceiptPageState extends State<PaymentReceiptPage> {
  bool _isPrinting = false;

  @override
  Widget build(BuildContext context) {
    // Extract data from payment callback
    final String merchantName = widget.paymentData['merchantName'] ?? 'Jop Jip';
    final String paymentMethod = widget.paymentData['paymentMethod'] ?? 'Bank Transfer';
    final String sourceName = widget.paymentData['sourceName'] ?? widget.customerName;  // Use customer name if not in callback
    final String sourceAccount = widget.paymentData['sourceAccount'] ?? '-';
    final String txnDateTime = widget.paymentData['txnDateTime'] ?? '';
    final String refNo = widget.paymentData['refNo']?.toString() ?? '-';
    final String billNumber = widget.paymentData['billNumber'] ?? widget.transactionId;
    final String status = widget.paymentData['status'] ?? 'COMPLETED';
    final double txnAmount = (widget.paymentData['txnAmount'] ?? widget.amount).toDouble();
    
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
                  ...widget.cartItems.asMap().entries.map((entry) {
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
                              '${NumberFormat('#,##0').format(item.product.price.toInt())} ₭',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${NumberFormat('#,##0').format(subtotal.toInt())} ₭',
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
                          '${NumberFormat('#,##0').format(txnAmount.toInt())} ₭',
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
                        '${NumberFormat('#,##0.00').format(txnAmount)} LAK',
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
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isPrinting ? null : _printReceipt,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: _isPrinting ? Colors.grey : Colors.blue[700],
                    ),
                    icon: _isPrinting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.print),
                    label: Text(_isPrinting ? 'ກຳລັງປະມວນຜົນ...' : 'ປິ້ນໃບບິນ'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
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

  String _buildItemsList() {
    StringBuffer items = StringBuffer();
    for (int i = 0; i < widget.cartItems.length; i++) {
      final item = widget.cartItems[i];
      final subtotal = item.product.price * item.qty;
      final name = item.product.name.length > 30
          ? '${item.product.name.substring(0, 30)}...'
          : item.product.name;

      items.writeln('${i + 1}. $name');
      items.writeln(
        'ຈຳນວນ: ${item.qty} | ລາຄາ: ${NumberFormat('#,##0').format(item.product.price.toInt())} ₭',
      );
      items.writeln(
        'ເປັນເງິນ: ${NumberFormat('#,##0').format(subtotal.toInt())} ₭',
      );
      items.writeln();
    }
    return items.toString();
  }

  Future<List<int>> _generateEscPosReceipt(
    String merchantName,
    String billNumber,
    String refNo,
    String dateStr,
    String timeStr,
    String paymentMethod,
    String sourceName,
    String sourceAccount,
    double txnAmount,
  ) async {
    // Generate ESC/POS commands for thermal printer
    final StringBuffer receipt = StringBuffer();

    // ESC/POS Commands
    const String newLine = '\n';
    const String centerAlign = '\x1B\x61\x01'; // Center align
    const String leftAlign = '\x1B\x61\x00'; // Left align
    const String fontSize2x = '\x1D\x21\x11'; // 2x font size

    receipt.write(centerAlign);
    receipt.write(fontSize2x);
    receipt.write(merchantName);
    receipt.write(newLine);
    receipt.write('\x1D\x21\x00'); // Normal font size
    receipt.write(newLine);
    receipt.write('INVOICE');
    receipt.write(newLine);
    receipt.write('================================');
    receipt.write(newLine);
    
    receipt.write(leftAlign);
    receipt.write('ເລກທີ່ບິນ: $billNumber$newLine');
    receipt.write('ເລກອ້າງອີງ: $refNo$newLine');
    receipt.write('ວັນທີ: $dateStr$newLine');
    receipt.write('ເວລາ: $timeStr$newLine');
    receipt.write('ວິທີຊຳລະ: $paymentMethod$newLine');
    receipt.write('ຊື່ຜູ້ຊຳລະ: $sourceName$newLine');
    receipt.write('ເລກບັນຊີ: $sourceAccount$newLine');
    receipt.write(newLine);
    
    receipt.write(centerAlign);
    receipt.write('================================$newLine');
    receipt.write('ລາຍການສິນຄ້າ$newLine');
    receipt.write(newLine);
    
    receipt.write(leftAlign);
    for (int i = 0; i < widget.cartItems.length; i++) {
      final item = widget.cartItems[i];
      final subtotal = item.product.price * item.qty;
      final name = item.product.name.length > 30
          ? '${item.product.name.substring(0, 30)}...'
          : item.product.name;

      receipt.write('${i + 1}. $name$newLine');
      receipt.write(
        'ຈຳນວນ: ${item.qty} | ລາຄາ: ${NumberFormat('#,##0').format(item.product.price.toInt())} ₭$newLine',
      );
      receipt.write(
        'ເປັນເງິນ: ${NumberFormat('#,##0').format(subtotal.toInt())} ₭$newLine',
      );
      receipt.write(newLine);
    }

    receipt.write(centerAlign);
    receipt.write('================================$newLine');
    receipt.write(fontSize2x);
    receipt.write('ທັງໝົດ: ${NumberFormat('#,##0').format(txnAmount.toInt())} ₭');
    receipt.write(newLine);
    receipt.write('\x1D\x21\x00'); // Normal font
    receipt.write(newLine);
    receipt.write('ຂອບໃຈທີ່ໃຊ້ບໍລິການ$newLine');
    receipt.write('www.bbbb.com.la$newLine');
    receipt.write(newLine);
    receipt.write(newLine);
    receipt.write('\x1B\x64\x03'); // Cut paper

    return receipt.toString().codeUnits;
  }

  Future<void> _printReceipt() async {
    setState(() => _isPrinting = true);

    try {
      // Extract data from payment callback
      final String merchantName = widget.paymentData['merchantName'] ?? 'Jop Jip';
      final String paymentMethod = widget.paymentData['paymentMethod'] ?? 'Bank Transfer';
      final String sourceName = widget.paymentData['sourceName'] ?? widget.customerName;
      final String sourceAccount = widget.paymentData['sourceAccount'] ?? '-';
      final String txnDateTime = widget.paymentData['txnDateTime'] ?? '';
      final String refNo = widget.paymentData['refNo']?.toString() ?? '-';
      final String billNumber = widget.paymentData['billNumber'] ?? widget.transactionId;
      final double txnAmount = (widget.paymentData['txnAmount'] ?? widget.amount).toDouble();

      // Parse date/time
      String dateStr = '';
      String timeStr = '';
      if (txnDateTime.isNotEmpty) {
        try {
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

      // Build receipt content
      final receiptText = '''
$merchantName
INVOICE
================================
ເລກທີ່ບິນ: $billNumber
ເລກອ້າງອີງ: $refNo
ວັນທີ: $dateStr
ເວລາ: $timeStr
ວິທີຊຳລະ: $paymentMethod
ຊື່ຜູ້ຊຳລະ: $sourceName
ເລກບັນຊີ: $sourceAccount

================================
ລາຍການສິນຄ້າ

${_buildItemsList()}

================================
ທັງໝົດ: ${NumberFormat('#,##0').format(txnAmount.toInt())} ₭


ຂອບໃຈທີ່ໃຊ້ບໍລິການ
www.bbbb.com.la


''';

      // Send to printer via ESC/POS
      try {
        // For EDC thermal printer, use ESC/POS commands
        final bytes = await _generateEscPosReceipt(
          merchantName,
          billNumber,
          refNo,
          dateStr,
          timeStr,
          paymentMethod,
          sourceName,
          sourceAccount,
          txnAmount,
        );
        
        // Print (this would be sent to your EDC printer)
        debugPrint('🖨️ Printing receipt...');
        // You can send these bytes to your EDC printer device
      } catch (e) {
        debugPrint('Printer error: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ປິ້ນສຳເລັດ'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ຜິດພາດ: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }
}
