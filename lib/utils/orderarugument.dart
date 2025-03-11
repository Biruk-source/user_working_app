import '../models/cart_item.dart';
import '../models/restaurant.dart';

class OrdersScreenArguments {
  final double totalPrice;
  final List<CartItem> cartItems;
  final Restaurant restaurant;
  final String? orderId;

  OrdersScreenArguments({
    required this.totalPrice,
    required this.cartItems,
    required this.restaurant,
    this.orderId,
  });
}
