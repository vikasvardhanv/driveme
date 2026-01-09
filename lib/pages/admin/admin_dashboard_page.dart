import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:yazdrive/services/user_service.dart';
import 'package:yazdrive/services/trip_service.dart';
import 'package:yazdrive/services/vehicle_service.dart';
import 'package:yazdrive/theme.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tripService = context.read<TripService>();
      final vehicleService = context.read<VehicleService>();
      tripService.loadTrips();
      vehicleService.loadVehicles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userService = context.watch<UserService>();
    final currentUser = userService.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await userService.logout();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.drive_eta), label: 'Trips'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const _OverviewTab();
      case 1:
        return const _TripsTab();
      case 2:
        return const _UsersTab();
      default:
        return const _OverviewTab();
    }
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    final userService = context.watch<UserService>();
    final tripService = context.watch<TripService>();
    final vehicleService = context.watch<VehicleService>();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final todayTrips = tripService.trips.where((t) => t.scheduledPickupTime.isAfter(today) && t.scheduledPickupTime.isBefore(tomorrow)).length;
    final unassignedTrips = tripService.getUnassignedTrips().length;

    return RefreshIndicator(
      onRefresh: () async {
        await tripService.loadTrips();
        await vehicleService.loadVehicles();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Quick Stats', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          _StatsGrid(
            drivers: userService.drivers.length,
            members: userService.members.length,
            vehicles: vehicleService.activeVehicles.length,
            todayTrips: todayTrips,
          ),
          const SizedBox(height: 24),
          _UnassignedTripsCard(count: unassignedTrips),
          const SizedBox(height: 24),
          _QuickActionsCard(),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final int drivers;
  final int members;
  final int vehicles;
  final int todayTrips;

  const _StatsGrid({
    required this.drivers,
    required this.members,
    required this.vehicles,
    required this.todayTrips,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(icon: Icons.local_shipping, label: 'Drivers', count: drivers, color: AppColors.primary)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(icon: Icons.people, label: 'Members', count: members, color: AppColors.info)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatCard(icon: Icons.drive_eta, label: 'Vehicles', count: vehicles, color: AppColors.success)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(icon: Icons.today, label: 'Today', count: todayTrips, color: AppColors.warning)),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 12),
          Text(count.toString(), style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _UnassignedTripsCard extends StatelessWidget {
  final int count;

  const _UnassignedTripsCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.go('/admin/trips/unassigned'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.warning_amber, color: AppColors.warning, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Unassigned Trips', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('\$count trips need driver assignment', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        _ActionButton(
          icon: Icons.add_circle,
          label: 'Create New Trip',
          color: AppColors.primary,
          onTap: () => context.push('/admin/trips/create'),
        ),
        const SizedBox(height: 12),
        _ActionButton(
          icon: Icons.person_add,
          label: 'Add Member',
          color: AppColors.info,
          onTap: () => context.push('/admin/members/create'),
        ),
        const SizedBox(height: 12),
        _ActionButton(
          icon: Icons.drive_eta,
          label: 'Add Vehicle',
          color: AppColors.success,
          onTap: () => context.push('/admin/vehicles/create'),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 16),
              Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500))),
              Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripsTab extends StatelessWidget {
  const _TripsTab();

  @override
  Widget build(BuildContext context) {
    final tripService = context.watch<TripService>();
    final trips = tripService.trips..sort((a, b) => b.scheduledPickupTime.compareTo(a.scheduledPickupTime));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: trips.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('All Trips (\${trips.length})', style: Theme.of(context).textTheme.headlineSmall),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => context.push('/admin/trips/create'),
                ),
              ],
            ),
          );
        }
        final trip = trips[index - 1];
        return _AdminTripCard(trip: trip);
      },
    );
  }
}

class _AdminTripCard extends StatelessWidget {
  final dynamic trip;

  const _AdminTripCard({required this.trip});

  Color _getStatusColor() {
    final status = trip.status.toString().split('.').last;
    switch (status) {
      case 'scheduled':
      case 'assigned':
        return AppColors.info;
      case 'enRoute':
      case 'arrived':
        return AppColors.warning;
      case 'pickedUp':
        return AppColors.success;
      case 'completed':
        return AppColors.success;
      default:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, h:mm a');
    final statusColor = _getStatusColor();

    return Card(
      child: InkWell(
        onTap: () => context.push('/admin/trip/\${trip.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      trip.status.toString().split('.').last.toUpperCase(),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                    ),
                  ),
                  const Spacer(),
                  Text(dateFormat.format(trip.scheduledPickupTime), style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 12),
              Text('\${trip.pickupAddress} → \${trip.dropoffAddress}', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text('Member ID: \${trip.membershipId}', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    final userService = context.watch<UserService>();

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Drivers'),
              Tab(text: 'Members'),
              Tab(text: 'Staff'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _UserList(users: userService.drivers, emptyMessage: 'No drivers found'),
                _UserList(users: userService.members, emptyMessage: 'No members found'),
                _UserList(users: [...userService.admins, ...userService.dispatchers], emptyMessage: 'No staff found'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  final List<dynamic> users;
  final String emptyMessage;

  const _UserList({required this.users, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(user.firstName[0] + user.lastName[0], style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
            title: Text(user.fullName),
            subtitle: Text(user.email),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
            onTap: () => context.push('/admin/user/\${user.id}'),
          ),
        );
      },
    );
  }
}
