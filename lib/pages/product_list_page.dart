import 'package:flutter/material.dart';
import '../models/product.dart';
import '../state/cart_state.dart';
import '../services/api_service.dart';
import 'product_detail_page.dart';
import 'cart_page.dart';

// Widget that tries multiple image paths
class _ImageWithMultiplePaths extends StatefulWidget {
  final List<String> paths;
  final double iconSize;

  const _ImageWithMultiplePaths({
    required this.paths,
    required this.iconSize,
  });

  @override
  State<_ImageWithMultiplePaths> createState() =>
      _ImageWithMultiplePathsState();
}

class _ImageWithMultiplePathsState extends State<_ImageWithMultiplePaths> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= widget.paths.length) {
      return Container(
        color: Colors.grey[300],
        child: Center(
          child: Icon(Icons.shopping_bag,
              size: widget.iconSize, color: Colors.grey),
        ),
      );
    }

    return Image.network(
      widget.paths[_currentIndex],
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        if (_currentIndex < widget.paths.length - 1) {
          Future.microtask(() {
            if (mounted) setState(() => _currentIndex++);
          });
          return const Center(child: CircularProgressIndicator());
        }
        return Container(
          color: Colors.grey[300],
          child: Center(
            child: Icon(Icons.shopping_bag,
                size: widget.iconSize, color: Colors.grey),
          ),
        );
      },
    );
  }
}

// Page 1: Product List
class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List<Product> _catalog = [];
  bool _isLoading = true;
  String? _error;

  String _query = '';
  String _category = 'All';
  String _stockFilter = 'All'; // All, In Stock, Out of Stock

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final products = await ApiService.fetchProducts();
      setState(() {
        _catalog = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _addToCart(Product p) {
    // Check if product is in stock
    if ((p.stock ?? 0) <= 0 || !p.isUsingSalePage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('This product is out of stock')),
            ],
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    
    setState(() {
      CartState.addToCart(p);
    });
    
    // Show success popup with animation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ເພີ່ມສຳເລັດ!',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    '${p.name}',
                    style: TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.shopping_cart, color: Colors.white70, size: 20),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 150,
          left: 20,
          right: 20,
        ),
      ),
    );
  }

  // Helper to build image with multiple fallback URLs
  Widget _buildImageWithFallback(
      String? filename, String productId, double iconSize) {
    if (filename == null || filename.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: Center(
          child: Icon(
            Icons.shopping_bag,
            size: iconSize,
            color: Colors.grey,
          ),
        ),
      );
    }

    // If already full URL, use it
    if (filename.startsWith('http')) {
      return Image.network(
        filename,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: Center(
              child: Icon(
                Icons.shopping_bag,
                size: iconSize,
                color: Colors.grey,
              ),
            ),
          );
        },
      );
    }

    // Try multiple paths for the filename
    // Convert .png to .jpg for S3, and try both extensions
    final filenameWithoutExt = filename.replaceAll(
        RegExp(r'\.(png|jpg|jpeg)$', caseSensitive: false), '');

    final paths = [
      'https://lailaocf-bucket.s3.amazonaws.com/resized/medium/$filenameWithoutExt.jpg',
      'https://lailaocf-bucket.s3.amazonaws.com/resized/medium/$filename',
      'https://lailaocf-bucket.s3.amazonaws.com/resized/large/$filenameWithoutExt.jpg',
      'https://lailaocf-bucket.s3.amazonaws.com/resized/small/$filenameWithoutExt.jpg',
      'https://lailaocf-bucket.s3.amazonaws.com/$filenameWithoutExt.jpg',
      'https://lailaocf-bucket.s3.amazonaws.com/$filename',
    ];

    return _ImageWithMultiplePaths(
      paths: paths,
      iconSize: iconSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      'All',
      ...{for (final p in _catalog) p.category}
    ];
    final filtered = _catalog.where((p) {
      final matchesQuery =
          _query.isEmpty || p.name.toLowerCase().contains(_query.toLowerCase());
      final matchesStock = _stockFilter == 'All' ||
          (_stockFilter == 'In Stock' && p.isUsingSalePage == true) ||
          (_stockFilter == 'Out of Stock' && p.isUsingSalePage == false);
      return matchesQuery && matchesStock;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('4B',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('+856 020 00000000', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  if (CartState.itemCount > 0) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartPage()),
                    ).then((_) => setState(() {}));
                  }
                },
              ),
              if (CartState.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${CartState.itemCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search products...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ຜະລິດຕະພັນຍອດນິຍົມ',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        DropdownButton<String>(
                          value: _stockFilter,
                          underline: const SizedBox(),
                          items: [
                            DropdownMenuItem(
                                value: 'All', child: Text('All Stock')),
                            DropdownMenuItem(
                                value: 'In Stock', child: Text('In Stock')),
                            DropdownMenuItem(
                                value: 'Out of Stock',
                                child: Text('Out of Stock')),
                          ],
                          onChanged: (v) =>
                              setState(() => _stockFilter = v ?? 'All'),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _category,
                          underline: const SizedBox(),
                          items: categories
                              .map((c) =>
                                  DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _category = v ?? 'All'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                'Error: $_error',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadProducts,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _catalog.isEmpty
                        ? const Center(child: Text('No products available'))
                        : GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, i) {
                              final p = filtered[i];
                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              ProductDetailPage(product: p)),
                                    ).then((_) => setState(() {}));
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                    top: Radius.circular(12)),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                    top: Radius.circular(12)),
                                            child: _buildImageWithFallback(
                                              p.imageUrl,
                                              '${p.id}',
                                              60,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.name,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              p.stock != null
                                                  ? 'ຈຳນວນ: ${p.stock}'
                                                  : 'ຈຳນວນ: -',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[600]),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  '₭ ${p.price.toStringAsFixed(0)}',
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFFE91E63)),
                                                ),
                                                SizedBox(
                                                  height: 28,
                                                  child: ElevatedButton(
                                                    onPressed: ((p.stock ?? 0) <= 0 || !p.isUsingSalePage)
                                                        ? null
                                                        : () => _addToCart(p),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8),
                                                      backgroundColor:
                                                          const Color(
                                                              0xFFE91E63),
                                                      foregroundColor:
                                                          Colors.white,
                                                      disabledBackgroundColor:
                                                          Colors.grey[400],
                                                      disabledForegroundColor:
                                                          Colors.grey[600],
                                                    ),
                                                    child: Text(
                                                        ((p.stock ?? 0) <= 0 || !p.isUsingSalePage)
                                                            ? 'ໝົດ'
                                                            : 'ເພີ່ມ',
                                                        style: const TextStyle(
                                                            fontSize: 12)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
