import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AppProvider with ChangeNotifier {
  SharedPreferences? _prefs;

  bool _isLoggedIn = false;
  String _username = '';
  bool _isStaff = false;
  int? _userId;

  List<Map<String, dynamic>> _cart = [];
  List<Map<String, dynamic>> _wishlist = [];
  String _serverIp = '';

  AppProvider() {
    _initPrefs();
  }

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  String get username => _username;
  bool get isStaff => _isStaff;
  int? get userId => _userId;
  List<Map<String, dynamic>> get cart => _cart;
  List<Map<String, dynamic>> get wishlist => _wishlist;
  String get serverIp => _serverIp.isEmpty ? ApiService.baseUrl : _serverIp;

  int get cartCount => _cart.fold<int>(0, (sum, item) => sum + (item['quantity'] as int));
  double get cartSubtotal => _cart.fold<double>(0.0, (sum, item) {
    final price = item['product']['sale_price'] ?? item['product']['price'];
    return sum + (price * item['quantity']);
  });

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Load auth
    _isLoggedIn = _prefs?.getBool('isLoggedIn') ?? false;
    _username = _prefs?.getString('username') ?? '';
    _isStaff = _prefs?.getBool('isStaff') ?? false;
    _userId = _prefs?.getInt('userId');

    // Load server IP
    _serverIp = _prefs?.getString('serverIp') ?? '';
    if (_serverIp.isNotEmpty) {
      ApiService.baseUrl = _serverIp;
    }

    // Load Cart
    final cartStr = _prefs?.getString('cart') ?? '[]';
    try {
      _cart = List<Map<String, dynamic>>.from(json.decode(cartStr));
    } catch (e) {
      _cart = [];
    }

    // Load Wishlist
    final wishlistStr = _prefs?.getString('wishlist') ?? '[]';
    try {
      _wishlist = List<Map<String, dynamic>>.from(json.decode(wishlistStr));
    } catch (e) {
      _wishlist = [];
    }

    notifyListeners();
  }

  // Set Server IP
  Future<void> setServerIp(String ip) async {
    _serverIp = ip;
    ApiService.baseUrl = ip;
    await _prefs?.setString('serverIp', ip);
    notifyListeners();
  }

  // Auth Operations
  Future<Map<String, dynamic>> login(String user, String pass) async {
    final res = await ApiService.login(user, pass);
    if (res['success'] == true) {
      _isLoggedIn = true;
      _username = res['user']['username'];
      _isStaff = res['user']['is_staff'];
      _userId = res['user']['id'];

      await _prefs?.setBool('isLoggedIn', true);
      await _prefs?.setString('username', _username);
      await _prefs?.setBool('isStaff', _isStaff);
      if (_userId != null) {
        await _prefs?.setInt('userId', _userId!);
      }
      notifyListeners();
    }
    return res;
  }

  Future<Map<String, dynamic>> register(String user, String pass, String email) async {
    final res = await ApiService.register(user, pass, email);
    if (res['success'] == true) {
      _isLoggedIn = true;
      _username = res['user']['username'];
      _isStaff = res['user']['is_staff'];
      _userId = res['user']['id'];

      await _prefs?.setBool('isLoggedIn', true);
      await _prefs?.setString('username', _username);
      await _prefs?.setBool('isStaff', _isStaff);
      if (_userId != null) {
        await _prefs?.setInt('userId', _userId!);
      }
      notifyListeners();
    }
    return res;
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _username = '';
    _isStaff = false;
    _userId = null;

    await _prefs?.remove('isLoggedIn');
    await _prefs?.remove('username');
    await _prefs?.remove('isStaff');
    await _prefs?.remove('userId');
    notifyListeners();
  }

  // Cart Operations
  Future<void> addToCart(Map<String, dynamic> product, {int quantity = 1}) async {
    final index = _cart.indexWhere((item) => item['product']['id'] == product['id']);
    if (index >= 0) {
      _cart[index]['quantity'] = (_cart[index]['quantity'] as int) + quantity;
    } else {
      _cart.add({
        'product': product,
        'quantity': quantity,
      });
    }
    await _saveCart();
  }

  Future<void> updateCartQty(int productId, int quantity) async {
    final index = _cart.indexWhere((item) => item['product']['id'] == productId);
    if (index >= 0) {
      if (quantity <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index]['quantity'] = quantity;
      }
      await _saveCart();
    }
  }

  Future<void> removeFromCart(int productId) async {
    _cart.removeWhere((item) => item['product']['id'] == productId);
    await _saveCart();
  }

  Future<void> clearCart() async {
    _cart = [];
    await _saveCart();
  }

  Future<void> _saveCart() async {
    await _prefs?.setString('cart', json.encode(_cart));
    notifyListeners();
  }

  // Wishlist Operations
  bool isInWishlist(int productId) {
    return _wishlist.any((item) => item['id'] == productId);
  }

  Future<void> toggleWishlist(Map<String, dynamic> product) async {
    final index = _wishlist.indexWhere((item) => item['id'] == product['id']);
    if (index >= 0) {
      _wishlist.removeAt(index);
    } else {
      _wishlist.add(product);
    }
    await _prefs?.setString('wishlist', json.encode(_wishlist));
    notifyListeners();
  }
}
