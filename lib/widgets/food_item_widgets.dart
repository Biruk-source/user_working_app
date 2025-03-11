// @dart=2.17

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/food_item.dart';
import '../providers/cart_provider.dart';

class FoodItemWidgets {
  static Widget buildFoodItemCard(
      BuildContext context, FoodItem item, VoidCallback onAddToCart) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => const Text('Error'),
                ),
              ),
              Consumer<CartProvider>(
                builder: (context, cart, _) =>
                    CartWidgets.buildCartIndicator(context, cart, item),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  '\$${item.price.toStringAsFixed(2)} only!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.1),
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Consumer<CartProvider>(
            builder: (context, cart, _) =>
                CartWidgets.buildQuantityControls(context, cart, item),
          ),
          CartWidgets.buildAddToCartButton(context, item),
        ],
      ),
    );
  }

  static void showFoodItemDetails(BuildContext context, FoodItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(40),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, -3),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red.withOpacity(0.9),
              Colors.blue.withOpacity(0.9),
            ],
          ),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: FoodItemDetails(
          item: item,
          onClose: () => Navigator.pop(context),
        ),
      ),
    );
  }
}

class FoodItemDetails extends StatefulWidget {
  final FoodItem item;
  final VoidCallback? onClose;

  const FoodItemDetails({
    super.key,
    required this.item,
    this.onClose,
  });

  @override
  State<FoodItemDetails> createState() => _FoodItemDetailsState();
}

class _FoodItemDetailsState extends State<FoodItemDetails> {
  late final CartProvider _cartProvider;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _cartProvider = Provider.of<CartProvider>(context, listen: false);
    _quantity = _cartProvider.getQuantity(widget.item.id) ?? 1;
  }

  Future<void> _addToCart() async {
    await _cartProvider.addToCart(
      widget.item.id,
      widget.item.name,
      widget.item.price,
      widget.item.imageUrl,
      widget.item.restaurantId,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.item.name} added to cart'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(
            height: 150,
            width: double.infinity,
            child: CachedNetworkImage(
              imageUrl: widget.item.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) => const Text('network error'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.item.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${widget.item.price.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (_quantity > 1) {
                              setState(() => _quantity--);
                            }
                          },
                        ),
                        Text(
                          _quantity.toString(),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() => _quantity++);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _addToCart,
                    child: const Text('Add to Cart'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QuantityController with ChangeNotifier {
  final CartProvider _cartProvider;
  FoodItem? _item;
  int _quantity = 1;

  QuantityController({
    required CartProvider cartProvider,
    FoodItem? item,
  })  : _cartProvider = cartProvider,
        _item = item;

  int get quantity => _quantity;

  void initialize({FoodItem? item}) {
    _item = item;
    _quantity = _cartProvider.getQuantity(item!.id) ?? 1;
    notifyListeners();
  }

  void incrementQuantity() {
    _quantity++;
    notifyListeners();
  }

  void decrementQuantity() {
    if (_quantity > 1) {
      _quantity--;
    }
    notifyListeners();
  }

  void updateQuantity(int quantity) {
    _quantity = quantity;
    notifyListeners();
  }
}

class CartWidgets {
  static Widget buildCartIndicator(
    BuildContext context,
    CartProvider cart,
    FoodItem item,
  ) {
    final quantity = cart.getQuantity(item.id);
    if (quantity == null || quantity == 0) return const SizedBox.shrink();

    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$quantity',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  static Widget buildQuantityControls(
    BuildContext context,
    CartProvider cart,
    FoodItem item,
  ) {
    final quantity = cart.getQuantity(item.id) ?? 0;
    if (quantity == 0) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: () => cart.decrementQuantity(item.id),
        ),
        Text(
          '$quantity',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => cart.incrementQuantity(item.id),
        ),
      ],
    );
  }

  static Widget buildAddToCartButton(BuildContext context, FoodItem item) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        final bool inCart = (cart.getQuantity(item.id) ?? 0) > 0;
        return ElevatedButton(
          onPressed: inCart
              ? null
              : () async {
                  await cart.addToCart(
                    item.id,
                    item.name,
                    item.price,
                    item.imageUrl,
                    item.restaurantId,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item.name} added to cart'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(inCart ? 'In Cart' : 'Add to Cart'),
        );
      },
    );
  }
}
