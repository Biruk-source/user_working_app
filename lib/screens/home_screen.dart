// @dart=2.17

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../models/restaurant.dart';
import '../services/restaurant_service.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/restaurant_widgets.dart';
import '../widgets/home_screen_widgets.dart';
import '../widgets/drawer_menu.dart';
import '../providers/cart_provider.dart';
import '../providers/theme_provider.dart';
import 'cart_screen.dart';
import 'my_orders.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'map_screen.dart'; // Import MapScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late RestaurantService _restaurantService;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late TextEditingController _searchController;

  List<Restaurant> _restaurants = [];
  List<Restaurant> _filteredRestaurants = [];
  final List<String> _availableCategories = [
    'Ethiopian',
    'Fast Food',
    'Italian',
    'Chinese',
    'Indian',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snacks',
    'Beverages',
    'Desserts'
  ];
  String? _selectedCategory;
  bool _isVegetarianSelected = false;
  bool _isFastingSelected = false;
  bool _isLoading = true;
  String _searchQuery = '';
  int _selectedIndex = 0;
  String _userName = '';
  double touchX = 0.0;
  double touchY = 0.0;
  bool isTouched = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _restaurantService = RestaurantService();
    _loadRestaurants();
    _loadUserName();
    _initializeAnimation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.repeat(reverse: true);
  }

  Future<void> _loadUserName() async {
    final user = _auth.currentUser;
    if (user != null) {
      String name = user.displayName ?? '';
      if (name.isEmpty) {
        name = user.email?.split('@')[0] ?? user.uid;
      }

      setState(() {
        _userName = name;
      });

      if (user.displayName == null || user.displayName!.isEmpty) {
        try {
          await user.updateDisplayName(name);
        } catch (e) {
          debugPrint('Failed to update display name: $e');
        }
      }
    }
  }

  Future<void> _loadRestaurants() async {
    setState(() => _isLoading = true);
    try {
      final restaurants = await _restaurantService.getRestaurants();
      setState(() {
        _restaurants = restaurants;
        _filteredRestaurants = restaurants;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error loading restaurants'),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterRestaurants() {
    setState(() {
      _filteredRestaurants = _restaurants.where((restaurant) {
        final matchesSearch = _searchQuery.isEmpty ||
            restaurant.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            restaurant.menu.any((item) =>
                item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                item.description
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()));

        final matchesCategory = _selectedCategory == null ||
            restaurant.categories.contains(_selectedCategory);

        final hasVegetarianItems = !_isVegetarianSelected ||
            restaurant.menu.any((item) => item.isVegetarian);

        final hasFastingItems = !_isFastingSelected ||
            restaurant.menu.any((item) => item.isFasting);

        return matchesSearch &&
            matchesCategory &&
            hasVegetarianItems &&
            hasFastingItems;
      }).toList();
    });
  }

  void _onCategorySelected(String? category) {
    setState(() {
      _selectedCategory = category;
      _filterRestaurants();
    });
  }

  void _onVegetarianChanged(bool value) {
    setState(() {
      _isVegetarianSelected = value;
      _filterRestaurants();
    });
  }

  void _navigateToMyorders(BuildContext context) {
    try {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyOrdersScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error navigating to cart: $e')),
        );
      }
      print('Error navigating to cart: $e');
    }
  }

  void _navigateToCart(BuildContext context) {
    try {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CartScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error navigating to cart: $e')),
        );
      }
      print('Error navigating to cart: $e');
    }
  }

  void _onFastingChanged(bool value) {
    setState(() {
      _isFastingSelected = value;
      _filterRestaurants();
    });
  }

  void _onRestaurantTap(Restaurant restaurant) {
    RestaurantWidgets.showRestaurantDetails(context, restaurant);
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        _navigateToCart(context);
        break;
      case 2:
        _navigateToMyorders(context);
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MapScreen(restaurants: _filteredRestaurants),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      drawer: DrawerMenu(
        userName: _userName,
        userEmail: FirebaseAuth.instance.currentUser?.email ?? '',
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              touchX = details.localPosition.dx;
              touchY = details.localPosition.dy;
              isTouched = true;
            });
          },
          onPanEnd: (details) {
            setState(() {
              isTouched = false;
            });
          },
          child: RefreshIndicator(
            onRefresh: _loadRestaurants,
            child: SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  HomeScreenWidgets.buildAppBar(
                    context,
                    _userName,
                    themeProvider,
                    cart,
                    touchX,
                    touchY,
                    isTouched,
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SearchBarWidget(
                            controller: _searchController,
                            onChanged: (query) {
                              setState(() {
                                _searchQuery = query;
                                _filterRestaurants();
                              });
                            },
                            onClear: () {
                              setState(() {
                                _searchQuery = '';
                                _filterRestaurants();
                              });
                            },
                            selectedCategory: _selectedCategory,
                            availableCategories: _availableCategories,
                            isVegetarianSelected: _isVegetarianSelected,
                            isFastingSelected: _isFastingSelected,
                            onCategorySelected: _onCategorySelected,
                            onVegetarianChanged: (value) {
                              setState(() {
                                _isVegetarianSelected = value;
                                _filterRestaurants();
                              });
                            },
                            onFastingChanged: (value) {
                              setState(() {
                                _isFastingSelected = value;
                                _filterRestaurants();
                              });
                            },
                          )
                              .animate()
                              .fadeIn(duration: 600.ms)
                              .slideX(begin: -0.2, end: 0),
                          const SizedBox(height: 24),
                          if (!_isLoading && _filteredRestaurants.isNotEmpty)
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MapScreen(
                                      restaurants: _filteredRestaurants,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.map),
                              label: const Text('View Map'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            )
                                .animate()
                                .fadeIn(duration: 800.ms, delay: 200.ms)
                                .scale(begin: const Offset(0.8, 0.8)),
                          const SizedBox(height: 24),
                          Text(
                            'Popular Restaurants',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                          )
                              .animate()
                              .fadeIn(duration: 600.ms)
                              .slideX(begin: -0.2, end: 0),
                        ],
                      ),
                    ),
                  ),
                  if (_isLoading)
                    const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    )
                  else if (_filteredRestaurants.isEmpty)
                    SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No restaurants found',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting your filters or search terms',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Colors.grey[500],
                                    ),
                              ),
                            ],
                          )
                              .animate()
                              .fadeIn(duration: 600.ms)
                              .slideY(begin: 0.2, end: 0),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(16.0),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final restaurant = _filteredRestaurants[index];
                            return AnimationConfiguration.staggeredGrid(
                              position: index,
                              duration: const Duration(milliseconds: 600),
                              columnCount: 2,
                              child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: GestureDetector(
                                    onTap: () => _onRestaurantTap(restaurant),
                                    child:
                                        RestaurantWidgets.buildRestaurantCard(
                                      context,
                                      restaurant,
                                      () => _onRestaurantTap(restaurant),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: _filteredRestaurants.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: HomeScreenWidgets.buildBottomNavigationBar(
        context,
        _selectedIndex,
        _onBottomNavTap,
        cart,
      ),
    );
  }
}
