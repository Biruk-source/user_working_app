import 'package:cloud_firestore/cloud_firestore.dart';

class FoodItem {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final double? rating;
  final bool isVegetarian;
  final bool isFasting;
  final List<String> categories;
  final List<String> ingredients;
  int quantity;

  FoodItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.rating,
    required this.isVegetarian,
    this.isFasting = false,
    this.categories = const [],
    this.ingredients = const [],
    this.quantity = 0,
  });

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] as String,
      restaurantId: map['restaurantId'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      price: (map['price'] as num).toDouble(),
      imageUrl: map['imageUrl'] as String,
      rating: map['rating'] != null ? (map['rating'] as num).toDouble() : null,
      isVegetarian: map['isVegetarian'] ?? false,
      isFasting: map['isFasting'] ?? false,
      categories: List<String>.from(map['categories'] ?? []),
      ingredients: List<String>.from(map['ingredients'] ?? []),
      quantity: map['quantity'] ?? 0,
    );
  }

  factory FoodItem.fromJson(Map<String, dynamic> data) {
    return FoodItem(
      id: data['id'] as String,
      restaurantId: data['restaurantId'] as String,
      name: data['name'] as String,
      description: data['description'] as String,
      price: (data['price'] as num).toDouble(),
      imageUrl: data['imageUrl'] as String,
      rating: data['rating'] != null ? (data['rating'] as num).toDouble() : null,
      isVegetarian: data['isVegetarian'] ?? false,
      isFasting: data['isFasting'] ?? false,
      categories: List<String>.from(data['categories'] ?? []),
      ingredients: List<String>.from(data['ingredients'] ?? []),
      quantity: data['quantity'] ?? 0,
    );
  }

  factory FoodItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FoodItem(
      id: doc.id,
      restaurantId: data['restaurantId'] as String,
      name: data['name'] as String,
      description: data['description'] as String,
      price: (data['price'] as num).toDouble(),
      imageUrl: data['imageUrl'] as String,
      rating: data['rating'] != null ? (data['rating'] as num).toDouble() : null,
      isVegetarian: data['isVegetarian'] ?? false,
      isFasting: data['isFasting'] ?? false,
      categories: List<String>.from(data['categories'] ?? []),
      ingredients: List<String>.from(data['ingredients'] ?? []),
      quantity: data['quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'rating': rating,
      'isVegetarian': isVegetarian,
      'isFasting': isFasting,
      'categories': categories,
      'ingredients': ingredients,
      'quantity': quantity,
    };
  }

  FoodItem copyWith({
    String? id,
    String? restaurantId,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    double? rating,
    bool? isVegetarian,
    bool? isFasting,
    List<String>? categories,
    List<String>? ingredients,
    int? quantity,
  }) {
    return FoodItem(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isFasting: isFasting ?? this.isFasting,
      categories: categories ?? this.categories,
      ingredients: ingredients ?? this.ingredients,
      quantity: quantity ?? this.quantity,
    );
  }
}
