import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_item.dart';

class CartProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Map<String, CartItem> _items = {};
  bool _isLoading = false;
  String? _editingOrderId;
  
  bool get isEditingOrder => _editingOrderId != null;
  String? get editingOrderId => _editingOrderId;

  bool containsOrderId(String orderId) {
    return _items.values.any((item) => item.orderId == orderId);
  }

  final orderId = <String>[];

  bool get isLoading => _isLoading;
  Map<String, CartItem> get items => {..._items};

  double get totalAmount {
    return _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  int get itemCount =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  int? getQuantity(String id) {
    return _items[id]?.quantity;
  }

  Future<void> addToCart(String id, String name, double price, String imageUrl,
      String restaurantId,
      {String? currentOrderId}) async {
    try {
      if (restaurantId.isEmpty) {
        throw Exception('Restaurant ID cannot be empty');
      }

      if (_items.isNotEmpty) {
        final existingRestaurantId = _items.values.first.restaurantId;
        if (restaurantId != existingRestaurantId) {
          throw Exception(
              'Cannot add items from different restaurants to cart');
        }
      }

      if (_items.containsKey(id)) {
        await incrementQuantity(id);
      } else {
        _items[id] = CartItem(
          id: id,
          name: name,
          price: price,
          quantity: 1,
          imageUrl: imageUrl,
          restaurantId: restaurantId,
          orderId: currentOrderId, // Use the renamed parameter
        );
        print('Cart Items: $_items');
        print('Order ID: $currentOrderId');
        notifyListeners();
        await _saveToFirestore();
      }
    } catch (e) {
      print('Error adding to cart: $e');
      rethrow;
    }
  }

  Future<void> incrementQuantity(String id) async {
    try {
      if (_items.containsKey(id)) {
        _items[id] = _items[id]!.copyWith(
          quantity: _items[id]!.quantity + 1,
        );
        notifyListeners();
        await _saveToFirestore();
      }
    } catch (e) {
      print('Error incrementing quantity: $e');
      rethrow;
    }
  }

  Future<void> decrementQuantity(String id) async {
    try {
      if (_items.containsKey(id)) {
        if (_items[id]!.quantity > 1) {
          _items[id] = _items[id]!.copyWith(
            quantity: _items[id]!.quantity - 1,
          );
          notifyListeners();
        } else {
          await removeItem(id);
        }
        await _saveToFirestore();
      }
    } catch (e) {
      print('Error decrementing quantity: $e');
      rethrow;
    }
  }

  Future<void> removeItem(String id) async {
    try {
      _items.remove(id);
      notifyListeners();
      await _saveToFirestore();
    } catch (e) {
      print('Error removing item: $e');
      rethrow;
    }
  }

  Future<void> clearCart() async {
    _items.clear();
    notifyListeners();
    await _saveToFirestore();
  }

  Future<void> clear() async {
    await clearCart();
  }

  Future<void> loadCartFromFirestore() async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_auth.currentUser == null) {
        print('No user logged in, skipping cart load');
        _isLoading = false;
        notifyListeners();
        return;
      }

      final userId = _auth.currentUser!.uid;
      final cartDoc = await FirebaseFirestore.instance.collection('carts').doc(userId).get();

      if (!cartDoc.exists || cartDoc.data() == null) {
        print('No cart found for user');
        _items.clear();
        _isLoading = false;
        notifyListeners();
        return;
      }

      final cartData = cartDoc.data()!;
      if (cartData['items'] == null) {
        print('Cart exists but no items found');
        _items.clear();
        _isLoading = false;
        notifyListeners();
        return;
      }

      final List<dynamic> itemsList = cartData['items'] as List<dynamic>;
      _items.clear();

      for (var item in itemsList) {
        if (item is Map<String, dynamic>) {
          final cartItem = CartItem.fromMap(item);
          if (cartItem.id.isNotEmpty && cartItem.restaurantId.isNotEmpty) {
            _items[cartItem.id] = cartItem;
          }
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading cart: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _saveToFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No user logged in, cannot save cart');
        return;
      }

      // Get the first item's restaurant ID
      String? restaurantId;
      if (_items.isNotEmpty) {
        restaurantId = _items.values.first.restaurantId;
      }

      final cartData = {
        'items': _items.values.map((item) => item.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'restaurantId': restaurantId,
      };

      await FirebaseFirestore.instance.collection('carts').doc(user.uid).set(cartData);
    } catch (e) {
      print('Error saving cart to Firestore: $e');
      rethrow;
    }
  }

  // Method to start editing an order
  Future<void> startEditingOrder(String orderId, List<Map<String, dynamic>> items, String restaurantId) async {
    _editingOrderId = orderId;
    await clearCart();
    
    // Add items from the order to the cart
    for (var item in items) {
      await addToCart(
        item['id'],
        item['name'],
        item['price'].toDouble(),
        item['imageUrl'] ?? '',
        restaurantId,
        currentOrderId: orderId,
      );
    }
    notifyListeners();
  }

  // Method to finish editing order
  void finishEditingOrder() {
    _editingOrderId = null;
    notifyListeners();
  }
}
