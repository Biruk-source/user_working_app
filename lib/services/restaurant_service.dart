import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../models/food_item.dart';

class RestaurantService extends ChangeNotifier {
  final List<Restaurant> _restaurants = [
    Restaurant(
      id: '1',
      name: 'Italian Delight',
      imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4',
      description: 'Authentic Italian cuisine in a cozy atmosphere',
      rating: 4.5,
      address: '123 Italian Street',
      cuisine: 'Italian',
      isOpen: true,
      categories: ['Italian', 'Pizza', 'Pasta'],
      menu: [
        FoodItem(
          id: '1',
          name: 'Margherita Pizza',
          description:
              'Classic Italian pizza with tomato sauce, mozzarella, and basil',
          price: 15.99,
          imageUrl:
              'https://images.unsplash.com/photo-1574071318508-1cdbab80d002',
          isVegetarian: true,
          categories: ['Pizza', 'Vegetarian'],
          ingredients: ['Tomato Sauce', 'Mozzarella', 'Basil'],
          rating: 4.8,
          restaurantId: '1',
        ),
        FoodItem(
          id: '2',
          name: 'Pasta Carbonara',
          description:
              'Creamy pasta with eggs, cheese, pancetta, and black pepper',
          price: 14.99,
          imageUrl:
              'https://images.unsplash.com/photo-1612874742237-6526221588e3',
          isVegetarian: false,
          categories: ['Pasta'],
          ingredients: [
            'Pasta',
            'Eggs',
            'Pecorino Romano',
            'Pancetta',
            'Black Pepper'
          ],
          rating: 4.7,
          restaurantId: '1',
        ),
      ],
      deliveryTime: 30,
      isPromoted: true,
      latitude: 40.7128,
      longitude: -74.0060,
      isFavorite: false,
    ),
    Restaurant(
      id: '2',
      name: 'Kitfo Corner',
      imageUrl: 'https://images.unsplash.com/photo-1626804475297-41608ea09aeb',
      description: 'Specializing in Kitfo and other Ethiopian delicacies',
      rating: 4.5,
      address: 'Adama University Road, Adama',
      cuisine: 'Ethiopian',
      isOpen: true,
      categories: ['Kitfo', 'Meat', 'Traditional'],
      menu: [
        FoodItem(
          id: '3',
          restaurantId: '2',
          name: 'Kitfo',
          description:
              'Minced raw beef marinated in spices and served with injera',
          price: 150.0,
          imageUrl:
              'https://images.unsplash.com/photo-1626804475297-41608ea09aeb',
          isVegetarian: false,
          categories: ['Meat', 'Traditional'],
          ingredients: ['Beef', 'Mitmita', 'Kibe', 'Injera'],
          rating: 4.7,
        ),
        FoodItem(
          id: '4',
          name: 'Tibs',
          restaurantId: '2',
          description: 'Sautéed beef with onions, peppers, and spices',
          price: 130.0,
          imageUrl:
              'https://images.unsplash.com/photo-1626804475297-41608ea09aeb',
          isVegetarian: false,
          categories: ['Meat', 'Tibs'],
          ingredients: ['Beef', 'Onions', 'Peppers', 'Spices'],
          rating: 4.5,
        ),
      ],
      deliveryTime: 25,
      isPromoted: false,
      latitude: 8.5615,
      longitude: 39.2694,
      isFavorite: false,
    ),
    Restaurant(
      id: '3',
      name: 'Green Valley Café',
      imageUrl: 'https://images.unsplash.com/photo-1626804475297-41608ea09aeb',
      description: 'A vegetarian-friendly café with a variety of options',
      rating: 4.4,
      address: 'Adama Main Road',
      cuisine: 'Ethiopian & International',
      isOpen: true,
      categories: ['Vegetarian', 'Café'],
      menu: [
        FoodItem(
          id: '7',
          restaurantId: '3',
          name: 'Vegetarian Platter',
          description: 'A mix of lentils, greens, and vegetables',
          price: 100.0,
          imageUrl:
              'https://images.unsplash.com/photo-1626804475297-41608ea09aeb',
          isVegetarian: true,
          categories: ['Vegetarian', 'Traditional'],
          ingredients: ['Lentils', 'Greens', 'Vegetables'],
          rating: 4.5,
        ),
        FoodItem(
          id: '8',
          name: 'Falafel Wrap',
          restaurantId: '3',
          description: 'Crispy falafel with tahini sauce',
          price: 90.0,
          imageUrl:
              'https://images.unsplash.com/photo-1626804475297-41608ea09aeb',
          isVegetarian: true,
          categories: ['Vegetarian', 'Wrap'],
          ingredients: ['Falafel', 'Tahini', 'Lettuce', 'Tomato'],
          rating: 4.3,
        ),
      ],
      deliveryTime: 20,
      isPromoted: false,
      latitude: 8.5415,
      longitude: 39.2686,
      isFavorite: false,
    ),
    Restaurant(
      id: '4',
      name: 'Adama Grill House',
      imageUrl: 'https://images.unsplash.com/photo-1626804475297-41608ea09aeb',
      description: 'Best grilled meats in town',
      rating: 4.6,
      address: 'Adama Stadium Area',
      cuisine: 'Ethiopian & BBQ',
      isOpen: true,
      categories: ['Grill', 'BBQ', 'Meat'],
      menu: [
        FoodItem(
          id: '9',
          restaurantId: '4',
          name: 'Mixed Grill Platter',
          description: 'Assortment of grilled meats with sides',
          price: 180.0,
          imageUrl:
              'https://images.unsplash.com/photo-1626804475297-41608ea09aeb',
          isVegetarian: false,
          categories: ['Grill', 'Meat'],
          ingredients: ['Beef', 'Chicken', 'Lamb', 'Vegetables'],
          rating: 4.8,
        ),
        FoodItem(
          id: '10',
          name: 'BBQ Ribs',
          restaurantId: '4',
          description: 'Tender ribs with BBQ sauce',
          price: 160.0,
          imageUrl:
              'https://images.unsplash.com/photo-1626804475297-41608ea09aeb',
          isVegetarian: false,
          categories: ['BBQ', 'Meat'],
          ingredients: ['Pork Ribs', 'BBQ Sauce', 'Coleslaw'],
          rating: 4.7,
        ),
      ],
      deliveryTime: 35,
      isPromoted: true,
      latitude: 8.5425,
      longitude: 39.2676,
      isFavorite: false,
    ),
  ];

  List<Restaurant> get restaurants => [..._restaurants];

  Restaurant? getRestaurantById(String id) {
    try {
      return _restaurants.firstWhere((restaurant) => restaurant.id == id);
    } catch (e) {
      print('Restaurant not found with ID: $id');
      return null;
    }
  }

  Future<List<Restaurant>> getRestaurants() async {
    // Simulate network delay for realistic behavior
    await Future.delayed(const Duration(milliseconds: 500));
    return [..._restaurants];
  }

  List<Restaurant> getRestaurantsByCategory(String category) {
    return _restaurants
        .where((restaurant) =>
            restaurant.categories.any((cat) =>
                cat.toLowerCase().contains(category.toLowerCase())))
        .toList();
  }

  List<Restaurant> searchRestaurants(String query) {
    return _restaurants
        .where((restaurant) =>
            restaurant.name.toLowerCase().contains(query.toLowerCase()) ||
            restaurant.cuisine.toLowerCase().contains(query.toLowerCase()) ||
            restaurant.categories.any((category) =>
                category.toLowerCase().contains(query.toLowerCase())))
        .toList();
  }
}
