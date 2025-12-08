// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import '../state/cart_state.dart';
// import 'package:intl/intl.dart';

// // หน้าแสดง Payment Link จาก PhaJay
// class PaymentLinkPage extends StatelessWidget {
//   final String redirectURL;
//   final String orderNo;
//   final double amount;

//   const PaymentLinkPage({
//     super.key,
//     required this.redirectURL,
//     required this.orderNo,
//     required this.amount,
//   });

//   Widget _buildPaymentOption({
//     required String title,
//     required String subtitle,
//     required IconData icon,
//     Color? iconColor,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           border: Border(
//             bottom: BorderSide(color: Colors.grey[200]!, width: 1),
//           ),
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 40,
//               height: 40,
//               decoration: BoxDecoration(
//                 color: iconColor?.withOpacity(0.1) ?? Colors.grey[100],
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Icon(
//                 icon,
//                 color: iconColor ?? Colors.grey[600],
//                 size: 24,
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: const TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black87,
//                     ),
//                   ),
//                   if (subtitle.isNotEmpty) ...[
//                     const SizedBox(height: 2),
//                     Text(
//                       subtitle,
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//             Icon(
//               Icons.chevron_right,
//               color: Colors.grey[400],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final dateFormat = DateFormat('dd/MM/yyyy', 'en_US');
//     final timeFormat = DateFormat('HH:mm:ss', 'en_US');
//     final now = DateTime.now();
    
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black87),
//           onPressed: () {
//             Navigator.of(context).popUntil((route) => route.isFirst);
//           },
//         ),
//         title: const Text(
//           'ເລືອກຊ່ອງທາງການຊຳລະ',
//           style: TextStyle(
//             color: Colors.black87,
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: Image.asset(
//               'assets/phajay_logo.png',
//               height: 32,
//               errorBuilder: (context, error, stackTrace) {
//                 return Container(
//                   width: 32,
//                   height: 32,
//                   decoration: BoxDecoration(
//                     color: Colors.blue[700],
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(Icons.payment, color: Colors.white, size: 20),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             // Blue Card with Amount
//             Container(
//               margin: const EdgeInsets.all(16),
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.blue.withOpacity(0.3),
//                     blurRadius: 10,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.2),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: const Icon(
//                           Icons.account_balance_wallet,
//                           color: Colors.white,
//                           size: 24,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       const Text(
//                         'ຍອດລວມ',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 16,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                     '${amount.toStringAsFixed(2)} LAK',
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 36,
//                       fontWeight: FontWeight.bold,
//                       letterSpacing: 1,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         dateFormat.format(now),
//                         style: TextStyle(
//                           color: Colors.white.withOpacity(0.9),
//                           fontSize: 13,
//                         ),
//                       ),
//                       Text(
//                         timeFormat.format(now),
//                         style: TextStyle(
//                           color: Colors.white.withOpacity(0.9),
//                           fontSize: 13,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//             // Warning Message
//             Container(
//               margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.blue[50],
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.blue[200]!),
//               ),
//               child: Row(
//                 children: [
//                   Icon(Icons.security, color: Colors.blue[700], size: 20),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Text(
//                       'ກະລຸນາກວດສອບຂໍ້ມູນທຸກຄັ້ງກ່ອນຊຳລະ ແລະ ຖ້າມີປັນຫາໃດໆສາມາດຕິດຕໍ່ພະນັກງານທີ່ປຶກສາໄດ້ໂດຍວິລະ.',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.blue[900],
//                         height: 1.4,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 8),

//             // Payment Methods Section Header
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//               alignment: Alignment.centerLeft,
//               child: Text(
//                 'ເລືອກຊ່ອງທາງການຊຳລະ',
//                 style: TextStyle(
//                   fontSize: 13,
//                   color: Colors.grey[600],
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),

//             // Payment Options
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.05),
//                     blurRadius: 10,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               margin: const EdgeInsets.symmetric(horizontal: 16),
//               child: Column(
//                 children: [
//                   // Bank Account
//                   _buildPaymentOption(
//                     title: 'JDB',
//                     subtitle: 'ຜ່ານແອັບມືຖືຂອງທະນາຄານ',
//                     icon: Icons.account_balance,
//                     iconColor: Colors.blue[700],
//                     onTap: () {
//                       _openPaymentLink(context);
//                     },
//                   ),

