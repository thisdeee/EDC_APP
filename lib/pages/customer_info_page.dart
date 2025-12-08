import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../state/cart_state.dart';
import '../services/api_service.dart';
import 'qr_payment_page.dart';

// Page 3: Customer Information Form
class CustomerInfoPage extends StatefulWidget {
  const CustomerInfoPage({super.key});

  @override
  State<CustomerInfoPage> createState() => _CustomerInfoPageState();
}

class _CustomerInfoPageState extends State<CustomerInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _provinceController = TextEditingController();
  final _districtController = TextEditingController();
  final _villageController = TextEditingController();
  String _memberType = 'ລາຍລະອຽດ';
  bool _processing = false;

  // PhaJay Secret Key
  static const String SECRET_KEY = '\$2b\$10\$sRx/uTHMydWDIdizURcgxecjFPbvnUNFzOwTl3lxNyV35zoFY4HnO';

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('customer_name') ?? '';
      _phoneController.text = prefs.getString('customer_phone') ?? '';
      _villageController.text = prefs.getString('customer_village') ?? '';
      _memberType = prefs.getString('customer_member_type') ?? 'ລາຍລະອຽດ';
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('customer_name', _nameController.text);
    await prefs.setString('customer_phone', _phoneController.text);
    await prefs.setString('customer_village', _villageController.text);
    await prefs.setString('customer_member_type', _memberType);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    _villageController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_formKey.currentState!.validate()) {
      // Save customer data for next time
      await _saveData();
      
      setState(() => _processing = true);

      try {
        // Generate unique transaction reference
        final transactionRef = 'TXN${DateTime.now().millisecondsSinceEpoch}';

        // Create description from cart items (English only for BCEL)
        final itemsList = CartState.cart.values
            .map((item) => '${item.product.name} x${item.qty}')
            .join(', ');
        // Use English description for BCEL compatibility
        final description = 'Purchase $transactionRef';

        print('Creating QR payment for: $description');

        // Call PhaJay API to create BCEL QR payment
        final paymentResponse = await ApiService.createQRPayment(
          amount: CartState.total,
          description: description,
          secretKey: SECRET_KEY,
        );

        final qrCode = paymentResponse['qrCode'];
        final transactionId = paymentResponse['transactionId'];
        final link = paymentResponse['link'];

        print('=== PAYMENT API RESPONSE ===');
        print('Response: $paymentResponse');
        print('qrCode: $qrCode');
        print('transactionId: $transactionId');
        print('link: $link');

        if (qrCode != null && transactionId != null) {
          // Save pending transaction
          final prefs = await SharedPreferences.getInstance();
          final list = prefs.getStringList('pending_orders') ?? [];
          list.add('$transactionId|${DateTime.now().toIso8601String()}|${CartState.total}');
          await prefs.setStringList('pending_orders', list);

          setState(() => _processing = false);

          // Navigate to QR Payment Page
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QRPaymentPage(
                  qrCode: qrCode,
                  transactionId: transactionId,
                  amount: CartState.total,
                  secretKey: SECRET_KEY,
                  link: link,
                  customerName: _nameController.text,
                  customerPhone: _phoneController.text,
                ),
              ),
            );
          }
        } else {
          throw Exception('QR Code not received from payment gateway');
        }
      } catch (e) {
        setState(() => _processing = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
        title: const Text('ຂໍ້ມູນລູກຄ້າ'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ຊື່ ແລະ ນາມສະກຸນ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'ຊື່ ແລະ ນາມສະກຸນ',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              const Text(
                'ເບີໂທລະສັບ (ຫ້າມປ້ອນ 020, 030) *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  hintText: '000-000-000',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 8,
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Required';
                  if (v!.length < 7 || v.length > 8) return 'ກະລຸນາປ້ອນ 7-8 ໂຕເລກ';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'ແຂວງ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  hintText: '--ເລືອກ--',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'ວຽງຈັນ', child: Text('ວຽງຈັນ')),
                  DropdownMenuItem(
                      value: 'ຫຼວງພະບາງ', child: Text('ຫຼວງພະບາງ')),
                  DropdownMenuItem(
                      value: 'ສະຫວັນນະເຂດ', child: Text('ສະຫວັນນະເຂດ')),
                ],
                onChanged: (v) {},
              ),
              const SizedBox(height: 16),
              const Text(
                'ເມືອງ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  hintText: '--ເລືອກ--',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'ສີສັດຕະນາກ', child: Text('ສີສັດຕະນາກ')),
                ],
                onChanged: (v) {},
              ),
              const SizedBox(height: 16),
              const Text(
                'ບ້ານ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _villageController,
                decoration: const InputDecoration(
                  hintText: 'ບ້ານ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'ບໍລິສັດຂົນສົ່ງ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  hintText: '--ເລືອກ--',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Thunder express', child: Text('Thunder express')),
                ],
                onChanged: (v) {},
              ),
              const SizedBox(height: 16),
              const Text(
                'ລາຍລະອຽດ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'ລາຍລະອຽດ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Affiliate',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'ປ້ອນ Affiliate ຫຼື ຜູ້ແນະນຳ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _processing ? null : _continue,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.purple[700],
                  ),
                  child: _processing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('ດໍາເນີນການຊຳລະເງິນ',
                          style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
