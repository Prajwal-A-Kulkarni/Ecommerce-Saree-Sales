import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/theme.dart';
import '../widgets/glass_container.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _couponController = TextEditingController();
  double _discount = 0.00;
  String _appliedCoupon = '';
  String _couponError = '';

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _applyCoupon(double subtotal) {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _couponError = '';
    });

    if (code == 'FIRST10') {
      setState(() {
        _discount = subtotal * 0.10;
        _appliedCoupon = 'FIRST10';
        _couponController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('FIRST10 (10% off) applied successfully!'), backgroundColor: Colors.green),
      );
    } else if (code == 'SAREE500') {
      setState(() {
        _discount = 500.00;
        _appliedCoupon = 'SAREE500';
        _couponController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SAREE500 (₹500 off) applied successfully!'), backgroundColor: Colors.green),
      );
    } else {
      setState(() {
        _couponError = 'Invalid coupon code.';
      });
    }
  }

  void _removeCoupon() {
    setState(() {
      _discount = 0.00;
      _appliedCoupon = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final cartItems = provider.cart;
    final subtotal = provider.cartSubtotal;
    final finalTotal = (subtotal - _discount) < 0 ? 0.00 : (subtotal - _discount);

    return Scaffold(
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 64, color: BoutiqueTheme.accentGold.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  const Text(
                    'Your shopping bag is empty',
                    style: TextStyle(color: BoutiqueTheme.textWhite, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'serif'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Explore our gorgeous sarees and fill your bag!',
                    style: TextStyle(color: BoutiqueTheme.textMuted, fontSize: 13),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Cart Items List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      final prod = item['product'];
                      final qty = item['quantity'] as int;
                      final price = prod['sale_price'] ?? prod['price'];
                      final itemTotal = price * qty;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: GlassContainer(
                          opacity: 0.06,
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  prod['image_url'],
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      prod['name'],
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: BoutiqueTheme.textWhite),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₹$price each',
                                      style: const TextStyle(color: BoutiqueTheme.textMuted, fontSize: 12),
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // Quantity Controls
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                provider.updateCartQty(prod['id'], qty - 1);
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(4)),
                                                child: const Icon(Icons.remove, size: 14, color: BoutiqueTheme.textWhite),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, color: BoutiqueTheme.textWhite)),
                                            const SizedBox(width: 12),
                                            GestureDetector(
                                              onTap: () {
                                                provider.updateCartQty(prod['id'], qty + 1);
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(4)),
                                                child: const Icon(Icons.add, size: 14, color: BoutiqueTheme.textWhite),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '₹$itemTotal',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: BoutiqueTheme.accentGold, fontSize: 14),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Remove Button
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () {
                                  provider.removeFromCart(prod['id']);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Pricing and Coupon summary
                GlassContainer(
                  opacity: 0.12,
                  radius: 0,
                  borderColor: Colors.transparent,
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Coupon code row
                      if (_appliedCoupon.isEmpty)
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _couponController,
                                style: const TextStyle(color: BoutiqueTheme.textWhite),
                                decoration: InputDecoration(
                                  hintText: 'Enter coupon (e.g. FIRST10)',
                                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                                  errorText: _couponError.isEmpty ? null : _couponError,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                minimumSize: const Size(60, 36),
                              ),
                              onPressed: () => _applyCoupon(subtotal),
                              child: const Text('APPLY', style: TextStyle(fontSize: 12)),
                            )
                          ],
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.confirmation_number, color: Colors.green, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Coupon $_appliedCoupon applied',
                                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: _removeCoupon,
                              child: const Text('REMOVE', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                            )
                          ],
                        ),
                      const SizedBox(height: 16),

                      // Totals breakdown
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal', style: TextStyle(color: BoutiqueTheme.textMuted)),
                          Text('₹$subtotal', style: const TextStyle(color: BoutiqueTheme.textWhite)),
                        ],
                      ),
                      if (_discount > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Discount', style: TextStyle(color: Colors.green)),
                            Text('-₹$_discount', style: const TextStyle(color: Colors.green)),
                          ],
                        ),
                      ],
                      const Divider(height: 24, color: Colors.white24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BoutiqueTheme.textWhite),
                          ),
                          Text(
                            '₹$finalTotal',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: BoutiqueTheme.accentGold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Checkout button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CheckoutScreen(
                                couponCode: _appliedCoupon,
                                discountAmount: _discount,
                              ),
                            ),
                          );
                        },
                        child: const Text('PROCEED TO CHECKOUT'),
                      )
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
