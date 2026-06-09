import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/gradient_background.dart';
import 'order_tracking_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  late Future<List<dynamic>> _ordersFuture;
  final _emailController = TextEditingController();
  bool _isGuestMode = false;
  String _guestEmail = '';

  @override
  void initState() {
    super.initState();
    _refreshOrders();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _refreshOrders() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    setState(() {
      if (provider.isLoggedIn) {
        _ordersFuture = ApiService.getUserOrders(provider.username);
        _isGuestMode = false;
      } else if (_guestEmail.isNotEmpty) {
        _ordersFuture = ApiService.getUserOrders(_guestEmail);
        _isGuestMode = true;
      } else {
        _ordersFuture = Future.value([]);
        _isGuestMode = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('MY ORDERS'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: BoutiqueTheme.accentGold),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: BoutiqueTheme.accentGold),
              onPressed: _refreshOrders,
            ),
          ],
        ),
        body: Column(
          children: [
            // If guest/anonymous user, show email query input
            if (!provider.isLoggedIn)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GlassContainer(
                  opacity: 0.06,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _emailController,
                          style: const TextStyle(color: BoutiqueTheme.textWhite),
                          decoration: const InputDecoration(
                            hintText: 'Enter checkout email to find orders...',
                            hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: const Size(60, 36),
                        ),
                        onPressed: () {
                          if (_emailController.text.trim().isNotEmpty) {
                            setState(() {
                              _guestEmail = _emailController.text.trim();
                            });
                            _refreshOrders();
                          }
                        },
                        child: const Text('FIND', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),

            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _ordersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: BoutiqueTheme.accentGold));
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading orders: ${snapshot.error}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    );
                  }

                  final orders = snapshot.data ?? [];

                  if (orders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: BoutiqueTheme.accentGold.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            !provider.isLoggedIn && _guestEmail.isEmpty
                                ? 'Enter your email above to track orders'
                                : 'No orders found',
                            style: const TextStyle(
                              color: BoutiqueTheme.textWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'serif',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            !provider.isLoggedIn && _guestEmail.isEmpty
                                ? 'Guest checkouts are searchable by email'
                                : 'Try another email or make a purchase!',
                            style: const TextStyle(color: BoutiqueTheme.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final orderId = order['order_id'];
                      final status = order['status'] as String? ?? 'Pending';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => OrderTrackingScreen(orderId: orderId),
                              ),
                            );
                          },
                          child: GlassContainer(
                            opacity: 0.05,
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: BoutiqueTheme.accentGold.withOpacity(0.1),
                                  radius: 22,
                                  child: const Icon(
                                    Icons.shopping_bag_rounded,
                                    color: BoutiqueTheme.accentGold,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Order #ZG-${orderId.toString().padLeft(5, '0')}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: BoutiqueTheme.textWhite,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Placed on: ${order['date']}',
                                        style: const TextStyle(
                                          color: BoutiqueTheme.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${order['items_count']} item(s)',
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${order['amount']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: BoutiqueTheme.accentGold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: BoutiqueTheme.accentGold.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: const TextStyle(
                                          color: BoutiqueTheme.accentGold,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
