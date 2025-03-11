// @dart=2.17

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/restaurant.dart';
import '../models/food_item.dart';
import '../providers/cart_provider.dart';
import 'food_item_widgets.dart';

class RestaurantWidgets {
  static Widget buildRestaurantCard(
    BuildContext context,
    Restaurant restaurant,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 8,
      shadowColor: Theme.of(context).shadowColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: CachedNetworkImage(
                  imageUrl: restaurant.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      color: Colors.white,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.restaurant, size: 40),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            restaurant.rating.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.access_time,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${restaurant.deliveryTime} min',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (restaurant.isPromoted)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Featured',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .shimmer(duration: 1000.ms, delay: 200.ms)
        .fade(duration: 500.ms);
  }

  static Widget buildRestaurantGrid(
    BuildContext context,
    List<Restaurant> restaurants,
    Function(Restaurant) onRestaurantTap,
  ) {
    return AnimatedRestaurantGrid(
      restaurants: restaurants,
      onRestaurantTap: onRestaurantTap,
    );
  }

  static Widget buildFoodItemGrid(
    BuildContext context,
    List<FoodItem> foodItems,
    Function(FoodItem) onFoodItemTap,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = (screenWidth > 600) ? 3 : 2;
    final childAspectRatio = (screenWidth > 600) ? 1.0 : 0.75;

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: foodItems.length,
      itemBuilder: (context, index) {
        return FoodItemWidgets.buildFoodItemCard(
            context, foodItems[index], () => onFoodItemTap(foodItems[index]));
      },
    );
  }

  static void showRestaurantDetails(
      BuildContext context, Restaurant restaurant) {
    ValueNotifier<String?> selectedMenuCategory = ValueNotifier<String?>(null);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: CustomScrollView(
                  controller: controller,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              Hero(
                                tag: 'restaurant_${restaurant.id}',
                                child: CachedNetworkImage(
                                  imageUrl: restaurant.imageUrl,
                                  height: 250,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  icon: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        color: Colors.white),
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.8),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        restaurant.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white24,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.star,
                                                  color: Colors.amber,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  restaurant.rating.toString(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white24,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              restaurant.cuisine,
                                              style: const TextStyle(
                                                color: Colors.white,
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
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (restaurant.description.isNotEmpty) ...[
                                  Text(
                                    'About',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    restaurant.description,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                Text(
                                  'Categories',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children:
                                      restaurant.categories.map((category) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        category,
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Menu',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 16),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ValueListenableBuilder<String?>(
                                      valueListenable: selectedMenuCategory,
                                      builder: (context, value, child) {
                                        return Row(
                                          children: [
                                            for (final category in [
                                              'All',
                                              ...restaurant.categories
                                            ])
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 8),
                                                child: FilterChip(
                                                  selected: value == category,
                                                  label: Text(category),
                                                  onSelected: (selected) {
                                                    selectedMenuCategory.value =
                                                        selected
                                                            ? category
                                                            : null;
                                                  },
                                                ),
                                              ),
                                          ],
                                        );
                                      }),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return ValueListenableBuilder<String?>(
                              valueListenable: selectedMenuCategory,
                              builder: (context, category, child) {
                                final filteredItems = restaurant.menu
                                    .where((item) =>
                                        category == null ||
                                        category == 'All' ||
                                        item.categories.contains(category))
                                    .toList();

                                if (index >= filteredItems.length) {
                                  return const SizedBox();
                                }

                                final foodItem = filteredItems[index];
                                return GestureDetector(
                                  onTap: () =>
                                      FoodItemWidgets.showFoodItemDetails(
                                          context, foodItem),
                                  child: FoodItemWidgets.buildFoodItemCard(
                                      context, foodItem, () {
                                    final cart = Provider.of<CartProvider>(
                                        context,
                                        listen: false);
                                    cart.addToCart(
                                      foodItem.id,
                                      foodItem.name,
                                      foodItem.price,
                                      foodItem.imageUrl,
                                      restaurant.id,
                                      currentOrderId: null,
                                    );
                                  }),
                                );
                              });
                        },
                        childCount: restaurant.menu.length,
                      ),
                    ),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedRestaurantGrid extends StatefulWidget {
  final List<Restaurant> restaurants;
  final Function(Restaurant) onRestaurantTap;

  const AnimatedRestaurantGrid({
    super.key,
    required this.restaurants,
    required this.onRestaurantTap,
  });

  @override
  _AnimatedRestaurantGridState createState() => _AnimatedRestaurantGridState();
}

class _AnimatedRestaurantGridState extends State<AnimatedRestaurantGrid> {
  double touchX = 0.0;
  double touchY = 0.0;
  bool isTouched = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
      child: Container(
        decoration: BoxDecoration(
          color: isTouched ? Colors.blue.withOpacity(0.1) : Colors.transparent,
        ),
        child: GridView.builder(
          padding: const EdgeInsets.all(8),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: (MediaQuery.of(context).size.width > 600) ? 3 : 2,
            childAspectRatio:
                (MediaQuery.of(context).size.width > 600) ? 1.2 : 0.8,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: widget.restaurants.length,
          itemBuilder: (context, index) {
            return RestaurantWidgets.buildRestaurantCard(
              context,
              widget.restaurants[index],
              () => widget.onRestaurantTap(widget.restaurants[index]),
            );
          },
        ),
      ),
    );
  }
}
