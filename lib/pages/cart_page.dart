import 'package:flutter/material.dart';
import '../state/cart_state.dart';
import 'bank_selection_page.dart';
import 'qr_payment_page.dart';
import 'payment_success_page.dart';
import 'payment_webview_page.dart';
import '../services/api_service.dart';

// Helper widget for summary rows
class SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;
  final bool large;
  const SummaryRow(
      {super.key,
      required this.label,
      required this.value,
      this.bold = false,
      this.large = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: large ? 18 : 14,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text('₭ ${value.toStringAsFixed(0)}', style: style),
      ],
    );
  }
}

// Page 2: Cart Review
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  static const String SECRET_KEY =
      '\$2b\$10\$sRx/uTHMydWDIdizURcgxecjFPbvnUNFzOwTl3lxNyV35zoFY4HnO';

  void _proceedToPayment() async {
    // Generate QR payment without creating order
    try {
      // Generate transaction ID
      final transactionId = 'TXN_${DateTime.now().millisecondsSinceEpoch}';

      // Create order first
      final orderResult = await ApiService.createOrderGroup(
        shop: '6864d7d2f32c2508f58eb7e8',
        type: 'POS',
        amount: CartState.cart.values.fold(0, (sum, item) => sum + item.qty),
        sumPrice: CartState.total.toInt(),
        sumPriceBaht: 0,
        sumPriceUsd: 0,
        totalPrice: CartState.total.toInt(),
        customerName: 'Walk-in Customer',
        phone: 'N/A',
        logistic: '',
        destinationLogistic: '',
        affiliateName: '',
        orders: CartState.cart.keys.first, // Use first product ID
      );

      if (orderResult != null && mounted) {
        final orderId = orderResult['id']; // Extract order ID

        // Then create QR payment
        final paymentResult = await ApiService.createQRPayment(
          amount: CartState.total,
          description: 'Payment for transaction $transactionId',
          secretKey: SECRET_KEY,
          bankCode: 'jdb', // Default bank
        );

        if (paymentResult != null && paymentResult['qrCode'] != null && mounted) {
          final qrCode = paymentResult['qrCode'];
          final link = paymentResult['link'] ?? '';

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QRPaymentPage(
                qrCode: qrCode,
                transactionId: transactionId,
                amount: CartState.total,
                secretKey: SECRET_KEY,
                link: link,
                customerName: 'Walk-in Customer',
                customerPhone: 'N/A',
                bankName: 'JDB',
                orderGroupId: orderId, // เพิ่ม orderGroupId
              ),
            ),
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to generate QR payment'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create order'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        title: const Text('ກະຕ່າສິນຄ້າ'),
      ),
      body: CartState.cart.isEmpty
          ? const Center(child: Text('ບໍ່ມີສິນຄ້າໃນກະຕ່າ'))
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: CartState.cart.values.map((item) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item.product.imageUrl?.isNotEmpty == true
                                        ? item.product.imageUrl!
                                        : 'https://picsum.photos/seed/${item.product.id}/100/100',
                                    fit: BoxFit.cover,
                                    width: 60,
                                    height: 60,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.shopping_bag,
                                          size: 30,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                        '₭ ${item.product.price.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                            color: Color(0xFFE91E63))),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon:
                                        const Icon(Icons.remove_circle_outline),
                                    onPressed: () => setState(() =>
                                        CartState.decreaseQty(item.product.id)),
                                  ),
                                  Text('${item.qty}',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () => setState(() =>
                                        CartState.increaseQty(item.product.id)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SummaryRow(label: 'ລາຄາ', value: CartState.total),
                      SummaryRow(label: 'ພາສີ (0%)', value: 0),
                      const Divider(height: 24),
                      SummaryRow(
                          label: 'ລວມລາຄາ', value: CartState.total, bold: true),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _proceedToPayment,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFFE91E63),
                          ),
                          child: const Text('ດໍາເນີນການຊໍາລະເງິນ',
                              style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      // Skip customer info page:
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //       builder: (_) => const CustomerInfoPage()),
                      // ).then((_) => setState(() {}));
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
