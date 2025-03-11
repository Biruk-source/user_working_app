// @dart=2.17

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/restaurant.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../widgets/glassmorphic_button.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../services/background_servies.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class OrdersScreen extends StatefulWidget {
  static const routeName = '/orders';
  final Restaurant restaurant;
  final List<CartItem> cartItems;
  final double totalPrice;

  const OrdersScreen({
    super.key,
    required this.restaurant,
    required this.cartItems,
    required this.totalPrice,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  String _paymentMethod = 'cash';
  bool _isProcessing = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final List<String> _paymentMethods = ['cash', 'card'];
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  Position? _currentPosition;
  bool _notificationsInitialized = false;
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  String _currentTime = '';
  String _orderStartTime = '';
  String? _currentOrderId;
  bool _isLocationEnabled = false;
  StreamSubscription<Position>? _locationSubscription;
  Timer? _timeUpdateTimer;
  Position? _lastPosition;
  DateTime? _lastUpdateTime;


  @override
  void initState() {
    super.initState();
   
    _setupLocationAndNotifications();
    _initializeTimeUpdates();
    final user = _auth.currentUser;
    if (user != null) {
      _currentOrderId = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}';
    }
  }


  void _initializeTimeUpdates() {
    _orderStartTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    _updateCurrentTime();
    _timeUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCurrentTime();
    });
  }

  void _updateCurrentTime() {
    setState(() {
      _currentTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _timeUpdateTimer?.cancel();
    _mapController?.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    stopBackgroundService();
    super.dispose();
  }

  Future<void> _setupLocationAndNotifications() async {
    try {
      // Initialize notifications
      if (!_notificationsInitialized) {
        const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
        const iosSettings = DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
        const initSettings = InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        );
        await _notifications.initialize(
          initSettings,
          onDidReceiveNotificationResponse: (details) {
            print('Notification tapped: ${details.payload}');
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            );
          },
        );
        // Create the notification channel for Android
        const androidChannel = AndroidNotificationChannel(
          'food will be delivered waiting for acceptance',
          'GB delivery',
          description: 'Notifications for your food delivery orders',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        );
        await _notifications
            .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(androidChannel);
        _notificationsInitialized = true;
      }

      // Get initial position
      _currentPosition = await Geolocator.getCurrentPosition();
      if (_currentPosition != null) {
        setState(() {
          _markers.add(
            Marker(
              markerId: const MarkerId('current_location'),
              position: LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ),
              infoWindow: const InfoWindow(title: 'Your Location'),
            ),
          );
        });
      }

    } catch (e) {
      print('Error setting up notifications: $e');
    }

    NotificationSettings settings = await _messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _firestore
            .collection('users')
            .doc(_auth.currentUser?.uid)
            .update({'fcmToken': token});
      }
    }
  }

  Future<void> _startLocationTracking() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        _isLocationEnabled = true;
        

        // Configure location settings for high accuracy and updates every meter
        const locationSettings = LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1, // Update every 1 meter
        );

        // Create a timer for 1-second updates
        Timer.periodic(const Duration(seconds: 1), (timer) async {
          try {
            final position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );
            
            if (position != null && _currentOrderId != null) {
              // Check if we should update based on distance and time
              bool shouldUpdate = true;
              if (_lastPosition != null && _lastUpdateTime != null) {
                final distance = Geolocator.distanceBetween(
                  _lastPosition!.latitude,
                  _lastPosition!.longitude,
                  position.latitude,
                  position.longitude,
                );
                final timeDiff = DateTime.now().difference(_lastUpdateTime!).inSeconds;
                
                // Only update if moved more than 1 meter or 1 second has passed
                shouldUpdate = distance >= 1.0 || timeDiff >= 1;
              }

              if (shouldUpdate) {
                if (mounted) {
                  setState(() {
                    _currentPosition = position;
                    _lastPosition = position;
                    _lastUpdateTime = DateTime.now();
                    
                    // Update map markers
                    _markers.clear();
                    _markers.add(
                      Marker(
                        markerId: const MarkerId('current_location'),
                        position: LatLng(position.latitude, position.longitude),
                        infoWindow: InfoWindow(
                          title: 'Current Location',
                          snippet: 'Updated: ${DateFormat('HH:mm:ss').format(DateTime.now())}',
                        ),
                      ),
                    );

                    // Update map camera position
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
                    );
                  });
                }

                // Update location in Firestore with timestamp
                await _firestore.collection('orders').doc(_currentOrderId).update({
                  'currentLocation': GeoPoint(position.latitude, position.longitude),
                  'lastUpdated': FieldValue.serverTimestamp(),
                  'speed': position.speed,
                  'heading': position.heading,
                  'accuracy': position.accuracy,
                  'timestamp': DateTime.now().toIso8601String(),
                  'distanceMoved': _lastPosition != null ? Geolocator.distanceBetween(
                    _lastPosition!.latitude,
                    _lastPosition!.longitude,
                    position.latitude,
                    position.longitude,
                  ) : 0.0,
                });
              }
            }
          } catch (e) {
            print('Error updating location: $e');
          }
        });

        // Start listening to position stream for continuous updates
        _locationSubscription?.cancel(); // Cancel any existing subscription
        _locationSubscription = Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen(
          (Position? position) async {
            if (position != null && _currentOrderId != null) {
              // Handle continuous position updates
              if (mounted) {
                setState(() {
                  _currentPosition = position;
                });
              }
            }
          },
          onError: (error) {
            print('Location tracking error: $error');
            _showErrorNotification('Location tracking error occurred');
          },
        );
      }
    } catch (e) {
      print('Error starting location tracking: $e');
      _showErrorNotification('Failed to start location tracking');
    }
  }

  void _showErrorNotification(String message) {
    _notifications.show(
      0,
      'Location Error',
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'food will be delivered waiting for acceptance',
          'GB delivery',
          importance: Importance.high,
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to place an order')),
        );
        return;
      }

      final orderData = {
        'userId': user.uid,
        'userName': _nameController.text,
        'userPhone': _phoneController.text,
        'userAddress': _addressController.text,
        'userCity': _cityController.text,
        'paymentMethod': _paymentMethod,
        'totalPrice': widget.totalPrice,

        'status': 'pending',
        'orderTime': _orderStartTime,
        'orderId': _currentOrderId,
      };

      await _firestore.collection('orders').doc(_currentOrderId).set(orderData);
      
      // Start location tracking after order is placed
      await _startLocationTracking();

      // Initialize and start background service
      await initializeBackgroundService();
      final service = FlutterBackgroundService();
      await service.startService();

      // Show notification after background service is started
      await _notifications.show(
        1,
        'Order Placed Successfully',
        'Your order has been placed and is being processed',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'food_delivery_channel',
            'GB delivery',
            channelDescription: 'Notifications for your food delivery orders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );

      if (!mounted) return;

      // Clear cart and navigate back
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.clearCart();

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
      );
    } catch (e) {
      print('Error placing order: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error placing order: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> stopBackgroundService() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Checkout - ${widget.restaurant.name}',
          style: const TextStyle(fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Restaurant Info
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Restaurant Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.restaurant.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(widget.restaurant.name),
                      subtitle: Text(widget.restaurant.address),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Order Summary
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Summary',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    ...widget.cartItems.map((item) => ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(item.name),
                      subtitle: Text('Quantity: ${item.quantity}'),
                      trailing: Text(
                        '${(item.price * item.quantity).toStringAsFixed(2)}',
                      ),
                    )),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount:'),
                        Text(
                          '${widget.totalPrice.toStringAsFixed(2)}',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Personal Information
            Text(
              'Personal Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter your name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) => value?.isEmpty ?? true
                  ? 'Please enter your phone number'
                  : null,
            ),
            const SizedBox(height: 24),

            // Delivery Information
            Text(
              'Delivery Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Delivery Address',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter your address' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter your city' : null,
            ),
            const SizedBox(height: 24),

            // Payment Method
            Text(
              'Payment Method',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  items: _paymentMethods.map((method) {
                    return DropdownMenuItem<String>(
                      value: method,
                      child: Text(method == 'cash'
                          ? 'Cash on Delivery'
                          : 'Credit/Debit Card'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _paymentMethod = value);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: GlassmorphicButton(
                onPressed: _isProcessing ? () {} : () => _placeOrder(),
                child: _isProcessing
                    ? const CircularProgressIndicator(
                  color: Color.fromARGB(255, 164, 255, 8),
                )
                    : const Text(
                  'Place Order',
                  style: TextStyle(
                    color: Color.fromARGB(255, 191, 255, 112),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