//                   // Credit/Debit Card - VISA
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                     alignment: Alignment.centerLeft,
//                     child: Text(
//                       'ຊຳລະ Credit/Debit',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey[500],
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                   _buildPaymentOption(
//                     title: 'VISA',
//                     subtitle: 'ບັດເຄຣດິດ/ເດບິດ (ປຶກສາບັດຂອງທ່ານເພື່ອຮັບ 3DS ເພີ່ມ)',
//                     icon: Icons.credit_card,
//                     iconColor: Colors.blue[800],
//                     onTap: () {
//                       _openPaymentLink(context);
//                     },
//                   ),
//                   _buildPaymentOption(
//                     title: 'MASTERCARD',
//                     subtitle: 'ບັດເຄຣດິດ/ເດບິດ (ປຶກສາບັດຂອງທ່ານເພື່ອຮັບ 3DS ເພີ່ມ)',
//                     icon: Icons.credit_card,
//                     iconColor: Colors.orange[700],
//                     onTap: () {
//                       _openPaymentLink(context);
//                     },
//                   ),

//                   // QR Code
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                     alignment: Alignment.centerLeft,
//                     child: Text(
//                       'ຊຳລະ QR',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey[500],
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                   _buildPaymentOption(
//                     title: 'LAO QR',
//                     subtitle: 'ສະແກນບໍ່ຕ້ອງໃຫ້ຂໍ້ມູນເພີ່ມເຕີມ',
//                     icon: Icons.qr_code_scanner,
//                     iconColor: Colors.teal[700],
//                     onTap: () {
//                       _openPaymentLink(context);
//                     },
//                   ),
//                   _buildPaymentOption(
//                     title: 'PROMPTPAY',
//                     subtitle: 'ສະແກນບໍ່ຕ້ອງໃຫ້ຂໍ້ມູນເພີ່ມເຕີມ',
//                     icon: Icons.qr_code,
//                     iconColor: Colors.indigo[700],
//                     onTap: () {
//                       _openPaymentLink(context);
//                     },
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 24),

//             // Order Info
//             Container(
//               margin: const EdgeInsets.symmetric(horizontal: 16),
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: Colors.grey[200]!),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'ລາຍລະອຽດການສັ່ງຊື້',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.grey[800],
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         'Order Number:',
//                         style: TextStyle(fontSize: 13, color: Colors.grey[600]),
//                       ),
//                       Text(
//                         orderNo,
//                         style: const TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         'Payment Link:',
//                         style: TextStyle(fontSize: 13, color: Colors.grey[600]),
//                       ),
//                       TextButton(
//                         onPressed: () {
//                           Clipboard.setData(ClipboardData(text: redirectURL));
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                               content: Text('Payment link copied!'),
//                               duration: Duration(seconds: 2),
//                             ),
//                           );
//                         },
//                         child: const Text(
//                           'Copy Link',
//                           style: TextStyle(fontSize: 12),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 24),
//           ],
//         ),
//       ),
//     );
//   }

//   void _openPaymentLink(BuildContext context) {
//     // Show confirmation and open link
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('ເປີດ Payment Link'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text('ກະລຸນາເປີດລິ້ງນີ້ໃນແອັບມືຖືຂອງທ່ານເພື່ອສຳເລັດການຊຳລະ'),
//             const SizedBox(height: 16),
//             SelectableText(
//               redirectURL,
//               style: const TextStyle(fontSize: 12, color: Colors.blue),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           FilledButton.icon(
//             onPressed: () {
//               Clipboard.setData(ClipboardData(text: redirectURL));
//               Navigator.pop(context);
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text('Payment link copied! Open in your banking app.'),
//                   backgroundColor: Colors.green,
//                 ),
//               );
              
//               // Clear cart and go home after a delay
//               Future.delayed(const Duration(seconds: 2), () {
//                 CartState.clear();
//                 Navigator.of(context).popUntil((route) => route.isFirst);
//               });
//             },
//             style: FilledButton.styleFrom(
//               backgroundColor: const Color(0xFF1E3A8A),
//             ),
//             icon: const Icon(Icons.copy),
//             label: const Text('Copy & Continue'),
//           ),
//         ],
//       ),
//     );
//   }
// }
