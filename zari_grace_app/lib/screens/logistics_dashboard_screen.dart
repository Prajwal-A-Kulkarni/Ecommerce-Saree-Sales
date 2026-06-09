import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import '../widgets/glass_container.dart';

class LogisticsDashboardScreen extends StatefulWidget {
  const LogisticsDashboardScreen({super.key});

  @override
  State<LogisticsDashboardScreen> createState() => _LogisticsDashboardScreenState();
}

class _LogisticsDashboardScreenState extends State<LogisticsDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<Map<String, dynamic>> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _refreshDashboard();
  }

  void _refreshDashboard() {
    setState(() {
      _dashboardFuture = ApiService.getLogisticsDashboard();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showUpdateStatusDialog(dynamic order) {
    final courierController = TextEditingController(text: order['shipping_courier']);
    final trackingIdController = TextEditingController(text: order['shipping_id']);
    String selectedStatus = order['status'];

    final statusOptions = ['Pending', 'Paid', 'Packed', 'Shipped', 'In Route', 'Delivered', 'Failed'];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: BoutiqueTheme.cardBg,
              title: Text('Process Shipment #ZG-${order['order_id'].toString().padLeft(5, '0')}', style: const TextStyle(color: BoutiqueTheme.textWhite, fontFamily: 'serif')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Update Order Status:', style: TextStyle(color: BoutiqueTheme.textMuted, fontSize: 13)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(8)),
                      child: DropdownButton<String>(
                        value: selectedStatus,
                        dropdownColor: BoutiqueTheme.cardBg,
                        style: const TextStyle(color: BoutiqueTheme.textWhite),
                        underline: const SizedBox(),
                        isExpanded: true,
                        items: statusOptions.map((String opt) {
                          return DropdownMenuItem<String>(
                            value: opt,
                            child: Text(opt),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedStatus = val!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    const Text('Courier Partner:', style: TextStyle(color: BoutiqueTheme.textMuted, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: courierController,
                      style: const TextStyle(color: BoutiqueTheme.textWhite),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Delhivery, BlueDart',
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: BoutiqueTheme.accentGold)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text('Tracking Number:', style: TextStyle(color: BoutiqueTheme.textMuted, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: trackingIdController,
                      style: const TextStyle(color: BoutiqueTheme.textWhite),
                      decoration: const InputDecoration(
                        hintText: 'e.g. TRK1289382',
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: BoutiqueTheme.accentGold)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: BoutiqueTheme.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Updating status...'), duration: Duration(seconds: 1)),
                    );

                    final res = await ApiService.updateOrderStatus(
                      order['order_id'],
                      selectedStatus,
                      courier: courierController.text.trim(),
                      trackingId: trackingIdController.text.trim(),
                    );

                    if (res['success'] == true) {
                      _refreshDashboard();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Order updated successfully!'), backgroundColor: Colors.green),
                        );
                      }
                    }
                  },
                  child: const Text('Update'),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LOGISTICS PORTAL'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BoutiqueTheme.accentGold),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: BoutiqueTheme.accentGold),
            onPressed: _refreshDashboard,
          )
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: BoutiqueTheme.accentGold));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
          }

          final data = snapshot.data ?? {};
          final totalRev = data['total_revenue'] ?? 0.0;
          final totalOrders = data['total_orders'] ?? 0;
          final pendingCount = data['pending_shipments'] ?? 0;
          final transitCount = data['in_transit_shipments'] ?? 0;
          final deliveredCount = data['completed_deliveries'] ?? 0;

          final pendingOrders = data['pending_orders'] ?? [];
          final transitOrders = data['transit_orders'] ?? [];
          final deliveredOrders = data['delivered_orders'] ?? [];
          final failedOrders = data['failed_orders'] ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Stats Grid
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('Net Revenue', '₹$totalRev', Icons.currency_rupee)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('Total Orders', '$totalOrders', Icons.list_alt)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('In Transit', '$transitCount', Icons.local_shipping)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('Completed', '$deliveredCount', Icons.check_circle_outline)),
                      ],
                    ),
                  ],
                ),
              ),

              // TabBar
              TabBar(
                controller: _tabController,
                indicatorColor: BoutiqueTheme.accentGold,
                labelColor: BoutiqueTheme.accentGold,
                unselectedLabelColor: BoutiqueTheme.textMuted,
                tabs: [
                  Tab(text: 'Needs Proc (${pendingOrders.length})'),
                  Tab(text: 'Transit (${transitOrders.length})'),
                  Tab(text: 'Delivered (${deliveredOrders.length})'),
                  Tab(text: 'Failed (${failedOrders.length})'),
                ],
              ),
              const SizedBox(height: 12),

              // Tab View
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOrdersTab(pendingOrders),
                    _buildOrdersTab(transitOrders),
                    _buildOrdersTab(deliveredOrders),
                    _buildOrdersTab(failedOrders),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String val, IconData icon) {
    return GlassContainer(
      opacity: 0.06,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: BoutiqueTheme.accentGold.withOpacity(0.12),
            radius: 20,
            child: Icon(icon, color: BoutiqueTheme.accentGold, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: BoutiqueTheme.textMuted, fontSize: 10)),
                const SizedBox(height: 4),
                Text(
                  val,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BoutiqueTheme.textWhite),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOrdersTab(List<dynamic> ordersList) {
    if (ordersList.isEmpty) {
      return const Center(child: Text('No orders in this stage.', style: TextStyle(color: BoutiqueTheme.textMuted)));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: ordersList.length,
      itemBuilder: (context, index) {
        final order = ordersList[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GlassContainer(
            opacity: 0.05,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#ZG-${order['order_id'].toString().padLeft(5, '0')}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: BoutiqueTheme.textWhite),
                    ),
                    Text(
                      order['date'],
                      style: const TextStyle(color: BoutiqueTheme.textMuted, fontSize: 11),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order['customer_name'], style: const TextStyle(fontWeight: FontWeight.bold, color: BoutiqueTheme.textWhite, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text('Phone: ${order['phone']}', style: const TextStyle(color: BoutiqueTheme.textMuted, fontSize: 11)),
                      ],
                    ),
                    Text(
                      '₹${order['amount']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: BoutiqueTheme.accentGold, fontSize: 16),
                    )
                  ],
                ),
                
                if (order['shipping_courier'].toString().isNotEmpty) ...[
                  const Divider(color: Colors.white12, height: 20),
                  Text(
                    'Courier: ${order['shipping_courier']} (${order['shipping_id']})',
                    style: const TextStyle(color: BoutiqueTheme.accentGold, fontSize: 11),
                  ),
                ],

                const Divider(color: Colors.white12, height: 20),
                
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: const Size(double.infinity, 32),
                  ),
                  onPressed: () => _showUpdateStatusDialog(order),
                  child: const Text('PROCESS SHIPMENT', style: TextStyle(fontSize: 12)),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
