import '../providers/cart_provider.dart';

class QuantityController {
  final CartProvider cartProvider;
  int _quantity = 1;

  QuantityController({required this.cartProvider});

  int get quantity => _quantity;

  void increment() {
    _quantity++;
  }

  void decrement() {
    if (_quantity > 1) {
      _quantity--;
    }
  }

  void reset() {
    _quantity = 1;
  }
}
