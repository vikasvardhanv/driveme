import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yazdrive/services/user_service.dart';
import 'package:yazdrive/services/vehicle_service.dart';
import 'package:yazdrive/theme.dart';

class DriverDrawer extends StatelessWidget {
  const DriverDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = context.watch<UserService>();
    final vehicleService = context.watch<VehicleService>();
    final user = userService.currentUser;

    return Drawer(
      backgroundColor: const Color(0xFF2D2D2D), // Dark background from screenshot
      child: Column(
        children: [
          const SizedBox(height: 60),
          // User Avatar & Name
          if (user != null) ...[
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[400],
                child: Text(
                  user.firstName[0],
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${user.firstName} ${user.lastName}',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
          ],

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerItem(
                  icon: Icons.location_on, // Trip History icon
                  text: 'Trip History',
                  color: Colors.lightBlue[300]!,
                  onTap: () {
                    context.pop(); // Close drawer
                    // Navigate to history (using filtered view on trips page usually)
                  },
                ),
                _DrawerItem(
                  icon: Icons.campaign, // Report Accident (Megaphone-ish)
                  text: 'Report an Accident',
                  color: Colors.teal[300]!,
                  onTap: () {
                    context.pop();
                    // Open accident report
                  },
                ),
                _DrawerItem(
                  icon: Icons.logout, // Sign Out from Vehicle (Exit)
                  text: 'Sign Out from Vehicle',
                  color: Colors.lightBlue[300]!,
                  onTap: () {
                    context.pop();
                    vehicleService.clearSelectedVehicle();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Signed out from vehicle')),
                    );
                  },
                ),
                const Divider(color: Colors.white24, height: 1),
                _DrawerItem(
                  icon: Icons.help_outline,
                  text: 'Help',
                  color: Colors.cyan[300]!,
                  onTap: () {
                    context.pop();
                  },
                ),
                const Divider(color: Colors.white24, height: 1),
                _DrawerItem(
                  icon: Icons.help_outline, // Handbook
                  text: 'Driver Handbook',
                  color: Colors.cyan[300]!,
                  onTap: () {
                    context.pop();
                  },
                ),
                const Divider(color: Colors.white24, height: 1),
                _DrawerItem(
                  icon: Icons.help_outline, // Report Passenger
                  text: 'Report Passenger',
                  color: Colors.cyan[300]!,
                  onTap: () {
                    context.pop();
                  },
                ),
                 const Divider(color: Colors.white24, height: 1),
              ],
            ),
          ),

          // Logout at bottom
          ListTile(
            leading: const Icon(Icons.power_settings_new, color: Colors.white54),
            title: Text(
              'Logout',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500
              ),
            ),
            onTap: () async {
              context.pop();
              vehicleService.clearSelectedVehicle();
              await userService.logout();
              if (context.mounted) context.go('/');
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final Color color;

  const _DrawerItem({
    required this.icon,
    required this.text,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color, size: 28),
      title: Text(
        text,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}
