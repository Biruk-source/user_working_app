import 'package:cloud_firestore/cloud_firestore.dart';
import 'food_item.dart';

class Restaurant {
  final String id;
  final String name;
  final String imageUrl;
  final String description;
  final double rating;
  final String address;
  final String cuisine;
  final bool isOpen;
  final List<String> categories;
  final List<FoodItem> menu;
  final int deliveryTime;
  final bool isPromoted;
  final double latitude;
  final double longitude;
  final GeoPoint? location;
  final bool isFavorite;

  Restaurant({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.rating,
    required this.address,
    required this.cuisine,
    required this.isOpen,
    required this.categories,
    required this.menu,
    required this.deliveryTime,
    required this.isPromoted,
    required this.latitude,
    required this.longitude,
    required this.isFavorite,
    this.location,
  });

  factory Restaurant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final GeoPoint? geoPoint = data['location'] as GeoPoint?;

    return Restaurant(
      id: doc.id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      address: data['address'] ?? '',
      cuisine: data['cuisine'] ?? '',
      isOpen: data['isOpen'] ?? false,
      categories: List<String>.from(data['categories'] ?? []),
      menu: (data['menu'] as List<dynamic>?)
              ?.map((item) => FoodItem.fromMap({...item as Map<String, dynamic>, 'restaurantId': doc.id}))
              .toList() ??
          [],
      deliveryTime: data['deliveryTime'] ?? 30,
      isPromoted: data['isPromoted'] ?? false,
      latitude: geoPoint?.latitude ?? (data['latitude'] ?? 0.0).toDouble(),
      longitude: geoPoint?.longitude ?? (data['longitude'] ?? 0.0).toDouble(),
      location: geoPoint,
      isFavorite: data['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
      'rating': rating,
      'address': address,
      'cuisine': cuisine,
      'isOpen': isOpen,
      'categories': categories,
      'menu': menu.map((item) => item.toMap()).toList(),
      'deliveryTime': deliveryTime,
      'isPromoted': isPromoted,
      'latitude': latitude,
      'longitude': longitude,
      'location': location ?? GeoPoint(latitude, longitude),
      'isFavorite': isFavorite,
    };
  }
}
