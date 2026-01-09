import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:yazdrive/services/user_service.dart';
import 'package:yazdrive/services/trip_service.dart';
import 'package:yazdrive/models/trip_model.dart';
import 'package:yazdrive/theme.dart';

class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage({super.key});

  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tripService = context.read<TripService>();
      tripService.loadTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userService = context.watch<UserService>();
    final tripService = context.watch<TripService>();
    final currentUser = userService.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final todayTrips = tripService.getTodayTrips(currentUser.id);
    final upcomingTrips = tripService.getUpcomingTrips(currentUser.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
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
      body: RefreshIndicator(
        onRefresh: () => tripService.loadTrips(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DriverInfoCard(driver: currentUser),
            const SizedBox(height: 24),
            _StatsRow(todayCount: todayTrips.length, upcomingCount: upcomingTrips.length),
            const SizedBox(height: 24),
            Text('Today\'s Trips', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            if (todayTrips.isEmpty)
              _EmptyStateCard(message: 'No trips scheduled for today')
            else
              ...todayTrips.map((trip) => _TripCard(trip: trip)),
            const SizedBox(height: 24),
            Text('Upcoming Trips', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            if (upcomingTrips.isEmpty)
              _EmptyStateCard(message: 'No upcoming trips')
            else
              ...upcomingTrips.take(5).map((trip) => _TripCard(trip: trip)),
            const SizedBox(height: 16),
            if (upcomingTrips.length > 5)
              TextButton(
                onPressed: () => context.push('/driver/trips'),
                child: const Text('View All Trips'),
              ),
          ],
        ),
      ),
    );
  }
}

class _DriverInfoCard extends StatelessWidget {
  final dynamic driver;

  const _DriverInfoCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  driver.firstName[0] + driver.lastName[0],
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.fullName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'License: ${driver.licenseNumber ?? 'N/A'}',
                      style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.verified_user, color: Colors.white.withValues(alpha: 0.9), size: 28),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int todayCount;
  final int upcomingCount;

  const _StatsRow({required this.todayCount, required this.upcomingCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(icon: Icons.today, label: 'Today', count: todayCount, color: AppColors.info)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(icon: Icons.calendar_month, label: 'Upcoming', count: upcomingCount, color: AppColors.success)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.count, required this.color});

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

class _TripCard extends StatelessWidget {
  final TripModel trip;

  const _TripCard({required this.trip});

  Color _getStatusColor() {
    switch (trip.status) {
      case TripStatus.scheduled:
      case TripStatus.assigned:
        return AppColors.info;
      case TripStatus.enRoute:
      case TripStatus.arrived:
        return AppColors.warning;
      case TripStatus.pickedUp:
        return AppColors.success;
      case TripStatus.completed:
        return AppColors.success;
      case TripStatus.cancelled:
      case TripStatus.noShow:
        return AppColors.error;
    }
  }

  String _getStatusText() {
    switch (trip.status) {
      case TripStatus.scheduled:
        return 'Scheduled';
      case TripStatus.assigned:
        return 'Assigned';
      case TripStatus.enRoute:
        return 'En Route';
      case TripStatus.arrived:
        return 'Arrived';
      case TripStatus.pickedUp:
        return 'Picked Up';
      case TripStatus.completed:
        return 'Completed';
      case TripStatus.cancelled:
        return 'Cancelled';
      case TripStatus.noShow:
        return 'No Show';
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final statusColor = _getStatusColor();

    return Card(
      child: InkWell(
        onTap: () => context.push('/driver/trip/${trip.id}'),
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
                      _getStatusText(),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(timeFormat.format(trip.scheduledPickupTime), style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.trip_origin, size: 20, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pickup', style: Theme.of(context).textTheme.labelSmall),
                        Text(trip.pickupAddress, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, size: 20, color: AppColors.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dropoff', style: Theme.of(context).textTheme.labelSmall),
                        Text(trip.dropoffAddress, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
              if (trip.mobilityAid != 'none') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.accessible, size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Text(trip.mobilityAid.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String message;

  const _EmptyStateCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy, size: 48, color: AppColors.textDisabled),
          const SizedBox(height: 12),
          Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
