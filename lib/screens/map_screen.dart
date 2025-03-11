// @dart=2.17

import 'dart:async'; // Add this import
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/restaurant.dart';
import '../widgets/restaurant_widgets.dart';
import '../providers/theme_provider.dart';
import '../utils/debouncer.dart';

class MapScreen extends StatefulWidget {
  final List<Restaurant> restaurants;

  const MapScreen({super.key, required this.restaurants});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final bool _isSearchVisible = false;
  Position? _currentPosition;
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';
  List<Restaurant> _filteredRestaurants = [];
  bool _isMapView = true;
  String _selectedCuisine = 'All';
  final List<Restaurant> _favoriteRestaurants = [];
  LatLng? _selectedRestaurantLocation;

  late StreamSubscription<Position> _positionStreamSubscription;
  final Debouncer _searchDebouncer = Debouncer();
  StreamSubscription<Position>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _startLocationTracking();
  }

  void _startLocationTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1,
      timeLimit: Duration(seconds: 1),
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });
      _mapController.move(LatLng(position.latitude, position.longitude), 15.0);
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      // Move the map to the current position with animation
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        5.0,
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() => _isLoading = false);
    }
  }

  void _onRestaurantTap(Restaurant restaurant) {
    setState(() {
      _selectedRestaurantLocation = LatLng(
        restaurant.latitude,
        restaurant.longitude,
      );
    });

    _mapController.move(
      LatLng(restaurant.latitude, restaurant.longitude),
      20.0, // Zoom level
    );
    _isMapView = true;
  }

  void _filterRestaurants(String query) {
    _searchDebouncer.run(() {
      setState(() {
        _isSearching = query.isNotEmpty;
        _searchQuery = query.toLowerCase();
        _filteredRestaurants = widget.restaurants
            .where(
              (restaurant) =>
                  restaurant.name.toLowerCase().contains(_searchQuery) &&
                  (_selectedCuisine == 'All' ||
                      restaurant.cuisine == _selectedCuisine),
            )
            .toList();
      });

      if (_filteredRestaurants.isNotEmpty) {
        final firstRestaurant = _filteredRestaurants.first;
        _mapController.move(
          LatLng(firstRestaurant.latitude, firstRestaurant.longitude),
          5.0,
        );
      }
    });
  }

  void _toggleView() {
    setState(() => _isMapView = !_isMapView);
  }

  void _toggleFavorite(Restaurant restaurant) {
    setState(() {
      if (_favoriteRestaurants.contains(restaurant)) {
        _favoriteRestaurants.remove(restaurant);
      } else {
        _favoriteRestaurants.add(restaurant);
      }
    });
  }

  void _openMaps(Restaurant restaurant) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${restaurant.latitude},${restaurant.longitude}';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not launch maps')));
    }
  }

  Widget buildThemeToggle(BuildContext context, ThemeProvider themeProvider) {
    return IconButton(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 1000),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return RotationTransition(
            turns: animation,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: Icon(
          themeProvider.themeMode == ThemeMode.dark
              ? Icons.light_mode
              : Icons.dark_mode,
          key: ValueKey<bool>(themeProvider.themeMode == ThemeMode.dark),
          color: themeProvider.themeMode == ThemeMode.dark
              ? const Color.fromARGB(197, 201, 221, 15)
              : const Color.fromARGB(213, 141, 40, 40),
          size: 24,
        ),
      ),
      onPressed: () => themeProvider.toggleTheme(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Map'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: themeProvider.themeMode == ThemeMode.dark
                  ? [
                      const Color(0xFF121212),
                      const Color(0xFF1E1E1E),
                      const Color(0xFF2A2A2A),
                    ]
                  : [
                      const Color.fromARGB(255, 255, 69, 69),
                      const Color(0xFFEAEAEA),
                      const Color(0xFFDADADA),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              if (_currentPosition != null) {
                _mapController.move(
                  LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  ),
                  5.0,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Check your internet connection'),
                  ),
                );
              }
            },
          ),
          buildThemeToggle(context, themeProvider),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? Shimmer.fromColors(
                  baseColor: const Color.fromARGB(255, 70, 13, 13),
                  highlightColor: const Color.fromARGB(255, 110, 9, 9),
                  child: ListView.builder(
                    itemCount: 5,
                    itemBuilder: (context, index) => Card(
                      child: ListTile(
                        title: Container(
                          width: 100,
                          height: 20,
                          color: const Color.fromARGB(255, 116, 11, 11),
                        ),
                        subtitle: Container(
                          width: 150,
                          height: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                )
              : _isMapView
                  ? FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentPosition != null
                            ? LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              )
                            : const LatLng(9.0320, 38.7520),
                        initialZoom: 14.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c'],
                        ),
                        MarkerLayer(
                          markers: [
                            if (_currentPosition != null)
                              Marker(
                                point: LatLng(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                ),
                                width: 40,
                                height: 40,
                                child: Container(
                                  width: 30, // Size of the outer circle
                                  height: 30,
                                  decoration: BoxDecoration(
                                    shape:
                                        BoxShape.circle, // Outer circle shape
                                    border: Border.all(
                                      width: 2, // Border width
                                      color: const Color.fromARGB(
                                        255,
                                        66,
                                        133,
                                        244,
                                      ).withOpacity(
                                        0.5,
                                      ), // Border color (e.g., Google Maps blue)
                                    ),
                                    color: const Color.fromARGB(92, 13, 20, 27),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 8, // Size of the inner dot
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            Color.fromARGB(255, 66, 133, 244),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ..._getRestaurantMarkers(),
                          ],
                        ),
                      ],
                    )
                  : ListView.builder(
                      itemCount: _isSearching
                          ? _filteredRestaurants.length
                          : widget.restaurants.length,
                      itemBuilder: (context, index) {
                        final restaurant = _isSearching
                            ? _filteredRestaurants[index]
                            : widget.restaurants[index];
                        return ListTile(
                          leading:
                              const Icon(Icons.restaurant, color: Colors.red),
                          title: Text(restaurant.name),
                          subtitle: Text(restaurant.address),
                          trailing: Row(
                            mainAxisSize: MainAxisSize
                                .min, // Prevents Row from taking full width
                            children: [
                              IconButton(
                                icon: Icon(
                                  _favoriteRestaurants.contains(restaurant)
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color:
                                      _favoriteRestaurants.contains(restaurant)
                                          ? Colors.red
                                          : Colors.grey,
                                ),
                                iconSize: 24,
                                onPressed: () => _toggleFavorite(restaurant),
                              ),
                              IconButton(
                                icon: const Icon(Icons.directions),
                                iconSize: 24,
                                onPressed: () => _onRestaurantTap(restaurant),
                              ),
                              IconButton(
                                icon: const Icon(Icons.menu),
                                iconSize: 24,
                                onPressed: () =>
                                    _navigateToRestaurantDetails(restaurant),
                              ),
                            ],
                          ),
                          onTap: () => _navigateToRestaurantDetails(restaurant),
                        );
                      },
                    ),
          CustomSearchBar(
            onSearch: _filterRestaurants,
            selectedCuisine: _selectedCuisine,
            onCuisineSelect: (cuisine) {
              setState(() => _selectedCuisine = cuisine);
              _filterRestaurants(_searchQuery);
            },
          ),
          CustomBottomNavigationBar(
            isMapView: _isMapView,
            onToggleView: _toggleView,
          ),
        ],
      ),
    );
  }

  List<Marker> _getRestaurantMarkers() {
    final restaurants =
        _isSearching ? _filteredRestaurants : widget.restaurants;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return restaurants
        .where((restaurant) => restaurant.longitude != null)
        .map(
          (restaurant) => Marker(
            point: LatLng(restaurant.latitude, restaurant.longitude),
            width: 80,
            height: 80,
            child: GestureDetector(
              onTap: () => _showRestaurantInfoSheet(restaurant),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: themeProvider.themeMode == ThemeMode.dark
                            ? const Color.fromARGB(255, 44, 62, 80)
                            : const Color.fromARGB(255, 25, 111, 61),
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: themeProvider.themeMode == ThemeMode.dark
                              ? const Color.fromARGB(255, 52, 152, 219)
                              : const Color.fromARGB(255, 0, 92, 75),
                          spreadRadius: 2,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Text(
                      restaurant.name.substring(0, 10),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: themeProvider.themeMode == ThemeMode.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.location_pin,
                    color: Color.fromARGB(255, 255, 0, 0),
                    size: 25,
                  ),
                ],
              ),
            ),
          ),
        )
        .toList();
  }

  void _showRestaurantInfoSheet(Restaurant restaurant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RestaurantInfoSheet(
        restaurant: restaurant,
        isFavorite: _favoriteRestaurants.contains(restaurant),
        onFavoriteToggle: _toggleFavorite,
        onDirections: () => _openMaps(restaurant),
        menu: () => _navigateToRestaurantDetails(restaurant),
      ).animate().fadeIn(duration: 300.ms).slide(begin: const Offset(0, 0.1)),
    );
  }

  void _navigateToRestaurantDetails(Restaurant restaurant) {
    RestaurantWidgets.showRestaurantDetails(context, restaurant);
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    super.dispose();
    _locationSubscription?.cancel();
  }
}

