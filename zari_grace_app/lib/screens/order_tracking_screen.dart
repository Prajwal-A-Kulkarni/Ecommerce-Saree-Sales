import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/gradient_background.dart';
import 'main_navigation.dart';

class OrderTrackingScreen extends StatefulWidget {
  final int orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late Future<Map<String, dynamic>> _trackFuture;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  void _refreshStatus() {
    setState(() {
      _trackFuture = ApiService.getOrderTrack(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('ORDER STATUS'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: BoutiqueTheme.accentGold),
              onPressed: _refreshStatus,
            )
          ],
        ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _trackFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: BoutiqueTheme.accentGold));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading tracking info: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final order = snapshot.data ?? {};
          final currentStage = order['current_stage'] as int? ?? 1;
          final status = order['status'] as String? ?? 'Pending';
          final courier = order['shipping_courier'] as String? ?? 'Pending';
          final trackingId = order['shipping_id'] as String? ?? 'Pending';
          final items = order['items'] as List<dynamic>? ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header details
                GlassContainer(
                  opacity: 0.05,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order ID: #ZG-${widget.orderId.toString().padLeft(5, '0')}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BoutiqueTheme.textWhite),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: BoutiqueTheme.accentGold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: const TextStyle(color: BoutiqueTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Placed on: ${order['updated_at']}', style: const TextStyle(color: BoutiqueTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 5-Stage status timeline pipeline
                const Text(
                  'DELIVERY PROGRESS',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: BoutiqueTheme.accentGold, fontFamily: 'serif'),
                ),
                const SizedBox(height: 16),
                
                GlassContainer(
                  opacity: 0.05,
                  child: Column(
                    children: [
                      _buildStageItem(1, 'PLACED', 'We have received your order.', currentStage >= 1),
                      _buildLine(currentStage >= 2),
                      _buildStageItem(2, 'PACKED', 'Saree is packed & ready for shipment.', currentStage >= 2),
                      _buildLine(currentStage >= 3),
                      _buildStageItem(3, 'SHIPPED', 'Handed over to delivery courier.', currentStage >= 3),
                      _buildLine(currentStage >= 4),
                      _buildStageItem(4, 'IN ROUTE', 'Package is out for local delivery.', currentStage >= 4),
                      _buildLine(currentStage >= 5),
                      _buildStageItem(5, 'DELIVERED', 'Package successfully delivered.', currentStage >= 5),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Logistics & Courier details if shipped
                if (currentStage >= 3) ...[
                  const Text(
                    'SHIPPING INFORMATION',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: BoutiqueTheme.accentGold, fontFamily: 'serif'),
                  ),
                  const SizedBox(height: 12),
                  GlassContainer(
                    opacity: 0.05,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Courier Partner:', style: TextStyle(color: BoutiqueTheme.textMuted, fontSize: 13)),
                            Text(courier, style: const TextStyle(fontWeight: FontWeight.bold, color: BoutiqueTheme.textWhite, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tracking Number:', style: TextStyle(color: BoutiqueTheme.textMuted, fontSize: 13)),
                            Text(trackingId, style: const TextStyle(fontWeight: FontWeight.bold, color: BoutiqueTheme.accentGold, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Items list summary
                const Text(
                  'ITEMS ORDERED',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: BoutiqueTheme.accentGold, fontFamily: 'serif'),
                ),
                const SizedBox(height: 12),
                
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, idx) {
                    final item = items[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: GlassContainer(
                        opacity: 0.03,
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            if (item['image_url'].toString().isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  ApiService.resolveImageUrl(item['image_url']),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              Container(width: 50, height: 50, color: Colors.white12, child: const Icon(Icons.image, size: 20)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['product_name'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: BoutiqueTheme.textWhite),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Qty: ${item['quantity']}  •  ₹${item['price']}',
                                    style: const TextStyle(color: BoutiqueTheme.textMuted, fontSize: 11),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const MainNavigation()),
                      (route) => false,
                    );
                  },
                  child: const Text('CONTINUE SHOPPING'),
                )
              ],
            ),
          );
        },
      ),
    ),
  );
}

  Widget _buildStageItem(int stageNumber, String title, String subtitle, bool isCompleted) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isCompleted ? BoutiqueTheme.accentGold : Colors.white12,
          child: isCompleted
              ? const Icon(Icons.check, size: 14, color: BoutiqueTheme.primaryBg)
              : Text('$stageNumber', style: const TextStyle(fontSize: 10, color: Colors.white30)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isCompleted ? BoutiqueTheme.accentGold : Colors.white30,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isCompleted ? BoutiqueTheme.textMuted : Colors.white24,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildLine(bool isActive) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 2,
        height: 24,
        margin: const EdgeInsets.only(left: 11),
        color: isActive ? BoutiqueTheme.accentGold : Colors.white12,
      ),
    );
  }
}
