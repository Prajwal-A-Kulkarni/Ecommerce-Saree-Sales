import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import '../widgets/glass_container.dart';
import 'product_detail_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final wishlist = provider.wishlist;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: wishlist.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: BoutiqueTheme.accentGold.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  const Text(
                    'Your wishlist is empty',
                    style: TextStyle(color: BoutiqueTheme.textWhite, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'serif'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Save your favorite luxury sarees here',
                    style: TextStyle(color: BoutiqueTheme.textMuted, fontSize: 13),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: wishlist.length,
              itemBuilder: (context, index) {
                final prod = wishlist[index];
                final hasSalePrice = prod['sale_price'] != null;
                final displayPrice = hasSalePrice ? prod['sale_price'] : prod['price'];

                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ProductDetailScreen(slug: prod['slug'])),
                    );
                  },
                  child: GlassContainer(
                    opacity: 0.06,
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Image with delete button
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: Image.network(
                                  ApiService.resolveImageUrl(prod['image_url']),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    provider.toggleWishlist(prod);
                                  },
                                  child: CircleAvatar(
                                    backgroundColor: BoutiqueTheme.primaryBg.withOpacity(0.6),
                                    radius: 16,
                                    child: const Icon(
                                      Icons.close,
                                      color: BoutiqueTheme.accentGold,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Details
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                prod['name'],
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: BoutiqueTheme.textWhite,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                prod['category_name'] ?? 'Saree',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: BoutiqueTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    '₹$displayPrice',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: BoutiqueTheme.accentGold,
                                    ),
                                  ),
                                  if (hasSalePrice) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '₹${prod['price']}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: BoutiqueTheme.textMuted,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ],
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
    );
  }
}
