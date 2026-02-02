import 'dart:math';
import 'package:flutter/foundation.dart';

/// Service to simulate fetching telematics data from Azuga
class AzugaService {
  
  /// Fetches telematics data for a specific trip
  /// In a real app, this would call Azuga's API with the vehicle ID and time range
  static Future<AzugaTripData> getTripTelematics({
    required String tripId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Generate mock data based on time difference to make it realistic
    final durationInMinutes = endTime.difference(startTime).inMinutes;
    final mockMiles = (durationInMinutes * 0.5) + (Random().nextDouble() * 2); // Roughly 30mph avg
    
    return AzugaTripData(
      tripId: tripId,
      actualMiles: double.parse(mockMiles.toStringAsFixed(1)),
      durationMinutes: durationInMinutes,
      maxSpeed: 45 + Random().nextInt(20), // 45-65 mph
      brakingEvents: Random().nextInt(3),
      accelerationEvents: Random().nextInt(2),
      engineIdleTimeMinutes: Random().nextInt(5),
      safetyScore: 85 + Random().nextInt(15), // 85-100
    );
  }
}

class AzugaTripData {
  final String tripId;
  final double actualMiles;
  final int durationMinutes;
  final int maxSpeed;
  final int brakingEvents;
  final int accelerationEvents;
  final int engineIdleTimeMinutes;
  final int safetyScore;

  AzugaTripData({
    required this.tripId,
    required this.actualMiles,
    required this.durationMinutes,
    required this.maxSpeed,
    required this.brakingEvents,
    required this.accelerationEvents,
    required this.engineIdleTimeMinutes,
    required this.safetyScore,
  });
  
  @override
  String toString() {
    return 'AzugaTripData(miles: $actualMiles, duration: ${durationMinutes}m, score: $safetyScore)';
  }
}
