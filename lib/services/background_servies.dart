import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../firebase_options.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  // Create notification channel
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'location_tracking',
    'Location Tracking',
    description: 'Used for tracking location in background',
    importance: Importance.high,
    enableVibration: true,
    playSound: true,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'location_tracking',
      initialNotificationTitle: 'Location Tracking',
      initialNotificationContent: 'Tracking your location in the background',
      foregroundServiceNotificationId: 888,
      autoStartOnBoot: true,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Initialize Firebase first
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Error initializing Firebase in background service: $e');
    return;
  }

  if (service is AndroidServiceInstance) {
    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Set up foreground notification
    await service.setForegroundNotificationInfo(
      title: 'Location Tracking Active',
      content: 'Your location is being tracked in the background',
    );
  }

  // Keep the service alive
  service.on('setAsForeground').listen((event) {
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }
  });

  service.on('setAsBackground').listen((event) {
    if (service is AndroidServiceInstance) {
      service.setAsBackgroundService();
    }
  });

  // Start location tracking
  try {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;

    // Request location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied || 
        permission == LocationPermission.deniedForever) {
      print('Location permissions denied');
      return;
    }

    // Configure location settings for high accuracy
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
      timeLimit: null, // No time limit
    );

    // Start location tracking
    Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) async {
        try {
          final user = auth.currentUser;
          if (user != null) {
            // Update location in Firestore
            await firestore.collection('orders')
                .where('userId', isEqualTo: user.uid)
                .where('status', isEqualTo: 'pending')
                .get()
                .then((querySnapshot) {
              querySnapshot.docs.forEach((doc) async {
                await doc.reference.update({
                  'currentLocation': GeoPoint(position.latitude, position.longitude),
                  'lastUpdated': FieldValue.serverTimestamp(),
                });
              });
            });

            // Keep service alive by updating notification periodically
            if (service is AndroidServiceInstance) {
              await service.setForegroundNotificationInfo(
                title: 'Location Tracking Active',
                content: 'Last update: ${DateTime.now().toString()}',
              );
            }
          }
        } catch (e) {
          print('Error updating location in Firestore: $e');
        }
      },
      onError: (error) {
        print('Background location error: $error');
      },
    );
  } catch (e) {
    print('Error setting up location tracking: $e');
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}