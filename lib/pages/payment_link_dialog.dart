import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../state/cart_state.dart';
import '../services/api_service.dart';
import 'payment_success_page.dart';

class PaymentLinkDialog extends StatefulWidget {
  final String redirectURL;
  final String orderNo;
  final double amount;
  final String customerName;
  final String customerPhone;

  const PaymentLinkDialog({
    super.key,
    required this.redirectURL,
    required this.orderNo,
    required this.amount,
    required this.customerName,
    required this.customerPhone,
  });

  @override
  State<PaymentLinkDialog> createState() => _PaymentLinkDialogState();
}

class _PaymentLinkDialogState extends State<PaymentLinkDialog> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('=== PAYMENT LINK DIALOG ===');
    print('Loading URL: ${widget.redirectURL}');
    print('Order No: ${widget.orderNo}');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          print('Page started loading: $url');
          setState(() => _isLoading = true);
        },
        onPageFinished: (url) {
          print('Page finished loading: $url');
          setState(() => _isLoading = false);
        },
        onWebResourceError: (error) {
          print('WebView error: ${error.description}');
        },
        onNavigationRequest: (request) {
          print('Navigation request: ${request.url}');
          // Handle payment callbacks
          if (request.url.contains('success') || request.url.contains('payment/success')) {
            _handlePaymentSuccess();
            return NavigationDecision.prevent;
          } else if (request.url.contains('fail')) {
            _handlePaymentFailure();
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.redirectURL));
  }

  void _handlePaymentSuccess() async {
    try {
      // Save cart items before clearing
      final cartItems = CartState.cart.values.toList();

      // Create order and update stock
      await ApiService.createOrderAndUpdateStock(
        transactionId: widget.orderNo,
        cartItems: cartItems,
        customerName: widget.customerName,
        customerPhone: widget.customerPhone,
        shopId: "6864d7d2f32c2508f58eb7e8", // Shop ID from API
        shopName: "Jop Jip", // Shop name
      );

      // Clear cart
      CartState.clear();

      // Close dialog and navigate to success page
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PaymentSuccessPage(
              transactionId: widget.orderNo,
              amount: widget.amount,
              paymentData: {},
              customerName: widget.customerName,
              cartItems: cartItems,
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error processing payment: $e');
      // Even if order creation fails, still clear cart and show success
      CartState.clear();

      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PaymentSuccessPage(
              transactionId: widget.orderNo,
              amount: widget.amount,
              paymentData: {},
              customerName: widget.customerName,
              cartItems: CartState.cart.values.toList(),
            ),
          ),
        );
      }
    }
  }

  void _handlePaymentFailure() {
    if (mounted) {
      Navigator.of(context).pop(); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(10),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Payment - ${widget.orderNo}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
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
                                Navigator.pop(context); // Close alert
                                Navigator.pop(context); // Close payment dialog
                              },
                              child: const Text('Yes'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // WebView
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}