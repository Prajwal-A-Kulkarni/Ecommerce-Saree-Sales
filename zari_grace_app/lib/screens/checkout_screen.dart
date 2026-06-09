import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/gradient_background.dart';
import 'phonepe_simulation_screen.dart';
import 'order_tracking_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final String couponCode;
  final double discountAmount;

  const CheckoutScreen({
    super.key,
    this.couponCode = '',
    this.discountAmount = 0.00,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _instructionsController = TextEditingController();

  String _paymentMethod = 'PhonePe';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate with dummy user details for convenience
    _firstNameController.text = 'Prajwal';
    _lastNameController.text = 'Kulkarni';
    _emailController.text = 'k.prajwal@gmail.com';
    _phoneController.text = '+919876543210';
    _addressController.text = 'No. 42, Lotus Boulevard';
    _cityController.text = 'Bangalore';
    _stateController.text = 'Karnataka';
    _zipController.text = '560001';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _submitCheckout() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<AppProvider>(context, listen: false);
    final itemsList = provider.cart.map((item) {
      final price = item['product']['sale_price'] ?? item['product']['price'];
      return {
        'product_id': item['product']['id'],
        'quantity': item['quantity'],
        'price': price,
      };
    }).toList();

    final response = await ApiService.checkout(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      addressLine1: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      postalCode: _zipController.text.trim(),
      paymentMethod: _paymentMethod,
      deliveryInstructions: _instructionsController.text.trim(),
      items: itemsList,
      couponCode: widget.couponCode,
      username: provider.username,
    );

    setState(() {
      _isLoading = false;
    });

    if (response['success'] == true) {
      final orderId = response['order_id'];
      final finalAmount = response['total'] ?? provider.cartSubtotal - widget.discountAmount;

      // Clear Cart state in app
      await provider.clearCart();

      if (_paymentMethod == 'PhonePe' && mounted) {
        // Redirect to PhonePe simulator screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PhonePeSimulationScreen(
              orderId: orderId,
              amount: finalAmount,
            ),
          ),
        );
      } else {
        // COD checkout successful
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => OrderTrackingScreen(orderId: orderId),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checkout failed: ${response['message'] ?? 'Unknown error'}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('CHECKOUT'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: BoutiqueTheme.accentGold),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: BoutiqueTheme.accentGold))
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'DELIVERY DETAILS',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: BoutiqueTheme.accentGold, fontFamily: 'serif'),
                      ),
                      const SizedBox(height: 12),
                      
                      GlassContainer(
                        opacity: 0.05,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _firstNameController,
                                    style: const TextStyle(color: BoutiqueTheme.textWhite),
                                    decoration: const InputDecoration(labelText: 'First Name', labelStyle: TextStyle(color: BoutiqueTheme.textMuted)),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _lastNameController,
                                    style: const TextStyle(color: BoutiqueTheme.textWhite),
                                    decoration: const InputDecoration(labelText: 'Last Name', labelStyle: TextStyle(color: BoutiqueTheme.textMuted)),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _emailController,
                              style: const TextStyle(color: BoutiqueTheme.textWhite),
                              decoration: const InputDecoration(labelText: 'Email Address', labelStyle: TextStyle(color: BoutiqueTheme.textMuted)),
                              validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phoneController,
                              style: const TextStyle(color: BoutiqueTheme.textWhite),
                              decoration: const InputDecoration(labelText: 'Mobile Phone', labelStyle: TextStyle(color: BoutiqueTheme.textMuted)),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _addressController,
                              style: const TextStyle(color: BoutiqueTheme.textWhite),
                              decoration: const InputDecoration(labelText: 'Address Line 1', labelStyle: TextStyle(color: BoutiqueTheme.textMuted)),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _cityController,
                                    style: const TextStyle(color: BoutiqueTheme.textWhite),
                                    decoration: const InputDecoration(labelText: 'City', labelStyle: TextStyle(color: BoutiqueTheme.textMuted)),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _stateController,
                                    style: const TextStyle(color: BoutiqueTheme.textWhite),
                                    decoration: const InputDecoration(labelText: 'State', labelStyle: TextStyle(color: BoutiqueTheme.textMuted)),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _zipController,
                                    style: const TextStyle(color: BoutiqueTheme.textWhite),
                                    decoration: const InputDecoration(labelText: 'PIN Code', labelStyle: TextStyle(color: BoutiqueTheme.textMuted)),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _instructionsController,
                              style: const TextStyle(color: BoutiqueTheme.textWhite),
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Delivery Instructions (Optional)',
                                labelStyle: TextStyle(color: BoutiqueTheme.textMuted),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Payment Method selector
                      const Text(
                        'PAYMENT METHOD',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: BoutiqueTheme.accentGold, fontFamily: 'serif'),
                      ),
                      const SizedBox(height: 12),
                      
                      GlassContainer(
                        opacity: 0.05,
                        child: Column(
                          children: [
                            RadioListTile<String>(
                              value: 'PhonePe',
                              groupValue: _paymentMethod,
                              onChanged: (val) {
                                setState(() {
                                  _paymentMethod = val!;
                                });
                              },
                              title: const Text('PhonePe Secure Pay', style: TextStyle(color: BoutiqueTheme.textWhite, fontWeight: FontWeight.bold)),
                              subtitle: const Text('Pay instantly with UPI, Cards, or Wallet', style: TextStyle(color: BoutiqueTheme.textMuted, fontSize: 11)),
                              activeColor: BoutiqueTheme.accentGold,
                            ),
                            const Divider(color: Colors.white12, indent: 16, endIndent: 16),
                            RadioListTile<String>(
                              value: 'COD',
                              groupValue: _paymentMethod,
                              onChanged: (val) {
                                setState(() {
                                  _paymentMethod = val!;
                                });
                              },
                              title: const Text('Cash on Delivery (COD)', style: TextStyle(color: BoutiqueTheme.textWhite, fontWeight: FontWeight.bold)),
                              subtitle: const Text('Pay when the package reaches your doorstep', style: TextStyle(color: BoutiqueTheme.textMuted, fontSize: 11)),
                              activeColor: BoutiqueTheme.accentGold,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      ElevatedButton(
                        onPressed: _submitCheckout,
                        child: const Text('PLACE ORDER NOW'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
