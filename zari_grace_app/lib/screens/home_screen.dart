import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import '../widgets/glass_container.dart';
import 'product_detail_screen.dart';
import 'browse_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, dynamic>> _homeDataFuture;

  @override
  void initState() {
    super.initState();
    _refreshHomeData();
  }

  void _refreshHomeData() {
    setState(() {
      _homeDataFuture = ApiService.getHomeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshHomeData();
        },
        color: BoutiqueTheme.accentGold,
        backgroundColor: BoutiqueTheme.cardBg,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _homeDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: BoutiqueTheme.accentGold));
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading data: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            }

            final data = snapshot.data ?? {};
            final banners = data['banners'] ?? [];
            final categories = data['categories'] ?? [];
            final featured = data['featured_products'] ?? [];
            final latest = data['latest_products'] ?? [];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome announcement banner
                  _buildMarqueeAnnouncement(),
                  const SizedBox(height: 16),

                  // Hero Banner
                  if (banners.isNotEmpty) _buildHeroBanner(banners[0]),
                  const SizedBox(height: 24),

                  // Shop by Category section
                  const Text(
                    'SHOP BY CATEGORY',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      fontFamily: 'serif',
                      color: BoutiqueTheme.accentGold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryList(categories),
                  const SizedBox(height: 28),

                  // Featured Sarees section
                  const Text(
                    'FEATURED SAREES',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      fontFamily: 'serif',
                      color: BoutiqueTheme.accentGold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildProductHorizontalList(featured, provider),
                  const SizedBox(height: 28),

                  // Latest Collection section
                  const Text(
                    'LATEST ARRIVALS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      fontFamily: 'serif',
                      color: BoutiqueTheme.accentGold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildProductHorizontalList(latest, provider),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMarqueeAnnouncement() {
    return GlassContainer(
      opacity: 0.05,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      radius: 8,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star, color: BoutiqueTheme.accentGold, size: 16),
          SizedBox(width: 8),
          Text(
            '10% OFF ON FIRST PURCHASE - CODE: FIRST10',
            style: TextStyle(
              color: BoutiqueTheme.textWhite,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          SizedBox(width: 8),
          Icon(Icons.star, color: BoutiqueTheme.accentGold, size: 16),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(dynamic banner) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BrowseScreen()),
        );
      },
      child: Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: NetworkImage(ApiService.resolveImageUrl(banner['image_url'])),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: BoutiqueTheme.accentGold.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Dark gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomRight,
                    end: Alignment.topLeft,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.15),
                    ],
                  ),
                ),
              ),
              
              // Floating Glassmorphic Container
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: GlassContainer(
                  blur: 20.0,
                  opacity: 0.12,
                  radius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  borderColor: BoutiqueTheme.accentGold.withOpacity(0.2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        banner['title'].toString().toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                          color: BoutiqueTheme.textWhite,
                          fontFamily: 'serif',
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              offset: Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        banner['subtitle'],
                        style: const TextStyle(
                          fontSize: 10,
                          letterSpacing: 0.8,
                          color: BoutiqueTheme.textMuted,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: BoutiqueTheme.accentGold,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: BoutiqueTheme.accentGold.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  banner['cta_text'].toString().toUpperCase(),
                                  style: const TextStyle(
                                    color: BoutiqueTheme.primaryBg,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_rounded, size: 10, color: BoutiqueTheme.primaryBg),
                              ],
                            ),
                          ),
                          
                          // Glass luxury tag
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: const Text(
                              'LIMITED EDITION',
                              style: TextStyle(
                                color: BoutiqueTheme.accentGold,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList(List<dynamic> categories) {
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => BrowseScreen(categorySlug: cat['slug'])),
              );
            },
            child: Container(
              width: 130,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(ApiService.resolveImageUrl(cat['image_url'])),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          BoutiqueTheme.primaryBg.withOpacity(0.8),
                          BoutiqueTheme.primaryBg.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 8,
                    right: 8,
                    child: Text(
                      cat['name'],
                      style: const TextStyle(
                        color: BoutiqueTheme.textWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        fontFamily: 'serif',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductHorizontalList(List<dynamic> products, AppProvider provider) {
    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        itemBuilder: (context, index) {
          final prod = products[index];
          final hasSalePrice = prod['sale_price'] != null;
          final displayPrice = hasSalePrice ? prod['sale_price'] : prod['price'];
          final isWishlisted = provider.isInWishlist(prod['id']);

          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ProductDetailScreen(slug: prod['slug'])),
              );
            },
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 16),
              child: GlassContainer(
                opacity: 0.06,
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product image & wishlist button
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image.network(
                            ApiService.resolveImageUrl(prod['image_url']),
                            height: 150,
                            width: 160,
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
                              child: Icon(
                                isWishlisted ? Icons.favorite : Icons.favorite_border,
                                color: isWishlisted ? Colors.red : BoutiqueTheme.accentGold,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Product info
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prod['name'],
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: BoutiqueTheme.textWhite,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '₹$displayPrice',
                                style: const TextStyle(
                                  fontSize: 13,
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
                              ]
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
