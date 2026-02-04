import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yazdrive/services/user_service.dart';
import 'package:yazdrive/theme.dart';

class DriversListPage extends StatefulWidget {
  const DriversListPage({super.key});

  @override
  State<DriversListPage> createState() => _DriversListPageState();
}

class _DriversListPageState extends State<DriversListPage> {
  @override
  void initState() {
    super.initState();
    // Fetch drivers when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserService>().fetchDrivers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drivers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<UserService>().fetchDrivers();
            },
          ),
        ],
      ),
      body: Consumer<UserService>(
        builder: (context, userService, child) {
          if (userService.isLoading && userService.drivers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final drivers = userService.drivers;

          if (drivers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No drivers found', style: TextStyle(color: Colors.grey, fontSize: 18)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final driver = drivers[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      driver.firstName.isNotEmpty ? driver.firstName[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    driver.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      if (driver.phoneNumber.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(driver.phoneNumber, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      if (driver.vehicleId != null)
                        Row(
                          children: [
                            const Icon(Icons.directions_car, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('Vehicle ID: ${driver.vehicleId}', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: driver.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      driver.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: driver.isActive ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
