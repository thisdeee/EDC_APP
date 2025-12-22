import 'package:flutter/material.dart';
import 'pages/product_list_page.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Get GraphQL schema information
  print('🔍 Getting GraphQL schema...');
  final schema = await ApiService.getGraphQLSchema();
  if (schema != null) {
    print('📋 Schema data: $schema');
  }

  runApp(const PosApp());
}

class PosApp extends StatelessWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
      ),
      home: const ProductListPage(),
    );
  }
}
