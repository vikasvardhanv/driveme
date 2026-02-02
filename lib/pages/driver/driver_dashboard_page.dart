import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:yazdrive/services/user_service.dart';
import 'package:yazdrive/services/trip_service.dart';
import 'package:yazdrive/services/vehicle_service.dart';
import 'package:yazdrive/models/trip_model.dart';
import 'package:yazdrive/models/vehicle_model.dart';
import 'package:yazdrive/theme.dart';

class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage({super.key});

  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
  bool _hasFetchedData = false;
  String _selectedFilter = 'all'; // Filter: 'all', 'scheduled', 'inProgress', 'completed', 'cancelled'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tripService = context.read<TripService>();
      final userService = context.read<UserService>();
      
      tripService.loadTrips();
      
      // Try to connect immediately if user is already loaded
      _checkAndConnect();

      // Listen for user changes (in case user loads later)
      userService.addListener(_checkAndConnect);
    });
  }

  @override
  void dispose() {
    final userService = context.read<UserService>();
    userService.removeListener(_checkAndConnect);
    super.dispose();
  }

  void _checkAndConnect() {
    if (!mounted) return;
    
    final userService = context.read<UserService>();
    final tripService = context.read<TripService>();
    final currentUser = userService.currentUser;

    if (currentUser != null) {
      tripService.initializeSocketConnection(currentUser.id);
      
      if (!_hasFetchedData) {
        tripService.fetchTripsFromBackend(currentUser.id);
        _hasFetchedData = true;
      }
    }
  }

  void _startTakingTrips() {
    // Navigate to vehicle confirmation before starting trips
    context.go('/driver/vehicle-confirmation');
  }

  @override
  Widget build(BuildContext context) {
    final userService = context.watch<UserService>();
    final tripService = context.watch<TripService>();
    final vehicleService = context.watch<VehicleService>();
    final currentUser = userService.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final todayTrips = tripService.getTodayTrips(currentUser.id);
    final upcomingTrips = tripService.getUpcomingTrips(currentUser.id);
    final completedToday = tripService.getCompletedTripsForToday(currentUser.id).length;
    
    TripModel? activeTrip;
    final activeTrips = tripService.trips.where((t) => 
      t.driverId == currentUser.id && 
      (t.status == TripStatus.enRoute || t.status == TripStatus.arrived || t.status == TripStatus.pickedUp)
    );
    if (activeTrips.isNotEmpty) activeTrip = activeTrips.first;



    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh trips',
            onPressed: () => tripService.loadTrips(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              vehicleService.clearSelectedVehicle();
              await userService.logout();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (currentUser != null) {
            await tripService.fetchTripsFromBackend(currentUser.id);
          } else {
            await tripService.loadTrips();
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DriverInfoCard(driver: currentUser),
            const SizedBox(height: 24),
            
            // Start Taking Trips button (Veyo-style)
            _StartTakingTripsButton(
              onPressed: _startTakingTrips,
              tripsCount: todayTrips.length,
              selectedVehicle: vehicleService.selectedVehicle,
            ),
            
            const SizedBox(height: 24),
            _StatsRow(
              todayCount: todayTrips.length,
              completedCount: completedToday,
              upcomingCount: upcomingTrips.length,
            ),
            const SizedBox(height: 24),
            
            // Active Trip Card
            if (activeTrip != null) ...[
              const SizedBox(height: 24),
              Text('Active Trip', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              _ActiveTripCard(trip: activeTrip),
            ] else ...[
              const SizedBox(height: 24),
              _NoActiveTripCard(),
            ],
          ],
        ),
      ),
    );
  }
}

class _StartTakingTripsButton extends StatelessWidget {
  final VoidCallback onPressed;
  final int tripsCount;
  final VehicleModel? selectedVehicle;

