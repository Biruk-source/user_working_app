// @dart=2.17

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'providers/cart_provider.dart';
import 'services/restaurant_service.dart';
import 'services/connectivity_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/OrdersScreen.dart';
import 'utils/theme.dart';
import 'providers/theme_provider.dart';
import 'utils/orderarugument.dart';
import 'screens/my_orders.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set platform optimization flags
  if (Platform.isAndroid) {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
  }

  // Initialize Firebase first
  try {
    if (!Firebase.apps.any((app) => app.name == '[DEFAULT]')) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    // Initialize notification service after Firebase
    await NotificationService().initialize();
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  // Initialize providers after ensuring Firebase is ready
  final cartProvider = CartProvider();
  try {
    if (FirebaseAuth.instance.currentUser != null) {
      await cartProvider.loadCartFromFirestore();
    }
  } catch (e) {
    print('Error loading cart: $e');

    cartProvider.clearCart();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: cartProvider),
        ChangeNotifierProvider<RestaurantService>(
          create: (_) => RestaurantService(),
        ),
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        Provider<ConnectivityService>(create: (_) => ConnectivityService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Restaurant App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          routes: {
            '/home': (context) => const HomeScreen(),
            CartScreen.routeName: (context) => const CartScreen(),
            OrdersScreen.routeName: (context) {
              final args = ModalRoute.of(context)?.settings.arguments
                  as OrdersScreenArguments;
              return OrdersScreen(
                totalPrice: args.totalPrice,
                cartItems: args.cartItems,
                restaurant: args.restaurant,
              );
            },
            MyOrdersScreen.routeName: (ctx) => const MyOrdersScreen(),
          },
          home: const AuthenticationWrapper(),
        );
      },
    );
  }
}

class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({super.key});

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final storage = const FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
