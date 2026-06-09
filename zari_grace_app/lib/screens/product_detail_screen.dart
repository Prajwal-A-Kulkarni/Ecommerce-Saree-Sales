import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/gradient_background.dart';

class ProductDetailScreen extends StatefulWidget {
  final String slug;
  const ProductDetailScreen({super.key, required this.slug});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<Map<String, dynamic>> _detailFuture;
  int _quantity = 1;
  int _activeImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  void _loadDetails() {
    setState(() {
      _detailFuture = ApiService.getProductDetail(widget.slug);
      _quantity = 1;
      _activeImageIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('SAREE DETAIL'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: BoutiqueTheme.accentGold),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: BoutiqueTheme.accentGold));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading details: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final product = snapshot.data ?? {};
          final images = (product['images'] as List<dynamic>?)?.cast<String>() ?? [product['image_url']];
          final reviews = product['reviews'] ?? [];
          final related = product['related_products'] ?? [];
          final hasSalePrice = product['sale_price'] != null;
          final displayPrice = hasSalePrice ? product['sale_price'] : product['price'];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image gallery swiper
                SizedBox(
                  height: 380,
                  child: Stack(
                    children: [
                      PageView.builder(
                        itemCount: images.length,
                        onPageChanged: (idx) {
                          setState(() {
                            _activeImageIndex = idx;
                          });
                        },
                        itemBuilder: (context, idx) {
                          return Image.network(
                            ApiService.resolveImageUrl(images[idx]),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          );
                        },
                      ),
                      
                      // Indicators overlay
                      if (images.length > 1)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(images.length, (idx) {
                              final isActive = _activeImageIndex == idx;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: isActive ? 24 : 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: isActive ? BoutiqueTheme.accentGold : Colors.white24,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Details Card Overlay
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              product['name'],
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          
                          // Rating Badge
                          Row(
                            children: [
                              const Icon(Icons.star, color: BoutiqueTheme.accentGold, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${product['avg_rating']}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: BoutiqueTheme.textWhite),
                              ),
                              Text(
                                ' (${product['reviews_count']})',
                                style: const TextStyle(color: BoutiqueTheme.textMuted, fontSize: 12),
                              )
                            ],
                          )
                        ],
                      ),
                      
                      const SizedBox(height: 6),
                      Text(
                        'CATEGORY: ${product['category_name'].toString().toUpperCase()}',
                        style: const TextStyle(color: BoutiqueTheme.accentGold, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 12),

                      // Pricing & Stock
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹$displayPrice',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: BoutiqueTheme.accentGold,
                                ),
                              ),
                              if (hasSalePrice) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '₹${product['price']}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: BoutiqueTheme.textMuted,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          
                          // Stock Indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: product['stock'] > 0 ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              product['stock'] > 0 ? 'In Stock (${product['stock']})' : 'Out of Stock',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: product['stock'] > 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          )
                        ],
                      ),
                      const Divider(height: 32, color: Colors.white12),

                      // Weave Description
                      const Text(
                        'ABOUT THE WEAVE',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: BoutiqueTheme.textWhite,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product['description'],
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      
                      const Divider(height: 32, color: Colors.white12),

                      // Quantity Selector & Add to Cart Action
                      Row(
                        children: [
                          // Qty Selector
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white24),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 18),
                                  onPressed: () {
                                    if (_quantity > 1) {
                                      setState(() {
                                        _quantity--;
                                      });
                                    }
                                  },
                                ),
                                Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 18),
                                  onPressed: () {
                                    if (_quantity < product['stock']) {
                                      setState(() {
                                        _quantity++;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Add to Cart button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: product['stock'] > 0
                                  ? () async {
                                      await provider.addToCart(product, quantity: _quantity);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('$_quantity x ${product['name']} added to cart!'),
                                            backgroundColor: BoutiqueTheme.cardBg,
                                          ),
                                        );
                                      }
                                    }
                                  : null,
                              child: const Text('ADD TO BAG'),
                            ),
                          )
                        ],
                      ),
                      const Divider(height: 32, color: Colors.white12),

                      // Reviews List
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'CUSTOMER REVIEWS',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: BoutiqueTheme.textWhite,
                            ),
                          ),
                          Text(
                            '${reviews.length} reviews',
                            style: const TextStyle(color: BoutiqueTheme.accentGold, fontSize: 12),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildReviewsList(reviews),
                      const Divider(height: 32, color: Colors.white12),

                      // Related Products section
                      if (related.isNotEmpty) ...[
                        const Text(
                          'RELATED SAREES',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: BoutiqueTheme.textWhite,
                            fontFamily: 'serif',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildRelatedList(related),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

  Widget _buildReviewsList(List<dynamic> reviews) {
    if (reviews.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('No reviews yet. Be the first to review!', style: TextStyle(color: BoutiqueTheme.textMuted, fontSize: 12)),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reviews.length,
      itemBuilder: (context, idx) {
        final rev = reviews[idx];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GlassContainer(
            opacity: 0.04,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(rev['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Row(
                      children: List.generate(5, (starIdx) {
                        return Icon(
                          Icons.star,
                          size: 12,
                          color: starIdx < rev['rating'] ? BoutiqueTheme.accentGold : Colors.white12,
                        );
                      }),
                    )
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  rev['review_text'],
                  style: const TextStyle(fontSize: 12, color: BoutiqueTheme.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  rev['created_at'],
                  style: const TextStyle(fontSize: 9, color: Colors.white24),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRelatedList(List<dynamic> related) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: related.length,
        itemBuilder: (context, idx) {
          final rp = related[idx];
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ProductDetailScreen(slug: rp['slug'])),
              );
            },
            child: Container(
              width: 120,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      ApiService.resolveImageUrl(rp['image_url']),
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    rp['name'],
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: BoutiqueTheme.textWhite),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '₹${rp['price']}',
                    style: const TextStyle(fontSize: 11, color: BoutiqueTheme.accentGold, fontWeight: FontWeight.bold),
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
