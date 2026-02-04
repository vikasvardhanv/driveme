import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:yazdrive/models/trip_model.dart';
import 'package:yazdrive/theme.dart';

class TripMap extends StatelessWidget {
  final TripModel trip;
  final VoidCallback? onExpand;

  const TripMap({super.key, required this.trip, this.onExpand});

  @override
  Widget build(BuildContext context) {
    if (trip.pickupLatitude == null || trip.pickupLongitude == null) {
      return Container(
        height: 200,
        color: Colors.grey[200],
        child: const Center(child: Text('Map not available')),
      );
    }

    final pickup = LatLng(trip.pickupLatitude!, trip.pickupLongitude!);
    final dropoff = (trip.dropoffLatitude != null && trip.dropoffLongitude != null)
        ? LatLng(trip.dropoffLatitude!, trip.dropoffLongitude!)
        : null;

    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: pickup, 
                initialZoom: 14.0,
                // Use CameraFit to automatically fit the route if dropoff exists
                initialCameraFit: dropoff != null 
                    ? CameraFit.bounds(
                        bounds: LatLngBounds(pickup, dropoff),
                        padding: const EdgeInsets.all(50), 
                      )
                    : null,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate, 
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.yazdrive', 
                ),
                if (dropoff != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [pickup, dropoff],
                        strokeWidth: 4,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: pickup,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on, color: AppColors.primary, size: 40),
                    ),
                    if (dropoff != null)
                      Marker(
                        point: dropoff,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_on, color: AppColors.success, size: 40),
                      ),
                  ],
                ),
              ],
            ),
            // Copyright Overlay
             Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '© OpenStreetMap',
                  style: TextStyle(fontSize: 10, color: Colors.black54),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
