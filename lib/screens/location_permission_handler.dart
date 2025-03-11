import 'package:flutter/material.dart';
import '../services/permission_service.dart';
import '../services/background_location_service.dart';

class LocationPermissionHandler extends StatelessWidget {
  final PermissionService _permissionService = PermissionService();
  final BackgroundLocationService _locationService = BackgroundLocationService();

  Future<void> _handleLocationPermission(BuildContext context) async {
    try {
      bool permissionsGranted = await _permissionService.requestAllRequiredPermissions();
      
      if (permissionsGranted) {
        // Initialize and start the background service
        await _locationService.initializeService();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location tracking started')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is required for background tracking'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Location Permission Required',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'This app needs access to location when open and in the background to track your deliveries.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _handleLocationPermission(context),
            child: const Text('Grant Permissions'),
          ),
        ],
      ),
    );
  }
}