  const _StartTakingTripsButton({
    required this.onPressed,
    required this.tripsCount,
    this.selectedVehicle,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOnline = selectedVehicle != null;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOnline 
              ? [AppColors.primary, AppColors.primaryDark]
              : [AppColors.success, AppColors.success.withGreen(180)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isOnline ? AppColors.primary : AppColors.success).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isOnline 
                        ? (selectedVehicle!.wheelchairAccessible 
                            ? Icons.accessible 
                            : Icons.directions_car)
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOnline 
                            ? selectedVehicle!.licensePlate
                            : 'Start Taking Trips',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isOnline
                            ? '${selectedVehicle!.year} ${selectedVehicle!.make} ${selectedVehicle!.model}'
                            : (tripsCount > 0
                                ? '$tripsCount trips scheduled for today'
                                : 'Go online to receive trips'),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      if (isOnline) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Tap to change vehicle',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  isOnline ? Icons.swap_horiz : Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoTripOverviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 16),
          Text(
            'No Trip Overview Available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Press refresh to check for newly assigned trips',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textDisabled,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DriverInfoCard extends StatelessWidget {
  final dynamic driver;

  const _DriverInfoCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go('/driver/profile'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
                    backgroundColor: Colors.white.withOpacity(0.2),
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
                          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap to view profile',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.9), size: 28),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int todayCount;
  final int completedCount;
  final int upcomingCount;

  const _StatsRow({
    required this.todayCount,
    required this.completedCount,
    required this.upcomingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(icon: Icons.today, label: 'Today', count: todayCount, color: AppColors.info)),
        const SizedBox(width: 8),
        Expanded(child: _StatCard(icon: Icons.check_circle, label: 'Done', count: completedCount, color: AppColors.success)),
        const SizedBox(width: 8),
        Expanded(child: _StatCard(icon: Icons.calendar_month, label: 'Upcoming', count: upcomingCount, color: AppColors.warning)),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(count.toString(), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
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
      margin: const EdgeInsets.only(bottom: 12),
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
                      color: statusColor.withOpacity(0.1),
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

class _TripFilterChips extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final TripService tripService;
  final String driverId;

  const _TripFilterChips({
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.tripService,
    required this.driverId,
  });

  @override
  Widget build(BuildContext context) {
    final allTrips = tripService.getDriverTrips(driverId);
    final scheduled = allTrips.where((t) => t.status == TripStatus.scheduled || t.status == TripStatus.assigned).toList();
    final inProgress = allTrips.where((t) => t.status == TripStatus.enRoute || t.status == TripStatus.arrived || t.status == TripStatus.pickedUp).toList();
    final completed = allTrips.where((t) => t.status == TripStatus.completed).toList();
    final cancelled = allTrips.where((t) => t.status == TripStatus.cancelled || t.status == TripStatus.noShow).toList();

    final filters = [
      {'key': 'all', 'label': 'All', 'count': allTrips.length},
      {'key': 'scheduled', 'label': 'Scheduled', 'count': scheduled.length},
      {'key': 'inProgress', 'label': 'In Progress', 'count': inProgress.length},
      {'key': 'completed', 'label': 'Completed', 'count': completed.length},
      {'key': 'cancelled', 'label': 'Cancelled', 'count': cancelled.length},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter['key'];
          final count = filter['count'] as int;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text('${filter['label']} ($count)'),
              onSelected: (_) => onFilterChanged(filter['key'] as String),
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FilteredTripList extends StatelessWidget {
  final String selectedFilter;
  final TripService tripService;
  final String driverId;

  const _FilteredTripList({
    required this.selectedFilter,
    required this.tripService,
    required this.driverId,
  });

  List<TripModel> _getFilteredTrips() {
    final allTrips = tripService.getDriverTrips(driverId);
    
    switch (selectedFilter) {
      case 'scheduled':
        return allTrips.where((t) => t.status == TripStatus.scheduled || t.status == TripStatus.assigned).toList();
      case 'inProgress':
        return allTrips.where((t) => t.status == TripStatus.enRoute || t.status == TripStatus.arrived || t.status == TripStatus.pickedUp).toList();
      case 'completed':
        return allTrips.where((t) => t.status == TripStatus.completed).toList();
      case 'cancelled':
        return allTrips.where((t) => t.status == TripStatus.cancelled || t.status == TripStatus.noShow).toList();
      default:
        return allTrips;
    }
  }

  @override
  Widget build(BuildContext context) {
    final trips = _getFilteredTrips();
    
    // Sort by pickup time (most recent first for completed/cancelled, nearest first for others)
    trips.sort((a, b) {
      if (selectedFilter == 'completed' || selectedFilter == 'cancelled') {
        return b.scheduledPickupTime.compareTo(a.scheduledPickupTime);
      }
      return a.scheduledPickupTime.compareTo(b.scheduledPickupTime);
    });

    if (trips.isEmpty) {
      return _EmptyStateCard(
        message: selectedFilter == 'all' 
            ? 'No trips available' 
            : 'No ${selectedFilter} trips',
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 400),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: trips.length,
        itemBuilder: (context, index) => _TripCard(trip: trips[index]),
      ),
    );
  }
}

class _ActiveTripCard extends StatelessWidget {
  final TripModel trip;

  const _ActiveTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: AppColors.primary.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.push('/driver/trip/${trip.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.navigation, size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'IN PROGRESS',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Tap to view',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Icon(Icons.trip_origin, color: AppColors.primary, size: 20),
                      Container(
                        width: 2,
                        height: 30,
                        color: AppColors.lightBorder,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      Icon(Icons.location_on, color: AppColors.error, size: 20),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pickup', style: Theme.of(context).textTheme.labelSmall),
                        Text(
                          trip.pickupAddress,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 20),
                        Text('Dropoff', style: Theme.of(context).textTheme.labelSmall),
                        Text(
                          trip.dropoffAddress,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoActiveTripCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.drive_eta, size: 48, color: AppColors.textDisabled),
            const SizedBox(height: 12),
            Text(
              'No Active Trip',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Start a scheduled trip to see it here',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