class CustomSearchBar extends StatefulWidget {
  final void Function(String) onSearch;
  final String selectedCuisine;
  final void Function(String) onCuisineSelect;

  const CustomSearchBar({
    required this.onSearch,
    required this.selectedCuisine,
    required this.onCuisineSelect,
    super.key,
  });

  @override
  _CustomSearchBarState createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar>
    with TickerProviderStateMixin {
  bool _isVisible = false;
  bool _isSearching = false;
  final FocusNode _searchFocus = FocusNode();
  late AnimationController _searchAnimationController;
  final Duration _animationDuration = const Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _searchAnimationController = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );

    _searchFocus.addListener(() {
      setState(() {
        _isSearching = _searchFocus.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    _searchAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    if (!_isVisible) {
      _searchAnimationController.reverse();
    }
    if (!_isSearching) {
      _searchAnimationController.reverse();
    }
    if (_isSearching) {
      _searchAnimationController.forward();
    } else {
      _searchAnimationController.reverse();
    }

    return Stack(
      children: [
        AnimatedPositioned(
          right: 40,
          duration: _animationDuration,
          child: AnimatedOpacity(
            opacity: _isVisible ? 1 : 0,
            duration: _animationDuration,
            child: CircleAvatar(
              backgroundColor: isDarkMode
                  ? const Color.fromARGB(157, 6, 17, 27)
                  : const Color.fromARGB(167, 134, 240, 178),
              radius: 30,
              child: IconButton(
                icon: const Icon(Icons.search),
                iconSize: 50,
                color: isDarkMode
                    ? const Color.fromARGB(181, 226, 3, 3)
                    : const Color.fromARGB(255, 144, 168, 4),
                onPressed: () {
                  setState(() {
                    _isVisible = !_isVisible;
                    if (_isVisible) {
                      _searchAnimationController.forward();
                      _searchFocus.requestFocus();
                    } else {
                      _searchAnimationController.reverse();
                      _searchFocus.unfocus();
                    }
                  });
                },
              ),
            ),
          ),
        ),
        AnimatedOpacity(
          opacity: _isVisible ? 1 : 1,
          duration: _animationDuration,
          child: AnimatedPadding(
            padding:
                _isVisible ? const EdgeInsets.all(8) : const EdgeInsets.all(0),
            duration: _animationDuration,
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color.fromARGB(255, 44, 62, 80)
                    : const Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  colors: isDarkMode
                      ? [
                          const Color.fromARGB(255, 26, 27, 25),
                          const Color.fromARGB(255, 33, 45, 58),
                        ]
                      : [
                          const Color.fromARGB(255, 255, 255, 255),
                          const Color.fromARGB(255, 245, 245, 245),
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? const Color.fromARGB(255, 33, 45, 58)
                        : const Color.fromARGB(
                            255,
                            0,
                            0,
                            0,
                          ).withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 10,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      focusNode: _searchFocus,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Search restaurants...',
                        hintStyle: TextStyle(
                          color: isDarkMode
                              ? const Color.fromARGB(255, 128, 128, 128)
                              : const Color.fromARGB(255, 128, 128, 128),
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 8, right: 8),
                          child: DropdownButton<String>(
                            underline: Container(),
                            icon: const Icon(Icons.filter_list),
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                              fontSize: 14,
                            ),
                            value: widget.selectedCuisine,
                            isExpanded: false,
                            hint: const Text('All'),
                            items: [
                              'All',
                              'Italian',
                              'Mexican',
                              'Chinese',
                              'Indian',
                            ]
                                .map(
                                  (cuisine) => DropdownMenuItem<String>(
                                    value: cuisine,
                                    child: Text(cuisine),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              widget.onCuisineSelect(value!);
                            },
                          ),
                        ),
                        suffixIcon: _isSearching
                            ? IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _searchFocus.unfocus();
                                    _isVisible = !_isVisible;
                                    _searchAnimationController.reverse();
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: (query) {
                        widget.onSearch(query);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CustomBottomNavigationBar extends StatelessWidget {
  final bool isMapView;
  final Function onToggleView;

  const CustomBottomNavigationBar({
    required this.isMapView,
    required this.onToggleView,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(187, 79, 92, 62),
              Color.fromARGB(197, 33, 45, 58),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(216, 20, 7, 7),
              spreadRadius: 2,
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.map),
              onPressed: () => onToggleView(),
            ),
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: () => onToggleView(),
            ),
            IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}

class RestaurantInfoSheet extends StatelessWidget {
  final Restaurant restaurant;
  final bool isFavorite;
  final void Function(Restaurant) onFavoriteToggle;
  final VoidCallback onDirections;
  final VoidCallback menu;

  const RestaurantInfoSheet({
    required this.restaurant,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onDirections,
    required this.menu,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                restaurant.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _RestaurantInfoRow(
            Icons.star,
            '${restaurant.rating} Stars',
            color: Colors.grey[800]!,
          ),
          const SizedBox(height: 12),
          _RestaurantInfoRow(
            Icons.location_on,
            restaurant.address,
            color: Colors.grey[800]!,
          ),
          const SizedBox(height: 12),
          _RestaurantInfoRow(
            Icons.phone,
            restaurant.isOpen ? 'Open' : 'Closed',
            color: Colors.grey[800]!,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton.icon(
                onPressed: onDirections,
                icon: const Icon(Icons.directions),
                label: const Text('Directions'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(100, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.grey,
                ),
                iconSize: 30,
                onPressed: () => onFavoriteToggle(restaurant),
              ),
              ElevatedButton.icon(
                onPressed: menu,
                icon: const Icon(Icons.fastfood),
                label: const Text('Menu'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(100, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RestaurantInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _RestaurantInfoRow(this.icon, this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color == Colors.grey[600]
                    ? Colors.black87
                    : color.withAlpha(200),
              ),
        ),
      ],
    );
  }
}
