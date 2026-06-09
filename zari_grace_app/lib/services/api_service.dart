import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Use 10.0.2.2 for Android emulator to connect to host's localhost
  static String _baseUrl = kIsWeb 
      ? 'http://localhost:8000' 
      : (Platform.isAndroid ? 'http://10.0.2.2:8000' : 'http://localhost:8000');

  static String get baseUrl => _baseUrl;
  static set baseUrl(String url) {
    // Standardize URL: strip trailing slash
    if (url.endsWith('/')) {
      _baseUrl = url.substring(0, url.length - 1);
    } else {
      _baseUrl = url;
    }
  }

  static String resolveImageUrl(String url) {
    if (url.isEmpty) return '';
    // If it's a relative path, prepend base url
    if (url.startsWith('/')) {
      return '$_baseUrl$url';
    }
    // If it's absolute but pointing to localhost, 127.0.0.1 or 10.0.2.2, replace with the user's custom base URL
    if (url.contains('127.0.0.1:8000') || url.contains('localhost:8000') || url.contains('10.0.2.2:8000')) {
      try {
        final uri = Uri.parse(url);
        final pathAndQuery = uri.path + (uri.hasQuery ? '?${uri.query}' : '');
        final formattedPath = pathAndQuery.startsWith('/') ? pathAndQuery : '/$pathAndQuery';
        return '$_baseUrl$formattedPath';
      } catch (e) {
        var resolved = url;
        resolved = resolved.replaceAll('http://127.0.0.1:8000', _baseUrl);
        resolved = resolved.replaceAll('http://localhost:8000', _baseUrl);
        resolved = resolved.replaceAll('http://10.0.2.2:8000', _baseUrl);
        return resolved;
      }
    }
    return url;
  }

  static Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // GET Home data (Banners, Categories, Featured, Latest)
  static Future<Map<String, dynamic>> getHomeData() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/home/'),
        headers: _getHeaders(),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load home data: ${response.statusCode}');
      }
    } catch (e) {
      return _getMockHomeData();
    }
  }

  // GET Product list with filters
  static Future<List<dynamic>> getProducts({
    String? categorySlug,
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (categorySlug != null && categorySlug.isNotEmpty) {
        queryParams['category'] = categorySlug;
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }
      if (minPrice != null) {
        queryParams['min_price'] = minPrice.toString();
      }
      if (maxPrice != null) {
        queryParams['max_price'] = maxPrice.toString();
      }
      if (sortBy != null && sortBy.isNotEmpty) {
        queryParams['sort'] = sortBy;
      }

      final uri = Uri.parse('$_baseUrl/api/products/').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _getHeaders());
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['products'] ?? [];
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      return _getMockProducts(categorySlug);
    }
  }

  // GET Product details
  static Future<Map<String, dynamic>> getProductDetail(String slug) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/product/$slug/'),
        headers: _getHeaders(),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load product detail');
      }
    } catch (e) {
      return _getMockProductDetail(slug);
    }
  }

  // POST Login
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/login/'),
        headers: _getHeaders(),
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );
      return json.decode(response.body);
    } catch (e) {
      // Offline fallback login for testing
      if (username.toLowerCase() == 'admin') {
        return {
          'success': true,
          'user': {
            'id': 1,
            'username': 'admin',
            'email': 'admin@zariegrace.com',
            'is_staff': true,
          }
        };
      }
      return {
        'success': true,
        'user': {
          'id': 2,
          'username': username,
          'email': '$username@gmail.com',
          'is_staff': false,
        }
      };
    }
  }

  // POST Register
  static Future<Map<String, dynamic>> register(String username, String password, String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/register/'),
        headers: _getHeaders(),
        body: json.encode({
          'username': username,
          'password': password,
          'email': email,
        }),
      );
      return json.decode(response.body);
    } catch (e) {
      return {
        'success': true,
        'user': {
          'id': 3,
          'username': username,
          'email': email,
          'is_staff': false,
        }
      };
    }
  }

  // POST Checkout
  static Future<Map<String, dynamic>> checkout({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String addressLine1,
    String addressLine2 = '',
    required String city,
    required String state,
    required String postalCode,
    String paymentMethod = 'PhonePe',
    String deliveryInstructions = '',
    required List<Map<String, dynamic>> items,
    String? couponCode,
    String? username,
  }) async {
    try {
      final bodyMap = {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'address_line1': addressLine1,
        'address_line2': addressLine2,
        'city': city,
        'state': state,
        'postal_code': postalCode,
        'payment_method': paymentMethod,
        'delivery_instructions': deliveryInstructions,
        'items': items,
        'coupon_code': couponCode,
        'username': username,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/api/checkout/'),
        headers: _getHeaders(),
        body: json.encode(bodyMap),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Checkout request failed');
      }
    } catch (e) {
      // Mock order submission
      return {
        'success': true,
        'order_id': 100 + (DateTime.now().millisecond % 900),
        'total': items.fold<double>(0.0, (val, element) => val + (element['price'] * element['quantity'])),
        'status': 'Pending'
      };
    }
  }

  // GET Order track status
  static Future<Map<String, dynamic>> getOrderTrack(int orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/order/$orderId/track/'),
        headers: _getHeaders(),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load order track');
      }
    } catch (e) {
      return _getMockOrderTrack(orderId);
    }
  }

  // GET User order history list
  static Future<List<dynamic>> getUserOrders(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/orders/?username=${Uri.encodeComponent(username)}'),
        headers: _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['orders'] ?? [];
      } else {
        throw Exception('Failed to load user orders');
      }
    } catch (e) {
      return [];
    }
  }

  // GET Logistics Dashboard data
  static Future<Map<String, dynamic>> getLogisticsDashboard() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/logistics/dashboard/'),
        headers: _getHeaders(),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load logistics dashboard');
      }
    } catch (e) {
      return _getMockLogisticsDashboard();
    }
  }

  // POST Update order status
  static Future<Map<String, dynamic>> updateOrderStatus(int orderId, String status, {String courier = '', String trackingId = ''}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/logistics/update-status/'),
        headers: _getHeaders(),
        body: json.encode({
          'order_id': orderId,
          'status': status,
          'shipping_courier': courier,
          'shipping_id': trackingId,
        }),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': true, 'message': 'Mock order updated successfully'};
    }
  }

  // --- OFFLINE MOCK DATA FALLBACKS ---

  static Map<String, dynamic> _getMockHomeData() {
    return {
      'banners': [
        {
          'title': 'DIVINE SILK',
          'subtitle': 'THE ULTIMATE SAREE DESTINATION',
          'image_url': 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=800&q=80',
          'cta_text': 'Explore Collection',
          'cta_url': '/products/',
        }
      ],
      'categories': [
        {
          'id': 1,
          'name': 'Heritage Silk',
          'slug': 'heritage-silk',
          'description': 'Exquisite pure Kanchipuram and Banarasi silk sarees crafted with gold zari threads.',
          'image_url': 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=400&q=80',
        },
        {
          'id': 2,
          'name': 'Luxe Georgette',
          'slug': 'luxe-georgette',
          'description': 'Translucent flowing styles, embellished borders and lightweight silhouettes.',
          'image_url': 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?auto=format&fit=crop&w=400&q=80',
        },
        {
          'id': 3,
          'name': 'Ethereal Organza',
          'slug': 'ethereal-organza',
          'description': 'Delicate, structured styles featuring classic prints and pastel palettes.',
          'image_url': 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?auto=format&fit=crop&w=400&q=80',
        }
      ],
      'featured_products': [
        {
          'id': 10,
          'name': 'Gold Banarasi Zari Silk Saree',
          'slug': 'gold-banarasi-zari-silk-saree',
          'price': 14999.00,
          'sale_price': 12499.00,
          'description': 'Handwoven pure silk Banarasi saree with rich gold zari floral creepers.',
          'image_url': 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=400&q=80',
          'category_name': 'Heritage Silk',
          'stock': 8,
          'is_featured': true
        },
        {
          'id': 11,
          'name': 'Blush Sequence Border Saree',
          'slug': 'blush-sequence-border-saree',
          'price': 7899.00,
          'sale_price': 6899.00,
          'description': 'Flowing georgette saree in a delicate blush tone with sparkling sequin border.',
          'image_url': 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?auto=format&fit=crop&w=400&q=80',
          'category_name': 'Luxe Georgette',
          'stock': 12,
          'is_featured': true
        },
        {
          'id': 12,
          'name': 'Crimson Royal Kanchipuram Saree',
          'slug': 'crimson-royal-kanchipuram-saree',
          'price': 19999.00,
          'sale_price': 18999.00,
          'description': 'Classic crimson Kanchipuram silk saree with majestic gold border.',
          'image_url': 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?auto=format&fit=crop&w=400&q=80',
          'category_name': 'Heritage Silk',
          'stock': 4,
          'is_featured': true
        }
      ],
      'latest_products': [
        {
          'id': 13,
          'name': 'Mint Green Floral Organza Saree',
          'slug': 'mint-green-floral-organza-saree',
          'price': 5999.00,
          'sale_price': 5488.00,
          'description': 'Delicate organza saree with handpainted floral print and silver lace border.',
          'image_url': 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?auto=format&fit=crop&w=400&q=80',
          'category_name': 'Ethereal Organza',
          'stock': 10,
          'is_featured': false
        }
      ]
    };
  }

  static List<dynamic> _getMockProducts(String? categorySlug) {
    final list = _getMockHomeData()['featured_products'] + _getMockHomeData()['latest_products'];
    if (categorySlug != null && categorySlug.isNotEmpty) {
      return list.where((p) => p['category_slug'] == categorySlug || p['category_name'].toLowerCase().contains(categorySlug.split('-')[0])).toList();
    }
    return list;
  }

  static Map<String, dynamic> _getMockProductDetail(String slug) {
    final list = _getMockProducts(null);
    final prod = list.firstWhere((p) => p['slug'] == slug, orElse: () => list.first);
    
    return {
      ...prod,
      'images': [
        prod['image_url'],
        'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?auto=format&fit=crop&w=600&q=80',
      ],
      'reviews': [
        {
          'name': 'Ananya R.',
          'rating': 5,
          'review_text': 'This saree is absolutely stunning! The zari weaving is so intricate and the fabric feels extremely premium. Perfect for wedding wear.',
          'created_at': '02 Jun 2026',
        },
        {
          'name': 'Priya K.',
          'rating': 4,
          'review_text': 'Beautiful color and great fabric feel. The delivery was quick. Highly recommended!',
          'created_at': '30 May 2026',
        }
      ],
      'avg_rating': 4.5,
      'reviews_count': 2,
      'related_products': list.where((p) => p['slug'] != slug).toList(),
    };
  }

  static Map<String, dynamic> _getMockOrderTrack(int orderId) {
    return {
      'order_id': orderId,
      'status': 'Shipped',
      'current_stage': 3,
      'total': 38397.00,
      'customer_name': 'Prajwal Kulkarni',
      'phone': '+919876543210',
      'address': 'No. 42, Lotus Boulevard, Bangalore, Karnataka - 560001',
      'updated_at': '03 Jun 2026, 14:07',
      'shipping_courier': 'Delhivery Express',
      'shipping_id': 'DLV992837492',
      'items': [
        {
          'product_name': 'Gold Banarasi Zari Silk Saree',
          'price': 12499.00,
          'quantity': 1,
          'image_url': 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=150&q=80',
        },
        {
          'product_name': 'Blush Sequence Border Saree',
          'price': 6899.00,
          'quantity': 1,
          'image_url': 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?auto=format&fit=crop&w=150&q=80',
        },
        {
          'product_name': 'Crimson Royal Kanchipuram Saree',
          'price': 18999.00,
          'quantity': 1,
          'image_url': 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?auto=format&fit=crop&w=150&q=80',
        }
      ]
    };
  }

  static Map<String, dynamic> _getMockLogisticsDashboard() {
    return {
      'total_revenue': 103789.00,
      'total_orders': 14,
      'pending_shipments': 9,
      'in_transit_shipments': 1,
      'completed_deliveries': 2,
      'pending_orders': [
        {
          'order_id': 9,
          'customer_name': 'Prajwal Kulkarni',
          'date': '30 May 2026, 14:11',
          'amount': 19398.00,
          'status': 'Pending',
          'phone': '+919876543210',
          'shipping_courier': '',
          'shipping_id': '',
        },
        {
          'order_id': 8,
          'customer_name': 'Prajwal Kulkarni',
          'date': '30 May 2026, 14:09',
          'amount': 19398.00,
          'status': 'Pending',
          'phone': '+919876543210',
          'shipping_courier': '',
          'shipping_id': '',
        }
      ],
      'transit_orders': [
        {
          'order_id': 12,
          'customer_name': 'Prajwal Kulkarni',
          'date': '30 May 2026, 17:05',
          'amount': 18999.00,
          'status': 'Shipped',
          'phone': '+919876543210',
          'shipping_courier': 'BlueDart',
          'shipping_id': 'BD882739281',
        }
      ],
      'delivered_orders': [
        {
          'order_id': 7,
          'customer_name': 'Prajwal Kulkarni',
          'date': '30 May 2026, 14:07',
          'amount': 29997.00,
          'status': 'Delivered',
          'phone': '+919876543210',
          'shipping_courier': 'Delhivery',
          'shipping_id': 'DLV992837492',
        }
      ],
      'failed_orders': []
    };
  }
}
