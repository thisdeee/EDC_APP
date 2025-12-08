import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../state/cart_state.dart';

class PaymentWebViewPage extends StatefulWidget {
  final String redirectURL;
  final String orderNo;
  
  const PaymentWebViewPage({
    super.key,
    required this.redirectURL,
    required this.orderNo,
  });
  
  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    print('=== PAYMENT WEBVIEW ===');
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
          if (request.url.contains('success_callback')) {
            _handlePaymentSuccess();
            return NavigationDecision.prevent;
          } else if (request.url.contains('fail_callback')) {
            _handlePaymentFailure();
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.redirectURL));
  }
  
  void _handlePaymentSuccess() {
    // Clear cart
    CartState.clear();
    
    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate back to home
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
  
  void _handlePaymentFailure() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment - ${widget.orderNo}'),
        leading: IconButton(
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
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
