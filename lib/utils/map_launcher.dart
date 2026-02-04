import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yazdrive/theme.dart';

class MapLauncher {
  static Future<void> launchNavigation({
    required BuildContext context,
    double? latitude,
    double? longitude,
    required String address,
  }) async {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Which App do you want to use for navigation?'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _launchGoogleMaps(latitude, longitude, address);
            },
            child: const Text('Google'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _launchAppleMaps(latitude, longitude, address);
            },
            child: const Text('Apple'),
          ),
          CupertinoActionSheetAction(
             onPressed: () {
               Navigator.pop(context);
               _launchWaze(latitude, longitude, address);
             },
             child: const Text('Waze'),
           ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDestructiveAction: true,
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  static Future<void> _launchGoogleMaps(double? lat, double? lng, String address) async {
    String url;
    if (lat != null && lng != null) {
      url = 'comgooglemaps://?daddr=$lat,$lng&directionsmode=driving';
    } else {
      url = 'comgooglemaps://?daddr=${Uri.encodeComponent(address)}&directionsmode=driving';
    }
    
    String fallbackUrl;
    if (lat != null && lng != null) {
      fallbackUrl = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    } else {
      fallbackUrl = 'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(address)}';
    }

    await _launch(url, fallbackUrl);
  }

  static Future<void> _launchAppleMaps(double? lat, double? lng, String address) async {
    String url;
    if (lat != null && lng != null) {
      url = 'http://maps.apple.com/?daddr=$lat,$lng';
    } else {
      url = 'http://maps.apple.com/?daddr=${Uri.encodeComponent(address)}';
    }
    await _launch(url, url);
  }

  static Future<void> _launchWaze(double? lat, double? lng, String address) async {
    String url;
    // Waze prefers coords but can search
    if (lat != null && lng != null) {
      url = 'waze://?ll=$lat,$lng&navigate=yes';
    } else {
      url = 'waze://?q=${Uri.encodeComponent(address)}&navigate=yes';
    }
    
    String fallbackUrl;
    if (lat != null && lng != null) {
      fallbackUrl = 'https://waze.com/ul?ll=$lat,$lng&navigate=yes';
    } else {
      fallbackUrl = 'https://waze.com/ul?q=${Uri.encodeComponent(address)}&navigate=yes';
    }

    await _launch(url, fallbackUrl);
  }

  static Future<void> _launch(String url, String fallbackUrl) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        final fallback = Uri.parse(fallbackUrl);
        if (await canLaunchUrl(fallback)) {
          await launchUrl(fallback, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      debugPrint('Could not launch map: $e');
    }
  }
}

