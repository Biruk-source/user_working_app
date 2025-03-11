// @dart=2.17

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart' as flutter;
import '../providers/theme_provider.dart';
import '../providers/cart_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'cart_screen.dart';
import 'package:shimmer/shimmer.dart';
import '../services/restaurant_service.dart';
import '../models/restaurant.dart';
import 'package:rive/rive.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';

class MyOrdersScreen extends StatefulWidget {
  static const routeName = '/my-orders';

  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  late CartProvider cart;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'all';
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    cart = Provider.of<CartProvider>(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: isDark ? Colors.grey[850] : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _HeroSection(),
          Expanded(
            child: _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _HeroSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Orders',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track and manage your orders with ease',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.grey[300] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text('Please login to view orders'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Error: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          print('Loading orders...');
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          print('No orders found. Refreshing data...');
          Future.delayed(Duration.zero, () async {
            await _refreshOrders();
            print('Orders loaded: ${snapshot.data!.docs.length}');
          });
          return _EmptyState();
        }

        print('Orders loaded: ${snapshot.data!.docs.length}');
        _handleOrderStatusChanges(snapshot.data!.docs);
        return RefreshIndicator(
          onRefresh: _refreshOrders,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final orderDoc = snapshot.data!.docs[index];
              print('Order ID: ${orderDoc.id}');
              final orderData = orderDoc.data() as Map<String, dynamic>;
              final status =
                  orderData['status']?.toString().toLowerCase() ?? 'pending';

              // Only allow dismissal if the status is 'pending'
              if (status == 'pending') {
                return Dismissible(
                  key: Key(orderDoc.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                          title: Text(
                            'Delete Order',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.color,
                            ),
                          ),
                          content: Text(
                            'Are you sure you want to delete this order?',
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () => Navigator.of(context).pop(false),
                            ),
                            TextButton(
                              child: const Text('Delete'),
                              onPressed: () => Navigator.of(context).pop(true),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) async {
                    try {
                      await _firestore
                          .collection('users')
                          .doc(user.uid)
                          .collection('orders')
                          .doc(orderDoc.id)
                          .delete();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Order deleted successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to delete order'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  background: Container(
                    color: Colors.red,
                    child: const Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(right: 16),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                    ),
                  ),
                  child: _OrderCard(
                    orderData: orderData,
                    orderId: orderDoc.id,
                  ).animate(),
                );
              } else {
                // If the status is not 'pending', return the _OrderCard without Dismissible
                return _OrderCard(
                  orderData: orderData,
                  orderId: orderDoc.id,
                ).animate();
              }
            },
          ),
        );
      },
    );
  }

  Widget _EmptyState() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/empty_order.json',
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 24),
          Text(
            'No orders found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Start ordering your favorite dishes!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.grey[300] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 53, 42, 207),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              elevation: 0,
            ),
            child: const Text(
              'Start Ordering',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleOrderStatusChanges(List<QueryDocumentSnapshot> orders) async {
    for (final orderDoc in orders) {
      final orderData = orderDoc.data() as Map<String, dynamic>;
      final orderId = orderDoc.id;
      final status = orderData['status']?.toString().toLowerCase() ?? 'pending';

      // Fetch the first item's imageUrl from the order
      final items = orderData['items'] as List<dynamic>;
      final imageUrl = items.isNotEmpty ? items[0]['imageUrl'] : null;

      if (imageUrl != null) {
        await _showNotification(orderId, imageUrl, status);
      }
    }
  }

  Future<Uint8List> _downloadImage(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load image');
    }
  }

  Future<void> _showNotification(
      String orderId, String imageUrl, String status) async {
    // Download the image
    Uint8List? imageBytes;
    try {
      imageBytes = await _downloadImage(imageUrl);
    } catch (e) {
      print('Failed to download image: $e');
    }

    // Define the notification details
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'order_status_channel', // Channel ID
      'Order Status Updates', // Channel Name
      channelDescription: 'Notifications about your order status',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      enableLights: true,
      color: Colors.blue,
      styleInformation: imageBytes != null
          ? BigPictureStyleInformation(
              ByteArrayAndroidBitmap(imageBytes),
              largeIcon:
                  ByteArrayAndroidBitmap(imageBytes), // Large icon (optional)
              contentTitle: 'Order Update: $status',
              summaryText: 'Tap to view details', // Summary text
              htmlFormatContentTitle: true,
              htmlFormatSummaryText: true,
            )
          : null, // Fallback to default style if image download fails
    );

    final DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    String title;
    String message;

    switch (status) {
      case 'pending':
        title = 'Order Received!';
        message = 'Your order has been received and is being processed.';
        break;
      case 'preparing':
        title = 'Order in Preparation!';
        message = 'Your order is being prepared. It will be ready soon.';
        break;
      case 'in delivery':
        title = 'Order On The Way!';
        message = 'Your order is on its way to you. Please stay tuned.';
        break;
      case 'delivered':
        title = 'Order Delivered!';
        message = 'Your order has been successfully delivered.';
        break;
      case 'cancelled':
        title = 'Order Cancelled!';
        message = 'Unfortunately, your order has been cancelled.';
        break;
      default:
        title = 'Order Update';
        message = 'There\'s an update to your order.';
    }

    await FlutterLocalNotificationsPlugin().show(
      orderId.hashCode,
      title,
      message,
      platformChannelSpecifics,
      payload: orderId,
    );
  }

  Future<void> _refreshOrders() async {
    await _firestore
        .collection('orders')
        .get(const GetOptions(source: Source.server));
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: const Color(0xFFFFFFFF),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                spreadRadius: 0,
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Filter Orders',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color.fromARGB(255, 15, 193, 242),
                ),
              ),
              const SizedBox(height: 24),
              ...[
                'All',
                'Pending',
                'Preparing',
                'In Delivery',
                'Delivered',
                'Cancelled'
              ].map(
                (status) => _FilterChip(
                  label: status,
                  isSelected: _selectedStatus == status,
                  onSelected: (value) {
                    _filterOrders(status);
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color.fromARGB(255, 5, 67, 191),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _filterOrders(String status) {
    setState(() {
      _selectedStatus = status;
    });
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final String orderId;

  const _OrderCard({
    required this.orderData,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    final restaurantService = RestaurantService();
    final restaurantId = orderData['restaurantId'] as String;
    final restaurant = restaurantService.restaurants.firstWhere(
      (rest) => rest.id == restaurantId,
    );

    final date = _formatTimestamp(orderData['createdAt']);
    final total =
        NumberFormat.currency(symbol: '\$').format(orderData['totalAmount']);
    final status = orderData['status']?.toString().toLowerCase() ?? 'pending';
    final items = orderData['items'] as List<dynamic>;
    final imageUrl = items.isNotEmpty ? items[0]['imageUrl'] : null;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _OrderDetailsBottomSheet(
            orderData: orderData,
            orderId: orderId,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      restaurant.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _OrderStatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 8),
              if (imageUrl != null)
                flutter.Image.network(
                  imageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 8),
              Text(
                'Order ID: $orderId',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              Text(
                'Date: $date',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              Text(
                'Total: $total',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (status == 'delivered')
                    _buildRatingSection()
                  else if (status != 'pending')
                    Text(
                      'This order cannot be deleted.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    )
                  else if (status == 'pending' || status == 'confirmed')
                    if (status == 'pending' || status == 'confirmed')
                      ElevatedButton.icon(
                        onPressed: () => _editOrder(context, restaurant),
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Order'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(20, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                  if (status == 'pending')
                    Column(
                      children: [
                        IconButton(
                          onPressed: () => _deleteOrder(context, orderId),
                          icon: const Icon(Icons.delete),
                          color: Colors.red,
                        ),
                        Text(
                          'Delete Order',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editOrder(BuildContext context, Restaurant restaurant) async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final items = orderData['items'] as List<dynamic>;

    // Start editing the order
    await cart.startEditingOrder(
      orderId,
      List<Map<String, dynamic>>.from(items),
      restaurant.id,
    );

    // Navigate to home screen for editing
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (route) => false,
      );
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    return DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp.toDate());
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(
          thickness: 1,
          color: Color(0x1A000000),
        ),
        const SizedBox(height: 8),
        const Text(
          'Rate your experience:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color.fromARGB(255, 166, 226, 243),
          ),
        ),
        RatingBar.builder(
          initialRating: 0,
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: true,
          itemCount: 5,
          itemSize: 28,
          itemPadding: const EdgeInsets.symmetric(horizontal: 4),
          itemBuilder: (context, _) => const Icon(
            Icons.star,
            color: Color.fromARGB(255, 204, 255, 1),
          ),
          onRatingUpdate: (rating) {
            _submitRating(rating);
          },
        ),
      ],
    );
  }

  void _submitRating(double rating) {
    FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .update({'rating': rating});
  }

  void _deleteOrder(BuildContext context, String orderId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Order'),
        content: const Text('Are you sure you want to delete this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    // If user confirms deletion
    if (confirmed == true) {
      try {
        // Delete the order from Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('orders')
            .doc(orderId)
            .delete();

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Show notification
        const AndroidNotificationDetails androidPlatformChannelSpecifics =
            AndroidNotificationDetails(
          'food_delivery_channel',
          'GB delivery',
          channelDescription: 'Notifications for your food delivery orders',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
          color: Colors.green,
        );
        const DarwinNotificationDetails iosPlatformChannelSpecifics =
            DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );
        const NotificationDetails platformChannelSpecifics =
            NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: iosPlatformChannelSpecifics,
        );
        await FlutterLocalNotificationsPlugin().show(
          orderId.hashCode,
          'You updated your order!! 🎉',
          'Your order deleted successfully.',
          platformChannelSpecifics,
          payload: orderId,
        );
      } catch (e) {
        // Show error message if deletion fails
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete order'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _OrderStatusBadge extends StatelessWidget {
  final String status;

  const _OrderStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
    final bgColor = color.withOpacity(0.1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFF3B82F6);
      case 'preparing':
        return const Color(0xFFF59E0B);
      case 'in delivery':
        return const Color(0xFF8B5CF6);
      case 'delivered':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }
}

class _OrderDetailsBottomSheet extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final String orderId;

  const _OrderDetailsBottomSheet({
    required this.orderData,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    // Ensure the orderData map contains the required keys
    final items = (orderData['items'] as List<dynamic>? ?? [])
        .map((item) => item as Map<String, dynamic>)
        .toList();
    final address = (orderData['deliveryAddress'] is String)
        ? orderData['deliveryAddress'] as String
        : 'No address provided';
    final paymentMethod = (orderData['paymentMethod'] is String)
        ? orderData['paymentMethod'] as String
        : 'Unknown';
    final total = (orderData['totalAmount'] is double)
        ? orderData['totalAmount'] as double
        : 0.0;
    final deliveryNotes = (orderData['deliveryNotes'] is String)
        ? orderData['deliveryNotes'] as String
        : 'No special instructions';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.9,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: isDark ? Colors.grey[900] : Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              spreadRadius: 0,
              blurRadius: 16,
            ),
          ],
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Details',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  color: isDark ? Colors.white : Colors.black,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailItem(Icons.receipt, 'Order ID:', orderId),
            _buildDetailItem(Icons.location_on, 'Delivery Address:', address),
            _buildDetailItem(
              Icons.payment,
              'Payment Method:',
              paymentMethod == 'cash'
                  ? 'Cash on Delivery'
                  : 'Credit/Debit Card',
            ),
            _buildDetailItem(Icons.note, 'Delivery Notes:', deliveryNotes),
            const SizedBox(height: 24),
            const Text(
              'Order Items:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3436),
              ),
            ),
            ...items.map((item) => _buildOrderItem(item, context)),
            const Divider(
              thickness: 1,
              color: Color(0x1A000000),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3436),
                  ),
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF243447),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 24,
            color: const Color(0xFF6B7280),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF2D3436),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item, context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final name =
        (item['name'] is String) ? item['name'] as String : 'Unknown Item';
    final price = (item['price'] is double) ? item['price'] as double : 0.0;
    final quantity = (item['quantity'] is int) ? item['quantity'] as int : 1;

    final total = (price * quantity).toStringAsFixed(2);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: const Color(0x1A000000).withOpacity(0.1),
        ),
      ),
      color: isDark ? Colors.grey[850] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: const Color.fromARGB(255, 0, 30, 89),
            child: Text(
              '${quantity}x',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          title: Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2D3436),
            ),
          ),
          subtitle: Text(
            '\$${price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6B7280),
            ),
          ),
          trailing: Text(
            '\$$total',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2D3436),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function(String) onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: () => onSelected(label),
        child: Card(
          elevation: isSelected ? 8 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
            side: isSelected
                ? const BorderSide(color: Color(0xFF4F46E5), width: 2)
                : BorderSide.none,
          ),
          color: isSelected
              ? const Color(0xFF4F46E5).withOpacity(0.1)
              : (isDark ? Colors.grey[850] : Colors.white),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 16,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? const Color(0xFF4F46E5)
                    : (isDark ? Colors.white : Colors.black),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
