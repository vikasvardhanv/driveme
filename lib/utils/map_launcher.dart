import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yazdrive/theme.dart';

class MapLauncher {
  static Future<void> launchNavigation({
    required BuildContext context,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Navigate to',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                address,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 32),
            
            // Waze
            _AppTile(
              name: 'Waze',
              icon: Icons.directions_car,
              color: Colors.blue,
              onTap: () async {
                Navigator.pop(context);
                final url = 'waze://?ll=$latitude,$longitude&navigate=yes';
                final fallback = 'https://waze.com/ul?ll=$latitude,$longitude&navigate=yes';
                _launch(url, fallback);
              },
            ),
            
            // Google Maps
            _AppTile(
              name: 'Google Maps',
              icon: Icons.map,
              color: Colors.green,
              onTap: () async {
                Navigator.pop(context);
                final url = 'google.navigation:q=$latitude,$longitude';
                final fallback = 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
                _launch(url, fallback);
              },
            ),
            
            // Apple Maps (iOS only)
            if (Platform.isIOS)
              _AppTile(
                name: 'Apple Maps',
                icon: Icons.map_outlined,
                color: Colors.grey,
                onTap: () async {
                  Navigator.pop(context);
                  final url = 'http://maps.apple.com/?daddr=$latitude,$longitude';
                  _launch(url, url);
                },
              ),
              
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
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

class _AppTile extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AppTile({
    required this.name,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(name),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }
}
