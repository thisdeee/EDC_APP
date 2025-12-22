import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';
import 'qr_payment_page.dart';

/// ------------------------------
/// Credit Card WebView Page
/// ------------------------------
class CreditCardWebViewPage extends StatefulWidget {
  final String url;
  const CreditCardWebViewPage({super.key, required this.url});

  @override
  State<CreditCardWebViewPage> createState() =>
      _CreditCardWebViewPageState();
}

class _CreditCardWebViewPageState extends State<CreditCardWebViewPage> {
  WebViewController? _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (request) {
              if (request.url.contains('success')) {
                Navigator.pop(context, true);
                return NavigationDecision.prevent;
              }
              if (request.url.contains('cancel')) {
                Navigator.pop(context, false);
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
            onPageStarted: (_) {
              setState(() => _isLoading = true);
            },
            onPageFinished: (_) {
              setState(() => _isLoading = false);
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.url));
    } else {
      // On web, launch in new tab and pop
      Future.microtask(() async {
        if (await canLaunchUrl(Uri.parse(widget.url))) {
          await launchUrl(
            Uri.parse(widget.url),
            webOnlyWindowName: '_blank',
          );
        }
        if (mounted) Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.url.startsWith('http')) {
      return const Scaffold(
        body: Center(child: Text('Invalid payment URL')),
      );
    }
    if (kIsWeb) {
      return const Scaffold(
        body: Center(child: Text('Opening payment page...')),
      );
    }
    // Mobile: show WebView with loading indicator
    return Scaffold(
      appBar: AppBar(title: const Text('Credit Card Payment')),
      body: Stack(
        children: [
          if (_controller != null)
            WebViewWidget(controller: _controller!),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

/// ------------------------------
/// Bank Selection Page
/// ------------------------------
class BankSelectionPage extends StatefulWidget {
  final double amount;
  final String secretKey;

  const BankSelectionPage({
    super.key,
    required this.amount,
    required this.secretKey,
  });

  @override
  State<BankSelectionPage> createState() => _BankSelectionPageState();
}

class _BankSelectionPageState extends State<BankSelectionPage> {
  bool _processing = false;
  String? _selectedBank;

  final List<Map<String, String>> banks = [
    {'name': 'JDB', 'logo': 'assets/images/jdb.png', 'code': 'jdb'},
  ];

  Future<void> _selectBank(String bankCode, String bankName) async {
    setState(() {
      _processing = true;
      _selectedBank = bankCode;
    });

    try {
      final result = await ApiService.createQRPayment(
        amount: widget.amount,
        description: 'Order payment',
        secretKey: widget.secretKey,
        bankCode: bankCode,
      );

      if (result != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => QRPaymentPage(
              qrCode: result['qrCode'],
              transactionId: result['transactionId'],
              amount: widget.amount,
              secretKey: widget.secretKey,
              link: result['link'],
              customerName: 'Guest',
              customerPhone: '',
              bankName: bankName,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
          _selectedBank = null;
        });
      }
    }
  }

  Future<void> _payByCreditCard() async {
    setState(() => _processing = true);

    try {
      final result = await ApiService.createCreditCardPayment(
        amount: widget.amount,
        description: 'Credit Card Payment',
        secretKey: widget.secretKey,
        tag1: 'AppZap Shop',
        tag2: '666bbb461732a2e46233fdf9',
        tag3: 'ORDER-0001',
      );

      if (result['paymentUrl'] != null && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                CreditCardWebViewPage(url: result['paymentUrl']),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Credit Card payment failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Select Payment Bank',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _amountCard(),
              const SizedBox(height: 24),
              _bankGrid(),
              // const SizedBox(height: 16),
              // _creditCardButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _amountCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text('ຈຳນວນເງິນທີ່ຕ້ອງຊໍາລະ',
                style: TextStyle(color: Colors.white70)),
            Text('${widget.amount.toStringAsFixed(0)} ₭',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Widget _bankGrid() => Expanded(
        child: GridView.builder(
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: banks.length,
          itemBuilder: (_, i) {
            final bank = banks[i];
            final isLoading =
                _processing && _selectedBank == bank['code'];

            return InkWell(
              onTap: _processing
                  ? null
                  : () =>
                      _selectBank(bank['code']!, bank['name']!),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Center(
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : Text(bank['name']!,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                ),
              ),
            );
          },
        ),
      );

  // Widget _creditCardButton() => ElevatedButton.icon(
  //       onPressed: _processing ? null : _payByCreditCard,
  //       icon: const Icon(Icons.credit_card),
  //       label: const Text('Pay by Credit Card'),
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: Colors.green,
  //         minimumSize: const Size.fromHeight(50),
  //       ),
  //     );
}
