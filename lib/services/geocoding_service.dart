import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Free Photon geocoding service (more reliable than Nominatim)
/// Built on OpenStreetMap data but with better performance
class GeocodingService {
  static const String _primaryUrl = 'https://photon.komoot.io';
  static const String _fallbackUrl = 'https://nominatim.openstreetmap.org';
  static const String _cachePrefix = 'geocode_';

  /// Geocode an address to coordinates
  /// Returns [latitude, longitude] or null if failed
  Future<List<double>?> geocodeAddress(String address) async {
    if (address.isEmpty) return null;

    // Check cache first
    final cached = await _getCachedCoordinates(address);
    if (cached != null) {
      debugPrint('Geocoding: Using cached coordinates for: $address');
      return cached;
    }

    // Try primary API (Photon) first
    try {
      debugPrint('Geocoding: Trying Photon API for: $address');

      final uri = Uri.parse('$_primaryUrl/api/');
      final fullUrl = uri.replace(queryParameters: {
        'q': address,
        'limit': '1',
      });

      debugPrint('Geocoding: URL: $fullUrl');

      final response = await http.get(
        fullUrl,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'DrivemeYaz-NEMT/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('Geocoding: Photon response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('Geocoding: Photon response body length: ${response.body.length}');

        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> features = data['features'] ?? [];

        debugPrint('Geocoding: Photon features count: ${features.length}');

        if (features.isNotEmpty) {
          final coords = features[0]['geometry']['coordinates'];
          // Photon returns [lng, lat] in GeoJSON format
          final lng = (coords[0] is int) ? (coords[0] as int).toDouble() : coords[0] as double;
          final lat = (coords[1] is int) ? (coords[1] as int).toDouble() : coords[1] as double;

          debugPrint('Geocoding: Photon found coordinates: $lat, $lng');

          // Cache the result
          await _cacheCoordinates(address, [lat, lng]);

          return [lat, lng];
        } else {
          debugPrint('Geocoding: Photon - No results found, trying fallback...');
        }
      } else {
        debugPrint('Geocoding: Photon API error (${response.statusCode}), response: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
      }
    } catch (e, stackTrace) {
      debugPrint('Geocoding: Photon error: $e');
      debugPrint('Geocoding: Stack trace: $stackTrace');
    }

    // Fallback to Nominatim
    return await _geocodeWithNominatim(address);
  }

  /// Fallback geocoding with Nominatim
  Future<List<double>?> _geocodeWithNominatim(String address) async {
    try {
      debugPrint('Geocoding: Trying Nominatim fallback for: $address');

      final response = await http.get(
        Uri.parse('$_fallbackUrl/search').replace(queryParameters: {
          'q': address,
          'format': 'json',
          'limit': '1',
        }),
        headers: {
          'User-Agent': 'DrivemeYaz-NEMT/1.0',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);

        if (results.isNotEmpty) {
          final lat = double.parse(results[0]['lat']);
          final lng = double.parse(results[0]['lon']);

          debugPrint('Geocoding: Nominatim found coordinates: $lat, $lng');

          // Cache the result
          await _cacheCoordinates(address, [lat, lng]);

          return [lat, lng];
        } else {
          debugPrint('Geocoding: Nominatim - No results found');
        }
      } else {
        debugPrint('Geocoding: Nominatim API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Geocoding: Nominatim error: $e. Continuing without coordinates.');
    }

    return null;
  }

  /// Get cached coordinates for an address
  Future<List<double>?> _getCachedCoordinates(String address) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _cachePrefix + address.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
      final cached = prefs.getString(key);

      if (cached != null) {
        final parts = cached.split(',');
        if (parts.length == 2) {
          return [double.parse(parts[0]), double.parse(parts[1])];
        }
      }
    } catch (e) {
      debugPrint('Geocoding: Cache read error: $e');
    }
    return null;
  }

  /// Cache coordinates for an address
  Future<void> _cacheCoordinates(String address, List<double> coords) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _cachePrefix + address.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
      await prefs.setString(key, '${coords[0]},${coords[1]}');
    } catch (e) {
      debugPrint('Geocoding: Cache write error: $e');
    }
  }

  /// Batch geocode multiple addresses
  Future<Map<String, List<double>>> geocodeAddresses(List<String> addresses) async {
    final results = <String, List<double>>{};

    for (final address in addresses) {
      // Add delay between requests to respect Nominatim rate limits (1 req/sec)
      await Future.delayed(const Duration(milliseconds: 1100));

      final coords = await geocodeAddress(address);
      if (coords != null) {
        results[address] = coords;
      }
    }

    return results;
  }
}
