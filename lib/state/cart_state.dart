import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/product.dart';

class CartState {
  static final Map<String, CartItem> cart = {};

  static void addToCart(Product p) {
    if (cart.containsKey(p.id)) {
      cart[p.id]!.qty++;
    } else {
      cart[p.id] = CartItem(product: p);
    }
    _saveCart();
  }

  static void removeFromCart(String productId) {
    cart.remove(productId);
    _saveCart();
  }

  static void increaseQty(String productId) {
    if (cart.containsKey(productId)) {
      cart[productId]!.qty++;
      _saveCart();
    }
  }

  static void decreaseQty(String productId) {
    if (cart.containsKey(productId)) {
      if (cart[productId]!.qty > 1) {
        cart[productId]!.qty--;
      } else {
        cart.remove(productId);
      }
      _saveCart();
    }
  }

  static void clear() {
    cart.clear();
    _saveCart();
  }

  static double get total {
    return cart.values.fold(0.0, (sum, item) => sum + item.lineTotal);
  }

  static int get itemCount {
    return cart.values.fold(0, (sum, item) => sum + item.qty);
  }

  static Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = cart.map((key, value) => MapEntry(
          key,
          {
            'productId': value.product.id,
            'productName': value.product.name,
            'productPrice': value.product.price,
            'productCategory': value.product.category,
            'productImageUrl': value.product.imageUrl,
            'productDescription': value.product.description,
            'productStock': value.product.stock,
            'productIsUsingSalePage': value.product.isUsingSalePage,
            'qty': value.qty,
          },
        ));
    await prefs.setString('cart', json.encode(cartData));
  }

  static Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartString = prefs.getString('cart');
    if (cartString != null) {
      final Map<String, dynamic> cartData = json.decode(cartString);
      cart.clear();
      cartData.forEach((key, value) {
        final product = Product(
          id: value['productId'],
          name: value['productName'],
          price: value['productPrice'],
          category: value['productCategory'],
          imageUrl: value['productImageUrl'],
          description: value['productDescription'],
          stock: value['productStock'],
          isUsingSalePage: value['productIsUsingSalePage'] ?? false,
        );
        cart[key] = CartItem(product: product, qty: value['qty']);
      });
    }
  }
}
