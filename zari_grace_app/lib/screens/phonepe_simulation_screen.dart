import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../widgets/glass_container.dart';
import 'order_tracking_screen.dart';

class PhonePeSimulationScreen extends StatefulWidget {
  final int orderId;
  final double amount;

  const PhonePeSimulationScreen({
    super.key,
    required this.orderId,
    required this.amount,
  });

  @override
  State<PhonePeSimulationScreen> createState() => _PhonePeSimulationScreenState();
}

class _PhonePeSimulationScreenState extends State<PhonePeSimulationScreen> {
  bool _isPaying = false;
  String _selectedMethod = 'UPI';

  void _pay() {
    setState(() {
      _isPaying = true;
    });

    // Simulate network processing delay
    Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _isPaying = false;
        });

        // Show success sheet/dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF5F259F), // PhonePe Purple
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  child: Icon(Icons.check, color: Color(0xFF5F259F), size: 40),
                ),
                const SizedBox(height: 20),
                const Text(
                  'PAYMENT SUCCESSFUL',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.0),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${widget.amount} Paid successfully',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => OrderTrackingScreen(orderId: widget.orderId),
                    ),
                  );
                },
                child: const Text('VIEW ORDER STATUS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAEAEA), // Lighter grey background to contrast PhonePe card
      appBar: AppBar(
        backgroundColor: const Color(0xFF5F259F), // PhonePe Purple
        title: const Text('PhonePe Secure Pay', style: TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 1.0)),
        centerTitle: false,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                'Merchant ID: ZG_BOUTIQUE',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
              ),
            ),
          )
        ],
      ),
      body: _isPaying
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF5F259F)),
                  SizedBox(height: 16),
                  Text(
                    'Processing Secure Payment...',
                    style: TextStyle(color: Color(0xFF5F259F), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Amount details card
                  Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ORDER REF', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                'ZG-${widget.orderId.toString().padLeft(5, '0')}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('AMOUNT PAYABLE', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                '₹${widget.amount}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF5F259F)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // UPI QR Option
                  Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          value: 'UPI',
                          groupValue: _selectedMethod,
                          activeColor: const Color(0xFF5F259F),
                          onChanged: (val) {
                            setState(() {
                              _selectedMethod = val!;
                            });
                          },
                          title: const Text('UPI QR Code', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                          subtitle: const Text('Scan QR code using any UPI app (PhonePe, GPay, Paytm)', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ),
                        if (_selectedMethod == 'UPI') ...[
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                // Mock QR code container
                                Container(
                                  width: 180,
                                  height: 180,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300, width: 2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Image.network(
                                    'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=upi://pay?pa=zg_boutique@ybl%26am=${widget.amount}%26tr=ZG-${widget.orderId}',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      // Fallback mock QR
                                      return Container(
                                        color: Colors.grey.shade100,
                                        child: const Center(
                                          child: Icon(Icons.qr_code_2, size: 80, color: Colors.grey),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Scan QR to complete transaction',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                )
                              ],
                            ),
                          )
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Card Option
                  Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: RadioListTile<String>(
                      value: 'CARD',
                      groupValue: _selectedMethod,
                      activeColor: const Color(0xFF5F259F),
                      onChanged: (val) {
                        setState(() {
                          _selectedMethod = val!;
                        });
                      },
                      title: const Text('Credit / Debit Card', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                      subtitle: const Text('Visa, Mastercard, RuPay and Maestro accepted', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Pay button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5F259F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _pay,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Pay ₹${widget.amount} Securely',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
