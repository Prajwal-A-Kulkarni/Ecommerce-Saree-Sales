import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import '../widgets/glass_container.dart';
import 'product_detail_screen.dart';

class BrowseScreen extends StatefulWidget {
  final String? categorySlug;
  const BrowseScreen({super.key, this.categorySlug});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final _searchController = TextEditingController();
  
  String _selectedCategorySlug = '';
  String _selectedSortBy = 'newest';
  
  double? _minPrice;
  double? _maxPrice;
  
  List<dynamic> _products = [];
  bool _isLoading = true;

  final List<Map<String, String>> _categories = [
    {'name': 'All', 'slug': ''},
    {'name': 'Heritage Silk', 'slug': 'heritage-silk'},
    {'name': 'Luxe Georgette', 'slug': 'luxe-georgette'},
    {'name': 'Ethereal Organza', 'slug': 'ethereal-organza'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.categorySlug != null) {
      _selectedCategorySlug = widget.categorySlug!;
    }
    _loadProducts();
  }

  void _loadProducts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final res = await ApiService.getProducts(
        categorySlug: _selectedCategorySlug,
        searchQuery: _searchController.text.trim(),
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        sortBy: _selectedSortBy,
      );
      if (mounted) {
        setState(() {
          _products = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: BoutiqueTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SORT BY',
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold, 
                  color: BoutiqueTheme.accentGold,
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(height: 16),
              _buildSortOptionItem('Newest Arrivals', 'newest'),
              _buildSortOptionItem('Price: Low to High', 'price_low'),
              _buildSortOptionItem('Price: High to Low', 'price_high'),
              _buildSortOptionItem('Popular & Featured', 'popular'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOptionItem(String title, String value) {
    final isSelected = _selectedSortBy == value;
    return ListTile(
      title: Text(
        title, 
        style: TextStyle(color: isSelected ? BoutiqueTheme.accentGold : BoutiqueTheme.textWhite),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: BoutiqueTheme.accentGold) : null,
      onTap: () {
        setState(() {
          _selectedSortBy = value;
        });
        Navigator.pop(context);
        _loadProducts();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      body: Column(
        children: [
          // Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: GlassContainer(
                    opacity: 0.05,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    radius: 12,
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: BoutiqueTheme.textWhite, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Search sarees...',
                        hintStyle: TextStyle(color: Colors.white24),
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: BoutiqueTheme.accentGold, size: 20),
                      ),
                      onSubmitted: (_) => _loadProducts(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _showSortOptions,
                  child: GlassContainer(
                    opacity: 0.05,
                    padding: const EdgeInsets.all(12),
                    radius: 12,
                    child: const Icon(Icons.sort, color: BoutiqueTheme.accentGold),
                  ),
                ),
              ],
            ),
          ),

          // Categories Tags
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategorySlug == cat['slug'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      cat['name']!,
                      style: TextStyle(
                        color: isSelected ? BoutiqueTheme.primaryBg : BoutiqueTheme.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategorySlug = cat['slug']!;
                      });
                      _loadProducts();
                    },
                    selectedColor: BoutiqueTheme.accentGold,
                    backgroundColor: BoutiqueTheme.cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Products Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: BoutiqueTheme.accentGold))
                : _products.isEmpty
                    ? const Center(
                        child: Text(
                          'No sarees found matching your criteria.',
                          style: TextStyle(color: BoutiqueTheme.textMuted),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final prod = _products[index];
                          final isWishlisted = provider.isInWishlist(prod['id']);
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
                                  // Product image & wishlist
                                  Expanded(
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                          child: Image.network(
                                            prod['image_url'],
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
                                  ),

                                  // Saree Details & Quick Add
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
                                          prod['category_name'],
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: BoutiqueTheme.textMuted,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '₹$displayPrice',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: BoutiqueTheme.accentGold,
                                                  ),
                                                ),
                                                if (hasSalePrice)
                                                  Text(
                                                    '₹${prod['price']}',
                                                    style: const TextStyle(
                                                      fontSize: 9,
                                                      color: BoutiqueTheme.textMuted,
                                                      decoration: TextDecoration.lineThrough,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            
                                            // QUICK ADD BUTTON
                                            GestureDetector(
                                              onTap: () async {
                                                await provider.addToCart(prod, quantity: 1);
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('${prod['name']} added to shopping bag!'),
                                                      duration: const Duration(seconds: 1),
                                                      backgroundColor: BoutiqueTheme.cardBg,
                                                      action: SnackBarAction(
                                                        label: 'OK',
                                                        textColor: BoutiqueTheme.accentGold,
                                                        onPressed: () {},
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: BoutiqueTheme.accentGold,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Row(
                                                  children: [
                                                    Icon(Icons.add, size: 12, color: BoutiqueTheme.primaryBg),
                                                    SizedBox(width: 2),
                                                    Text(
                                                      'ADD',
                                                      style: TextStyle(
                                                        fontSize: 9, 
                                                        fontWeight: FontWeight.bold, 
                                                        color: BoutiqueTheme.primaryBg
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
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
          ),
        ],
      ),
    );
  }
}
